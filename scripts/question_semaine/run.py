#!/usr/bin/env python3
"""Question de la semaine automatique.

Pour chaque pays actif sans sondage pour la semaine visée : recherche d'actualité (Claude + recherche
web), contrôles automatiques, relecture indépendante (Claude, sans web), publication dans Supabase,
rapport Markdown. Voir docs/superpowers/specs/2026-09-12-question-semaine-auto-design.md.

Usage : run.py [--dry-run] [--semaine AAAA-MM-JJ] [--pays BJ,CI] [--fixture sujets.json] [--sortie DOSSIER]
Prérequis : CLI Supabase relié au projet de production (supabase link), pas de clé.
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
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from controles import filtrer, lundi_vise  # noqa: E402
from rapport import rendre_rapport  # noqa: E402

ICI = os.path.dirname(os.path.abspath(__file__))
MODELE = 'claude-opus-5'
UA = 'Palabre question-semaine (+https://github.com/teiki5320/palabre)'

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


# ---------------------------------------------------------------- Supabase (CLI relié au projet)
RACINE = os.path.dirname(os.path.dirname(ICI))


def sql_question(pays, lundi, sujet):
    q = lambda t: "'" + str(t).replace("'", "''") + "'"
    sources = json.dumps([{'titre': x['titre'], 'url': x['url'], 'date': x['date']} for x in sujet['sources']], ensure_ascii=False).replace("'", "''")
    rows = ',\n'.join(f"  ({i + 1}, {q(o.strip())}, {'true' if o.strip().lower() == 'sans avis' else 'false'})" for i, o in enumerate(sujet['options']))
    return f"""-- Palabre — question de la semaine du lundi {lundi.isoformat()} ({pays}).
-- Générée par scripts/question_semaine/run.py à partir de la recherche d'actualité de la tâche planifiée.

begin;

with q as (
  insert into public.poll (country_code, semaine, question, contexte, sources)
  values ({q(pays)}, {q(lundi.isoformat())}, {q(sujet['question'].strip())}, {q(sujet['contexte'].strip())}, '{sources}'::jsonb)
  returning id
)
insert into public.poll_option (poll_id, ordre, libelle, neutre)
select id, ordre, libelle, neutre from q, (values
{rows}
) as o(ordre, libelle, neutre);

update public.poll set publie = true where country_code = {q(pays)} and semaine = {q(lundi.isoformat())};

commit;
"""


def supabase_query(sql_ou_fichier, fichier=False):
    import subprocess
    cmd = ['supabase', 'db', 'query', '--linked'] + (['-f', sql_ou_fichier] if fichier else [sql_ou_fichier])
    r = subprocess.run(cmd, cwd=RACINE, capture_output=True, text=True)
    out = r.stdout + r.stderr
    if r.returncode != 0 or 'ERROR:' in out or '"error"' in out:
        raise RuntimeError(out.strip()[-800:])
    return out


def _rows(out):
    try:
        j = json.loads(out[out.index('{'):out.rindex('}') + 1])
        return next(v for v in j.values() if isinstance(v, list))
    except Exception:
        return []


class Supabase:
    """Lecture et écriture via `supabase db query --linked` (projet de production relié sur ce Mac)."""

    def pays_actifs(self):
        return _rows(supabase_query("select c.code, c.nom, c.fuseau from public.country c join public.country_module m on m.country_code = c.code and m.module = 'poll' and m.actif where c.actif order by c.code"))

    def sondage_existe(self, pays, lundi):
        return bool(_rows(supabase_query(f"select id from public.poll where country_code = '{pays}' and semaine = '{lundi.isoformat()}'")))

    def noms_personnes(self, pays):
        return [r['nom'] for r in _rows(supabase_query(f"select nom from public.person where country_code = '{pays}'"))]

    def publier(self, pays, lundi, sujet):
        dossier = os.path.join(RACINE, 'supabase', 'prod', pays.lower(), 'questions')
        os.makedirs(dossier, exist_ok=True)
        chemin = os.path.join(dossier, f'{lundi.isoformat()}.sql')
        open(chemin, 'w', encoding='utf-8').write(sql_question(pays, lundi, sujet))
        supabase_query(chemin, fichier=True)
        return chemin


# ---------------------------------------------------------------- Pipeline
def traiter_pays(code, fiche, lundi, jour, sb, sujets, publier):
    """Contrôles puis publication du premier sujet retenu (la tâche planifiée met son choix en premier)."""
    resultat = {'pays': code, 'nom': fiche['nom'], 'rejets': []}
    if not sujets:
        return {**resultat, 'statut': 'aucun', 'raison': 'aucun sujet proposé par la recherche'}
    noms = sb.noms_personnes(code) if sb else []
    statuts = {src['url']: statut_http(src['url']) for s in sujets for src in s.get('sources') or []}
    retenus, rejets = filtrer(sujets, lundi, jour, noms, statuts)
    resultat['rejets'] = rejets
    if not retenus:
        return {**resultat, 'statut': 'aucun', 'raison': 'tous les sujets ont échoué aux contrôles automatiques'}
    choix = retenus[0]
    if publier:
        sb.publier(code, lundi, choix)
    return {**resultat, 'statut': 'publie', 'sujet': choix, 'avis': choix.get('points_d_attention') or ''}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--sujets', required=True, help='JSON {code_pays: [sujets]} issu de la recherche, choix en premier')
    ap.add_argument('--publier', action='store_true', help='écrire et exécuter le SQL (sinon simulation)')
    ap.add_argument('--semaine', help='lundi visé AAAA-MM-JJ (défaut : prochain lundi)')
    ap.add_argument('--pays', help='codes séparés par des virgules (défaut : pays du fichier)')
    ap.add_argument('--sortie', default='.', help='dossier des rapports')
    ap.add_argument('--jour', help="date d'exécution simulée AAAA-MM-JJ (tests)")
    a = ap.parse_args()

    jour = dt.date.fromisoformat(a.jour) if a.jour else dt.date.today()
    lundi = dt.date.fromisoformat(a.semaine) if a.semaine else lundi_vise(jour)
    fiches = json.load(open(os.path.join(ICI, 'pays.json'), encoding='utf-8'))
    sujets_par_pays = json.load(open(a.sujets, encoding='utf-8'))
    sb = Supabase() if a.publier else None
    codes = [c.strip().upper() for c in a.pays.split(',')] if a.pays else list(sujets_par_pays)
    pays = [{'code': c} for c in codes]

    resultats, erreur = [], False
    for p in pays:
        code = p['code']
        fiche = fiches.get(code, {'nom': code, 'medias': '', 'prudence': ''})
        try:
            if sb and sb.sondage_existe(code, lundi):
                resultats.append({'pays': code, 'nom': fiche['nom'], 'statut': 'aucun', 'raison': 'un sondage existe déjà pour cette semaine', 'rejets': []})
                continue
            resultats.append(traiter_pays(code, fiche, lundi, jour, sb, sujets_par_pays.get(code) or [], a.publier))
        except Exception as e:  # une erreur sur un pays n'empêche pas les autres
            erreur = True
            traceback.print_exc()
            resultats.append({'pays': code, 'nom': fiche['nom'], 'statut': 'erreur', 'raison': f'{type(e).__name__} : {e}', 'rejets': []})

    os.makedirs(a.sortie, exist_ok=True)
    md = rendre_rapport(lundi, resultats, dry_run=not a.publier)
    open(os.path.join(a.sortie, 'rapport.md'), 'w', encoding='utf-8').write(md)
    json.dump({'semaine': lundi.isoformat(), 'resultats': resultats}, open(os.path.join(a.sortie, 'rapport.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(md)
    sys.exit(1 if erreur else 0)


if __name__ == '__main__':
    main()
