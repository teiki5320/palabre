#!/usr/bin/env python3
"""Génère les scripts SQL de production à partir des fichiers JSON de recherche.

Usage : gen_prod_sql.py [SN|BJ] [--out DOSSIER]

Entrées (supabase/prod/sources, ou sources/<pays> hors Sénégal) : government.json,
assembly.json, parties.json, quiz_statements.json, positions.json (facultatif).
Sorties : 03_partis.sql, 04_gouvernement.sql, 05_assemblee.sql, 06_quiz.sql dans
supabase/prod (Sénégal) ou supabase/prod/<pays>.

Identifiants explicites, décalés par pays (Sénégal 0, Bénin 10 000) pour que
les pays se chargent l'un après l'autre sans collision. Chaque ligne porte
sa source. Rien n'est inventé : un champ absent reste NULL.
"""
import json
import os
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARGS = sys.argv[1:]
OUT_ARG = ARGS[ARGS.index('--out') + 1] if '--out' in ARGS else None
CC = next((a.upper() for a in ARGS if not a.startswith('--') and a != OUT_ARG), 'SN')
PAYS = {
    'SN': {'nom': 'Sénégal', 'offset': 0, 'sources': 'sources', 'sortie': ''},
    'BJ': {'nom': 'Bénin', 'offset': 10000, 'sources': 'sources/bj', 'sortie': 'bj'},
}[CC]
OFFSET = PAYS['offset']
HERE = os.path.join(ROOT, 'supabase', 'prod', PAYS['sources'])
OUT = OUT_ARG or os.path.join(ROOT, 'supabase', 'prod', PAYS['sortie'])
SN = CC  # nom historique : code du pays généré


def o(n):
    """Identifiant explicite décalé pour le pays."""
    return n + OFFSET


def q(s):
    if s is None or s == '':
        return 'null'
    return "'" + str(s).replace("'", "''") + "'"


def d(s):
    if not s:
        return 'null'
    s = str(s)
    if len(s) == 4:
        s = f'{s}-01-01'
    elif len(s) == 7:
        s = f'{s}-01'
    return q(s)


def norm(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode()
    return ''.join(c if c.isalnum() else '_' for c in s.lower()).strip('_')


def load(name, default=None):
    p = os.path.join(HERE, name)
    if not os.path.exists(p):
        return default
    with open(p, encoding='utf-8') as f:
        return json.load(f)


# ---------------------------------------------------------------------------
# Départements → régions (codes ISO 3166-2:SN de 01_configuration.sql)
# ---------------------------------------------------------------------------
DEPT_REGION = {
    'Dakar': 'DK', 'Guédiawaye': 'DK', 'Pikine': 'DK', 'Rufisque': 'DK', 'Keur Massar': 'DK',
    'Bambey': 'DB', 'Diourbel': 'DB', 'Mbacké': 'DB',
    'Fatick': 'FK', 'Foundiougne': 'FK', 'Gossas': 'FK',
    'Birkelane': 'KA', 'Kaffrine': 'KA', 'Koungheul': 'KA', 'Malem Hodar': 'KA',
    'Guinguinéo': 'KL', 'Kaolack': 'KL', 'Nioro du Rip': 'KL',
    'Kédougou': 'KE', 'Salémata': 'KE', 'Saraya': 'KE',
    'Kolda': 'KD', 'Médina Yoro Foulah': 'KD', 'Vélingara': 'KD',
    'Kébémer': 'LG', 'Linguère': 'LG', 'Louga': 'LG',
    'Kanel': 'MT', 'Matam': 'MT', 'Ranérou': 'MT',
    'Dagana': 'SL', 'Podor': 'SL', 'Saint-Louis': 'SL',
    'Bounkiling': 'SE', 'Goudomp': 'SE', 'Sédhiou': 'SE',
    'Bakel': 'TC', 'Goudiry': 'TC', 'Koumpentoum': 'TC', 'Tambacounda': 'TC',
    'Mbour': 'TH', 'Thiès': 'TH', 'Tivaouane': 'TH',
    'Bignona': 'ZG', 'Oussouye': 'ZG', 'Ziguinchor': 'ZG',
}
if CC == 'BJ':
    # Bénin : les 12 départements servent de régions (codes ISO 3166-2:BJ).
    DEPT_REGION = {
        'Alibori': 'AL', 'Atacora': 'AK', 'Atlantique': 'AQ', 'Borgou': 'BO', 'Collines': 'CO', 'Couffo': 'KO',
        'Donga': 'DO', 'Littoral': 'LI', 'Mono': 'MO', 'Ouémé': 'OU', 'Plateau': 'PL', 'Zou': 'ZO',
    }
DEPT_BY_NORM = {norm(k): (k, v) for k, v in DEPT_REGION.items()}
# Variantes d'orthographe rencontrées dans les sources.
DEPT_BY_NORM.update({norm('Kouffo'): ('Couffo', 'KO')} if CC == 'BJ' else {norm('Birkilane'): ('Birkilane', 'KA'), norm('Ranérou Ferlo'): ('Ranérou Ferlo', 'MT'), norm('Ranerou-Ferlo'): ('Ranérou Ferlo', 'MT')})
LIST_ALIASES = {'MOELE-BENIN': 'MOELE-Bénin'} if CC == 'BJ' else {'TAKKU WALLU SENEGAL': 'TWS', 'JAMM AK NJARIÑ': 'JAN', 'SAMM SA KADDU': 'SSK', 'PASTEF': 'PASTEF'}

# Blocs ministériels par mots-clés (premier qui correspond).
BLOCS = [
    ('regalien', ['forces arm', 'intérieur', 'interieur', 'justice', 'affaires étrang', 'affaires etrang', 'intégration afric', 'integration afric', 'secrétaire général du gouvernement', 'secretaire general du gouvernement', 'porte-parole', 'fonction publique', 'collectivités', 'collectivites', 'territoriale']),
    ('economie', ['économie', 'economie', 'finances', 'budget', 'commerce', 'industrie', 'agriculture', 'élevage', 'elevage', 'pêche', 'peche', 'tourisme', 'artisanat', 'mines', 'énergie', 'energie', 'pétrole', 'petrole', 'microfinance', 'entrepreneuriat', 'planification', 'coopération', 'cooperation']),
    ('social', ['santé', 'sante', 'éducation', 'education', 'enseignement', 'formation', 'travail', 'emploi', 'jeunesse', 'sport', 'culture', 'famille', 'femme', 'solidarit', 'action sociale', 'communication', 'religieu']),
    ('infrastructure', ['infrastructure', 'transport', 'urbanisme', 'habitat', 'hydraulique', 'assainissement', 'numérique', 'numerique', 'télécom', 'telecom', 'environnement', 'transition écologique', 'transition ecologique', 'aménagement', 'amenagement', 'eau ']),
]


def bloc_of(intitule):
    low = intitule.lower()
    for bloc, keys in BLOCS:
        if any(k in low for k in keys):
            return bloc
    return None


def portfolio_norm(intitule):
    """Clé stable d'un portefeuille : premier mot significatif après « Ministre de/du/des »."""
    low = intitule.lower()
    for prefix in ['ministre de la ', 'ministre de l\'', 'ministre du ', 'ministre des ', 'ministre de ', 'ministre d\'', 'ministre ', 'ministère de la ', 'ministère de l\'', 'ministère du ', 'ministère des ', 'ministère de ']:
        if low.startswith(prefix):
            low = low[len(prefix):]
            break
    return norm(low.split(',')[0].split(' et ')[0])[:60]


# ---------------------------------------------------------------------------
ALIAS = (load('mandats_speciaux.json', {}) or {}).get('alias', {})


class Ids:
    def __init__(self):
        self.person = {}
        self.org = {}
        self.next_person = o(1)
        self.next_org = o(1)

    def person_id(self, nom):
        key = ALIAS.get(nom.strip(), nom.strip())
        if key not in self.person:
            self.person[key] = self.next_person
            self.next_person += 1
        return self.person[key]

    def org_id(self, key):
        if key not in self.org:
            self.org[key] = self.next_org
            self.next_org += 1
        return self.org[key]


def header(title):
    return f"""-- Palabre — production {PAYS['nom']} : {title}
-- Généré par gen_sql.py depuis les fichiers de recherche sourcés.
-- Chaque ligne porte sa source. Aucune donnée fictive.
-- À exécuter avec : supabase db query --linked -f <ce fichier>

begin;

"""


def gen_parties(ids, parties):
    out = [header('partis, coalitions et groupes')]
    out.append('insert into public.organization (id, country_code, type, nom, sigle, couleur, fondation, source_url) values')
    rows = []
    for p in parties['partis']:
        oid = ids.org_id(p['sigle'])
        fond = p.get('fondation') or None
        rows.append(f"  ({oid}, {q(SN)}, {q(p['type'])}, {q(p['nom'])}, {q(p['sigle'])}, {q(p.get('couleur') or None)}, {d(fond)}, {q(p.get('source_url') or p.get('wikipedia') or None)})")
    out.append(',\n'.join(rows) + ';\n')
    rel = parties.get('relations') or []
    if rel:
        out.append('insert into public.org_relation (from_id, to_id, type, date, source_url) values')
        rrows = []
        for r in rel:
            # Seuls les types du schéma ; les alliances et soutiens restent dans les sources.
            if r['de'] in ids.org and r['vers'] in ids.org and r['type'] in ('scission', 'fusion', 'renommage', 'coalition_membre', 'absorption'):
                rrows.append(f"  ({ids.org[r['de']]}, {ids.org[r['vers']]}, {q(r['type'])}, {d(r.get('date'))}, {q(r.get('source_url'))})")
        out.append(',\n'.join(rrows) + ';\n')
    # Dirigeants : rôle « dirigeant_parti » sans mandat daté si la date manque.
    return '\n'.join(out)


def gen_government(ids, gov):
    out = [header('gouvernement en exercice')]
    g = gov['gouvernement']
    # Le Secrétaire général du Gouvernement béninois n'est pas membre du gouvernement.
    gov = {**gov, 'ministres': [m for m in gov['ministres'] if m.get('type') != 'secretaire_general']}
    # Sénégal : Premier ministre ; Bénin : le Président de la République.
    pm = gov.get('premier_ministre') or gov['chef_gouvernement']
    pm_intitule = pm.get('intitule') or 'Premier ministre'
    pm_id = ids.person_id(pm['nom'])
    persons = [(pm_id, pm['nom'])]
    out.append(f"insert into public.person (id, country_code, nom) values\n  ({pm_id}, {q(SN)}, {q(pm['nom'])})")
    prow = []
    for m in gov['ministres']:
        pid = ids.person_id(m['nom'])
        if pid != pm_id and all(pid != x[0] for x in persons):
            persons.append((pid, m['nom']))
            prow.append(f"  ({pid}, {q(SN)}, {q(m['nom'])})")
    if prow:
        out[-1] += ',\n' + ',\n'.join(prow)
    out[-1] += ';\n'

    gov_org = ids.org_id('GOUV')
    out.append(f"insert into public.organization (id, country_code, type, nom, source_url) values\n  ({gov_org}, {q(SN)}, 'gouvernement', {q(g['nom'])}, {q(g['source_url'])});\n")
    out.append(f"insert into public.government (id, country_code, nom, chef_gouv_id, debut, portefeuilles_total, decret_ref, source_url) values\n  ({o(1)}, {q(SN)}, {q(g['nom'])}, {pm_id}, {q(g['debut'])}, {len(gov['ministres'])}, {q(g['decret_ref'])}, {q(g['source_url'])});\n")
    out.append(f"insert into public.role (id, country_code, type, intitule, intitule_norm, organization_id) values\n  ({o(1)}, {q(SN)}, 'chef_gouvernement', {q(pm_intitule)}, {q(norm(pm_intitule))}, {gov_org}),\n  ({o(2)}, {q(SN)}, 'ministre', 'Ministre', 'ministre', {gov_org}),\n  ({o(3)}, {q(SN)}, 'depute', 'Député', 'depute', null);\n")

    prows = []
    unmapped = []
    pf_ids = {}
    for i, m in enumerate(gov['ministres'], start=1):
        bloc = m.get('bloc') or bloc_of(m['intitule'])
        if bloc is None:
            unmapped.append(m['intitule'])
            bloc = 'economie'
        pf_ids[m['nom']] = o(i)
        prows.append(f"  ({o(i)}, {q(SN)}, {q(m['intitule'])}, {q(portfolio_norm(m['intitule']))}, {q(bloc)}, {m.get('ordre', i)})")
    out.append('insert into public.portfolio (id, country_code, intitule, intitule_norm, bloc, rang) values\n' + ',\n'.join(prows) + ';\n')
    if unmapped:
        out.append('-- Blocs à vérifier à la main (mot-clé non reconnu, mis en « economie ») :\n' + ''.join(f'--   {u}\n' for u in unmapped))

    mrows = [f"  ({pm_id}, {o(1)}, null, {o(1)}, {q(pm.get('date_nomination') or pm.get('date_investiture'))}, {q(pm.get('decret_ref') or pm.get('acte_ref'))}, {q(pm['source_url'])}, 'communique')"]
    for m in gov['ministres']:
        mrows.append(f"  ({ids.person_id(m['nom'])}, {o(2)}, {pf_ids[m['nom']]}, {o(1)}, {q(g['debut'])}, {q(g['decret_ref'] if not m.get('source_url') else None)}, {q(m.get('source_url') or g['source_url'])}, 'communique')")
    out.append('insert into public.mandate (person_id, role_id, portfolio_id, government_id, debut, acte_ref, source_url, confiance) values\n' + ',\n'.join(mrows) + ';\n')
    for r in gov.get('remaniements') or []:
        out.append(f"-- Remaniement signalé, à modéliser à la main : {r.get('date')} — {r.get('description')} ({r.get('source_url')})\n")
    return '\n'.join(out)


def gen_assembly(ids, asm, parties):
    out = [header(f"{asm['legislature']['numero']}e législature")]
    leg = asm['legislature']
    out.append(f"insert into public.legislature (id, country_code, numero, debut, sieges_total, scrutins_nominatifs, source_url) values\n  ({o(1)}, {q(SN)}, {leg['numero']}, {q(leg['debut'])}, {leg['sieges_total']}, false, {q(leg.get('source_url'))});\n")

    asm_org = ids.org_id('AN')
    out.append(f"insert into public.organization (id, country_code, type, nom, sigle, source_url) values\n  ({asm_org}, {q(SN)}, 'assemblee', 'Assemblée nationale', 'AN', {q(leg.get('source_url'))});\n")

    # Groupes parlementaires
    grp_ids = {}
    grows = []
    for gp in asm.get('groupes') or []:
        if gp['nom'].lower().startswith('non inscrit'):
            continue
        gid = ids.org_id('GRP:' + gp['nom'])
        grp_ids[gp['nom']] = gid
        grows.append(f"  ({gid}, {q(SN)}, 'groupe_parlementaire', {q(gp['nom'])}, {q(gp.get('sigle'))}, {q(gp.get('couleur'))}, {asm_org}, {q(gp.get('source_url'))})")
    if grows:
        out.append('insert into public.organization (id, country_code, type, nom, sigle, couleur, parent_id, source_url) values\n' + ',\n'.join(grows) + ';\n')

    # Listes électorales absentes de parties.json : coalitions ou entités
    lrows = []
    for lst in asm.get('listes') or []:
        key = LIST_ALIASES.get(lst.get('sigle'), lst.get('sigle'))
        if key in ids.org:
            continue
        oid = ids.org_id(key)
        lrows.append(f"  ({oid}, {q(SN)}, 'coalition', {q(lst['nom'])}, {q(lst.get('sigle'))}, {q(leg.get('source_url'))})")
    if lrows:
        out.append('insert into public.organization (id, country_code, type, nom, sigle, source_url) values\n' + ',\n'.join(lrows) + ';\n')

    # Circonscriptions
    cons = {}
    crows = []
    cid = 0
    notes = []
    for dep in asm['deputes']:
        key = dep['circonscription'].strip()
        if key in cons:
            continue
        cid += 1
        t = dep.get('type_circonscription') or 'departement'
        region = 'null'
        nom = key
        if t == 'departement':
            hit = DEPT_BY_NORM.get(norm(dep.get('departement') or key))
            if hit:
                code = hit[1]
                if not dep.get('departement'):
                    nom = hit[0]
                region = f"(select id from public.region where country_code = '{CC}' and code = '{code}')"
            else:
                notes.append(f'département non reconnu : {key}')
        cons[key] = o(cid)
        crows.append((o(cid), nom, t, region))
    seats = {}
    for dep in asm['deputes']:
        seats[dep['circonscription'].strip()] = seats.get(dep['circonscription'].strip(), 0) + 1
    out.append('insert into public.constituency (id, country_code, legislature_id, nom, type, sieges, region_id) values\n' +
               ',\n'.join(f"  ({c}, {q(SN)}, {o(1)}, {q(n)}, {q(t)}, {seats[k]}, {r})" for (c, n, t, r), k in zip(crows, cons.keys())) + ';\n')

    # Personnes et mandats (ids explicites pour la suppléance)
    special = load('mandats_speciaux.json', {}) or {}
    cases = {c['depute']: c for c in special.get('cas', [])}
    for r in special.get('roles_supplementaires', []):
        out.append(f"insert into public.role (id, country_code, type, intitule, intitule_norm, organization_id) values\n  ({o(r['id'])}, {q(SN)}, {q(r['type'])}, {q(r['intitule'])}, {q(r['intitule_norm'])}, {asm_org});\n")
    src = leg.get('source_mandats') or leg.get('source_url')
    src_groupes = leg.get('source_affiliation_groupes') or src
    persons = {}
    mrows = []
    arows = []
    mid = [o(100)]  # les mandats du gouvernement occupent les ids 1..99 (décalés)

    def person_row(nom):
        pid = ids.person_id(nom)
        persons.setdefault(pid, ALIAS.get(nom.strip(), nom.strip()))
        return pid

    def mandate(pid, c, debut, fin=None, motif=None, source=None, qualite='titulaire', remplace=None, role=None):
        role = o(3) if role is None else role
        mid[0] += 1
        mrows.append(f"  ({mid[0]}, {pid}, {role}, {c if c is not None else 'null'}, {q(debut)}, {d(fin)}, {q(motif)}, {q(source or src)}, {q(qualite)}, {remplace if remplace else 'null'}, 'presse' if False else 'journal_officiel')".replace("'presse' if False else 'journal_officiel'", "'journal_officiel'" if source is None else "'presse'"))
        return mid[0]

    for dep in asm['deputes']:
        pid = person_row(dep['nom'])
        c = cons[dep['circonscription'].strip()]
        if dep.get('statut') == 'sorti':
            # Mandat créé par le cas de son remplaçant ; on garde la liste d'élection.
            lst = LIST_ALIASES.get(dep.get('liste'), dep.get('liste'))
            if lst and lst in ids.org:
                arows.append(f"  ({pid}, {ids.org[lst]}, {q(leg['debut'])}, {q(src)})")
            continue
        case = cases.get(dep['nom'])
        if case is None:
            if dep.get('statut') == 'suppleant_en_exercice':
                notes.append(f"suppléant sans cas documenté : {dep['nom']}")
                continue
            mandate(pid, c, leg['debut'])
        elif 'segments' in case:
            if case.get('predecesseur'):
                p = case['predecesseur']
                mandate(person_row(p['nom']), c, p['debut'], p.get('fin'), p.get('motif_fin'), p.get('source_url'))
            for seg in case['segments']:
                tid = mandate(pid, c, seg['debut'], seg.get('fin'), seg.get('motif_fin'), seg.get('source_url'))
                if seg.get('suppleant'):
                    sp = seg['suppleant']
                    mandate(person_row(sp['nom']), c, sp['debut'], sp.get('fin'), sp.get('motif_fin'), sp.get('source_url'), 'suppleant', tid)
            if case.get('presidence'):
                pr = case['presidence']
                mandate(pid, None, pr['debut'], pr.get('fin'), pr.get('motif_fin'), pr.get('source_url'), role=o(4))
        else:
            t = case['titulaire']
            tid = mandate(person_row(t['nom']), c, t['debut'], t.get('fin'), t.get('motif_fin'), t.get('source_url'))
            sp = case['suppleant']
            mandate(pid, c, sp['debut'], sp.get('fin'), sp.get('motif_fin'), sp.get('source_url'), 'suppleant', tid)
        grp = dep.get('groupe')
        if grp and grp in grp_ids and not grp.lower().startswith('non inscrit'):
            arows.append(f"  ({pid}, {grp_ids[grp]}, {q(leg['debut'])}, {q(src_groupes)})")
        lst = LIST_ALIASES.get(dep.get('liste'), dep.get('liste'))
        if lst and lst in ids.org:
            arows.append(f"  ({pid}, {ids.org[lst]}, {q(leg['debut'])}, {q(src)})")
    pres = asm.get('president') or {}
    if pres.get('date_election') and not any(c.get('presidence') for c in cases.values()):
        mandate(person_row(pres['nom']), None, pres['date_election'], source=pres.get('source_url'), role=o(4))
    out.append('insert into public.person (id, country_code, nom) values\n' + ',\n'.join(f"  ({pid}, {q(SN)}, {q(nom)})" for pid, nom in persons.items()) + '\non conflict (id) do nothing;\n')
    out.append('insert into public.mandate (id, person_id, role_id, constituency_id, debut, fin, motif_fin, source_url, qualite, remplace_mandate_id, confiance) values\n' + ',\n'.join(mrows) + ';\n')
    if arows:
        out.append('insert into public.affiliation (person_id, organization_id, debut, source_url) values\n' + ',\n'.join(arows) + ';\n')
    for c in special.get('cas', []):
        if c.get('note'):
            notes.append(f"{c['depute']} : {c['note']}")
    for n in notes:
        out.append(f'-- À traiter : {n}\n')
    return '\n'.join(out)


def gen_quiz(ids, quiz, positions):
    out = [header('quiz « Testez-vous »')]
    out.append(f"insert into public.quiz (id, country_code, titre, version, publie) values\n  ({o(1)}, {q(SN)}, {q(quiz['titre'])}, 1, false);\n")
    srows = [f"  ({o(a['ordre'])}, {o(1)}, {a['ordre']}, {q(a['texte'])}, {q(a['theme'])})" for a in quiz['affirmations']]
    out.append('insert into public.statement (id, quiz_id, ordre, texte, theme) values\n' + ',\n'.join(srows) + ';\n')
    pos = {(p['ordre'], p['sigle']): p for p in (positions or {}).get('positions', [])}
    orgs = (positions or {}).get('partis') or [p['sigle'] for p in (load('parties.json') or {}).get('partis', []) if p.get('type') == 'parti']
    prows = []
    for a in quiz['affirmations']:
        for sigle in orgs:
            if sigle not in ids.org:
                continue
            p = pos.get((a['ordre'], sigle))
            if p and p.get('position') != 'sans_position':
                prows.append(f"  ({o(a['ordre'])}, {ids.org[sigle]}, {q(p['position'])}, 'document_public', {q(p['source_url'])}, {q(p['source_extrait'][:600])}, {q(p['date_source'])})")
            else:
                prows.append(f"  ({o(a['ordre'])}, {ids.org[sigle]}, 'sans_position', 'aucune', null, null, null)")
    if prows:
        out.append('insert into public.party_position (statement_id, org_id, position, source_type, source_url, source_extrait, date_source) values\n' + ',\n'.join(prows) + ';\n')
    out.append(f"-- Une fois relu : update public.quiz set publie = true where id = {o(1)};\n")
    return '\n'.join(out)


def main():
    parties = load('parties.json')
    gov = load('government.json')
    asm = load('assembly.json')
    quiz = load('quiz_statements.json')
    positions = load('positions.json', {})
    ids = Ids()
    os.makedirs(OUT, exist_ok=True)
    files = []
    if parties:
        files.append(('03_partis.sql', gen_parties(ids, parties)))
    if gov:
        files.append(('04_gouvernement.sql', gen_government(ids, gov)))
    if asm:
        files.append(('05_assemblee.sql', gen_assembly(ids, asm, parties)))
    if quiz:
        files.append(('06_quiz.sql', gen_quiz(ids, quiz, positions)))
    tail = f"\nselect setval('public.person_id_seq', (select coalesce(max(id), 1) from public.person));\nselect setval('public.organization_id_seq', (select coalesce(max(id), 1) from public.organization));\nselect setval('public.portfolio_id_seq', (select coalesce(max(id), 1) from public.portfolio));\nselect setval('public.role_id_seq', (select coalesce(max(id), 1) from public.role));\nselect setval('public.government_id_seq', (select coalesce(max(id), 1) from public.government));\nselect setval('public.mandate_id_seq', (select coalesce(max(id), 1) from public.mandate));\nselect setval('public.legislature_id_seq', (select coalesce(max(id), 1) from public.legislature));\nselect setval('public.constituency_id_seq', (select coalesce(max(id), 1) from public.constituency));\nselect setval('public.quiz_id_seq', (select coalesce(max(id), 1) from public.quiz));\nselect setval('public.statement_id_seq', (select coalesce(max(id), 1) from public.statement));\n\ncommit;\n"
    for name, body in files:
        with open(os.path.join(OUT, name), 'w', encoding='utf-8') as f:
            f.write(body + tail)
        print('écrit', name)


if __name__ == '__main__':
    main()
