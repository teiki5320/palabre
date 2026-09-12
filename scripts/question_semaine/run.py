#!/usr/bin/env python3
"""Question de la semaine automatique.

Pour chaque pays actif sans sondage pour la semaine visée : recherche d'actualité (Claude + recherche
web), contrôles automatiques, relecture indépendante (Claude, sans web), publication dans Supabase,
rapport Markdown. Voir docs/superpowers/specs/2026-09-12-question-semaine-auto-design.md.

Usage : run.py [--dry-run] [--semaine AAAA-MM-JJ] [--pays BJ,CI] [--fixture sujets.json] [--sortie DOSSIER]
Env  : ANTHROPIC_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, GITHUB_SERVER_URL, GITHUB_REPOSITORY
"""
import argparse
import datetime as dt
import html
import json
import os
import re
import sys
import traceback
import urllib.error
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from controles import filtrer, lundi_vise, fenetre  # noqa: E402
from rapport import rendre_rapport  # noqa: E402

ICI = os.path.dirname(os.path.abspath(__file__))
MODELE = 'claude-opus-5'
UA = 'Palabre question-semaine (+https://github.com/teiki5320/palabre)'

SCHEMA_SUJET = {
    'type': 'object', 'additionalProperties': False,
    'required': ['id', 'fait', 'question', 'contexte', 'options', 'sources', 'points_d_attention'],
    'properties': {
        'id': {'type': 'string'}, 'fait': {'type': 'string'}, 'question': {'type': 'string'}, 'contexte': {'type': 'string'},
        'options': {'type': 'array', 'items': {'type': 'string'}},
        'sources': {'type': 'array', 'items': {'type': 'object', 'additionalProperties': False, 'required': ['titre', 'url', 'date', 'media'],
                    'properties': {'titre': {'type': 'string'}, 'url': {'type': 'string'}, 'date': {'type': 'string'}, 'media': {'type': 'string'}}}},
        'points_d_attention': {'type': 'string'},
    },
}
SCHEMA_RECHERCHE = {'type': 'object', 'additionalProperties': False, 'required': ['sujets', 'notes'],
                    'properties': {'sujets': {'type': 'array', 'items': SCHEMA_SUJET}, 'notes': {'type': 'string'}}}
SCHEMA_RELECTURE = {'type': 'object', 'additionalProperties': False, 'required': ['choix', 'avis', 'rejets'],
                    'properties': {'choix': {'type': ['string', 'null']}, 'avis': {'type': 'string'},
                                   'rejets': {'type': 'array', 'items': {'type': 'object', 'additionalProperties': False, 'required': ['id', 'motif'],
                                              'properties': {'id': {'type': 'string'}, 'motif': {'type': 'string'}}}}}}


# ---------------------------------------------------------------- HTTP
def http(url, method='GET', data=None, headers=None, timeout=15):
    req = urllib.request.Request(url, method=method, data=data, headers={'User-Agent': UA, **(headers or {})})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.status, r.read()


def statut_http(url):
    try:
        code, _ = http(url, headers={'Accept': 'text/html,*/*'})
        return code
    except urllib.error.HTTPError as e:
        return e.code
    except Exception:
        return None


def texte_page(url, limite=4000):
    try:
        _, corps = http(url, headers={'Accept': 'text/html,*/*'})
    except Exception as e:
        return f'[page illisible : {e}]'
    s = corps.decode('utf-8', 'ignore')
    s = re.sub(r'(?is)<(script|style|nav|footer|header)[^>]*>.*?</\1>', ' ', s)
    s = re.sub(r'(?s)<[^>]+>', ' ', s)
    s = html.unescape(re.sub(r'\s+', ' ', s)).strip()
    return s[:limite]


# ---------------------------------------------------------------- Supabase (PostgREST, clé service)
class Supabase:
    def __init__(self, url, cle):
        self.url = url.rstrip('/') + '/rest/v1/'
        self.h = {'apikey': cle, 'Authorization': f'Bearer {cle}', 'Content-Type': 'application/json'}

    def _req(self, method, chemin, data=None, prefer=None):
        headers = dict(self.h)
        if prefer:
            headers['Prefer'] = prefer
        code, corps = http(self.url + chemin, method, json.dumps(data).encode() if data is not None else None, headers, timeout=30)
        return json.loads(corps) if corps else None

    def get(self, chemin):
        return self._req('GET', chemin)

    def pays_actifs(self):
        actifs = {c['code']: c for c in self.get('country?select=code,nom,fuseau&actif=eq.true')}
        modules = self.get('country_module?select=country_code&module=eq.poll&actif=eq.true')
        return [actifs[m['country_code']] for m in modules if m['country_code'] in actifs]

    def sondage_existe(self, pays, lundi):
        return bool(self.get(f'poll?select=id&country_code=eq.{pays}&semaine=eq.{lundi.isoformat()}'))

    def noms_personnes(self, pays):
        return [p['nom'] for p in self.get(f'person?select=nom&country_code=eq.{pays}&limit=5000')]

    def publier(self, pays, lundi, sujet):
        sources = [{'titre': s['titre'], 'url': s['url'], 'date': s['date']} for s in sujet['sources']]
        rows = self._req('POST', 'poll', {'country_code': pays, 'semaine': lundi.isoformat(), 'question': sujet['question'].strip(),
                                          'contexte': sujet['contexte'].strip(), 'sources': sources}, prefer='return=representation')
        pid = rows[0]['id']
        options = [{'poll_id': pid, 'ordre': i + 1, 'libelle': o.strip(), 'neutre': o.strip().lower() == 'sans avis'}
                   for i, o in enumerate(sujet['options'])]
        self._req('POST', 'poll_option', options, prefer='return=minimal')
        self._req('PATCH', f'poll?id=eq.{pid}', {'publie': True}, prefer='return=minimal')
        return pid


# ---------------------------------------------------------------- Claude
def client_claude():
    import anthropic
    return anthropic.Anthropic()


def _json_final(message):
    """Dernier bloc texte JSON d'une réponse (les blocs de recherche précèdent)."""
    textes = [b.text for b in message.content if getattr(b, 'type', '') == 'text']
    for t in reversed(textes):
        m = re.search(r'\{.*\}', t, re.S)
        if m:
            try:
                return json.loads(m.group(0))
            except json.JSONDecodeError:
                continue
    raise ValueError('aucun JSON dans la réponse')


def prompt_recherche(fiche, pays_code, lundi, jour, debut, fin):
    return f"""Tu fais une recherche d'actualité pour Palabre, une app civique strictement neutre : pas de score, pas d'opinion,
jamais une question sur une personne, chaque fait renvoie à sa source. Nous sommes le {jour.isoformat()}. Pays : {fiche['nom']}.
La question sera ouverte aux citoyens la semaine du lundi {lundi.isoformat()}.

Objectif : trouver 3 à 5 sujets d'ACTUALITÉ rapportés entre le {debut.isoformat()} et le {fin.isoformat()} (les plus récents
d'abord), qui se prêtent à une question de sondage citoyenne neutre.

Critères :
- un fait précis et daté de cette période (décision du gouvernement ou du Conseil des ministres, loi votée ou débattue, annonce,
  mesure de vie quotidienne : prix, école, santé, transports, services publics), rapporté par au moins deux sources datées de la
  période, d'origines différentes. Médias reconnus : {fiche['medias']}.
- qui concerne le pays entier et sur lequel un citoyen peut avoir un avis sans connaissances techniques ;
- jamais une question sur une personne (pas de nom de dirigeant dans la question ni les options), jamais une intention de vote ;
- rien qui puisse exposer un répondant. {fiche['prudence']}
- pas un débat ancien sans fait nouveau dans la période ;
- la question ne reprend pas la justification officielle de la mesure (elle orienterait la réponse) : les arguments restent dans
  le contexte, attribués à qui les porte.

Vérifie chaque URL en l'ouvrant ; ne cite rien que tu n'as pas lu. Pour chaque sujet : "id" (mot-clé), "fait" (1 phrase datée),
"question" (neutre, une seule question, ≤ 200 caractères, terminée par « ? »), "contexte" (2 à 3 phrases strictement factuelles,
≤ 600 caractères, chaque fait couvert par une source listée), "options" (3 ou 4 options équilibrées, puis exactement « Sans avis »),
"sources" ([{{"titre","url","date":"AAAA-MM-JJ","media"}}], au moins 2 sites différents), "points_d_attention".

Réponds UNIQUEMENT par un objet JSON de la forme {{"sujets": [...], "notes": "..."}}, sans texte autour."""


def rechercher(client, fiche, pays_code, lundi, jour):
    debut, fin = fenetre(lundi, jour)
    import anthropic
    contenu = prompt_recherche(fiche, pays_code, lundi, jour, debut, fin)
    outil = {'type': 'web_search_20250305', 'name': 'web_search', 'max_uses': 25}
    try:
        msg = client.messages.create(model=MODELE, max_tokens=8000, messages=[{'role': 'user', 'content': contenu}],
                                     tools=[{**outil, 'user_location': {'type': 'approximate', 'country': pays_code, 'timezone': fiche.get('fuseau', 'UTC')}}])
    except anthropic.BadRequestError:  # pays non pris en charge par la localisation : sans localisation
        msg = client.messages.create(model=MODELE, max_tokens=8000, messages=[{'role': 'user', 'content': contenu}], tools=[outil])
    tours = 0
    while msg.stop_reason == 'pause_turn' and tours < 3:
        tours += 1
        msg = client.messages.create(model=MODELE, max_tokens=8000,
                                     messages=[{'role': 'user', 'content': contenu}, {'role': 'assistant', 'content': msg.content}],
                                     tools=[outil])
    data = _json_final(msg)
    return data.get('sujets') or [], data.get('notes') or ''


def relire(client, fiche, sujets, extraits):
    dossier = []
    for s in sujets:
        dossier.append({'sujet': s, 'extraits_sources': [{'url': src['url'], 'texte': extraits.get(src['url'], '')} for src in s['sources']]})
    prompt = f"""Tu es le relecteur indépendant de Palabre, une app civique strictement neutre ({fiche['nom']}). Tu reçois des sujets de
question de la semaine et, pour chaque source, un extrait du texte de la page. Tu n'as pas accès au web.

Pour chaque sujet, vérifie :
1. que chaque phrase du contexte est couverte par au moins un extrait de source (un fait absent des extraits = rejet) ;
2. que la question est neutre : pas de justification officielle reprise, pas de mot chargé, pas de présupposé ; les options sont
   équilibrées et ne visent aucun groupe de personnes ;
3. qu'aucune personne n'est nommée dans la question ni les options, et que répondre n'expose personne. {fiche['prudence']}
4. que le sujet est bien d'actualité (fait daté de la période) et concerne tout le pays.

Choisis le meilleur sujet qui passe les quatre vérifications, ou aucun (choix = null) si aucun ne passe. Explique en deux ou trois
phrases dans "avis", et donne un motif court pour chaque sujet écarté dans "rejets".

Dossier : {json.dumps(dossier, ensure_ascii=False)}"""
    msg = client.messages.create(model=MODELE, max_tokens=2000, messages=[{'role': 'user', 'content': prompt}],
                                 output_config={'format': {'type': 'json_schema', 'schema': SCHEMA_RELECTURE}})
    return json.loads(''.join(b.text for b in msg.content if getattr(b, 'type', '') == 'text'))


# ---------------------------------------------------------------- Pipeline
def traiter_pays(code, fiche, lundi, jour, sb, client, fixture, dry_run):
    resultat = {'pays': code, 'nom': fiche['nom'], 'rejets': []}
    if fixture is not None:
        sujets, notes = fixture, 'fixture'
    else:
        sujets, notes = rechercher(client, fiche, code, lundi, jour)
    if not sujets:
        return {**resultat, 'statut': 'aucun', 'raison': f'aucun sujet trouvé par la recherche ({notes})'}

    noms = sb.noms_personnes(code) if sb else []
    statuts = {src['url']: statut_http(src['url']) for s in sujets for src in s.get('sources') or []}
    retenus, rejets = filtrer(sujets, lundi, jour, noms, statuts)
    resultat['rejets'] = rejets
    if not retenus:
        return {**resultat, 'statut': 'aucun', 'raison': 'tous les sujets ont échoué aux contrôles automatiques'}
    if client is None:  # fixture hors ligne : on s'arrête aux contrôles
        return {**resultat, 'statut': 'publie', 'sujet': retenus[0], 'avis': 'relecture non exécutée (fixture)'}

    extraits = {src['url']: texte_page(src['url']) for s in retenus for src in s['sources']}
    relecture = relire(client, fiche, retenus, extraits)
    resultat['rejets'] += [{'id': r['id'], 'motifs': [r['motif']]} for r in relecture.get('rejets') or []]
    choix = next((s for s in retenus if s['id'] == relecture.get('choix')), None)
    if choix is None:
        return {**resultat, 'statut': 'aucun', 'raison': f"le relecteur n'a retenu aucun sujet : {relecture.get('avis')}"}
    if not dry_run:
        sb.publier(code, lundi, choix)
    return {**resultat, 'statut': 'publie', 'sujet': choix, 'avis': relecture.get('avis')}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--semaine', help='lundi visé AAAA-MM-JJ (défaut : prochain lundi)')
    ap.add_argument('--pays', help='codes séparés par des virgules (défaut : pays actifs)')
    ap.add_argument('--fixture', help='JSON {code: [sujets]} remplaçant la recherche ; sans relecture ni publication')
    ap.add_argument('--sortie', default='.', help='dossier des rapports')
    ap.add_argument('--jour', help="date d'exécution simulée AAAA-MM-JJ (tests)")
    a = ap.parse_args()

    jour = dt.date.fromisoformat(a.jour) if a.jour else dt.date.today()
    lundi = dt.date.fromisoformat(a.semaine) if a.semaine else lundi_vise(jour)
    fiches = json.load(open(os.path.join(ICI, 'pays.json'), encoding='utf-8'))
    fixture = json.load(open(a.fixture, encoding='utf-8')) if a.fixture else None

    sb = Supabase(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY']) if os.environ.get('SUPABASE_URL') else None
    client = None if fixture is not None else client_claude()
    if a.pays:
        pays = [{'code': c.strip().upper(), 'fuseau': fiches.get(c.strip().upper(), {}).get('fuseau', 'UTC')} for c in a.pays.split(',')]
    elif sb:
        pays = sb.pays_actifs()
    else:
        sys.exit('ni --pays ni SUPABASE_URL')

    resultats, erreur = [], False
    for p in pays:
        code = p['code']
        fiche = {**fiches.get(code, {'nom': code, 'medias': '', 'prudence': ''}), 'fuseau': p.get('fuseau', 'UTC')}
        try:
            if sb and sb.sondage_existe(code, lundi):
                resultats.append({'pays': code, 'nom': fiche['nom'], 'statut': 'aucun', 'raison': 'un sondage existe déjà pour cette semaine', 'rejets': []})
                continue
            resultats.append(traiter_pays(code, fiche, lundi, jour, sb, client, (fixture or {}).get(code) if fixture else None, a.dry_run))
        except Exception as e:  # une erreur sur un pays n'empêche pas les autres
            erreur = True
            traceback.print_exc()
            resultats.append({'pays': code, 'nom': fiche['nom'], 'statut': 'erreur', 'raison': f'{type(e).__name__} : {e}', 'rejets': []})

    url_retrait = f"{os.environ.get('GITHUB_SERVER_URL', 'https://github.com')}/{os.environ.get('GITHUB_REPOSITORY', 'teiki5320/palabre')}/actions/workflows/retirer-question.yml"
    os.makedirs(a.sortie, exist_ok=True)
    md = rendre_rapport(lundi, resultats, url_retrait, a.dry_run)
    open(os.path.join(a.sortie, 'rapport.md'), 'w', encoding='utf-8').write(md)
    json.dump({'semaine': lundi.isoformat(), 'resultats': resultats}, open(os.path.join(a.sortie, 'rapport.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(md)
    sys.exit(1 if erreur else 0)


if __name__ == '__main__':
    main()
