#!/usr/bin/env python3
"""Écrit « Comment une romance se joue », à partir des cartes elles-mêmes.

    python3 outils/planche_romances.py <fichier.html>

Dix échelles de six cartes, le rendez-vous qui s'ouvre au troisième cran,
et ce que la chambre montre alors. Rien n'est écrit à la main ici : les
textes viennent de `cartes.json`, les crans des conditions, les délais des
chaînes. Une carte réécrite change la page au tour suivant.
"""

import json
import os
import re
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# La chaîne de chaque personne. Deux d'entre elles ne portent pas leur
# identifiant : l'épouse et l'époux du jeu d'avant la romance ont gardé
# leurs noms de rôle, « protocole » et « intendant ».
CHAINES = {
    'redactrice': 'coeur_redactrice', 'cabinet': 'coeur_cabinet',
    'emissaire': 'coeur_emissaire', 'militante': 'coeur_militante',
    'epouse': 'coeur_protocole', 'international': 'coeur_international',
    'ministre': 'coeur_ministre', 'renseignements': 'coeur_renseignements',
    'maire': 'coeur_maire', 'epoux': 'coeur_intendant',
}

# Ceux dont la chambre se raconte au masculin. Le jeu ne porte pas le
# genre de ses personnages — seule cette page a besoin de l'accord.
HOMMES = {'international', 'ministre', 'renseignements', 'maire', 'epoux'}

# Ce que vaut chaque cran, dans les mots du jeu.
CRANS = ['rien', 'un regard', 'un geste', 'une liaison', 'au grand jour', 'une demande']

# Le cran à partir duquel le rendez-vous peut sortir, et la chambre se
# partager. Lu dans romance.dart plutôt que recopié.
def cran_liaison():
    src = open(os.path.join(RACINE, 'lib/moteur/romance.dart')).read()
    trouve = re.search(r'attacheLiaison\s*=\s*(\d+)', src)
    if trouve is None:
        sys.exit('romance.dart : cran de liaison introuvable')
    return int(trouve.group(1))


def echappe(s):
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
             .replace('"', '&quot;'))


def habille(texte):
    """Le texte tel que le joueur le lit, titre et nom posés."""
    return texte.replace('{titre}', 'Madame la Présidente').replace('{nom}', 'Awa')


def mouvement(reponse):
    r = reponse.get('romance', {})
    if r.get('epouse'):
        return 'mariage'
    if r.get('rupture'):
        return 'rupture'
    m = r.get('mouvement', 0)
    return f'+{m}' if m > 0 else (str(m) if m else None)


def apres_le_mariage(cartes):
    """Les cartes qui n'existent qu'une fois marié. Elles ne nomment
    personne : c'est la personne épousée qui les dit, quelle qu'elle soit."""
    dedans = [c for c in cartes if c['personnage'] == 'conjoint']
    if not dedans:
        sys.exit('aucune carte du conjoint : le mariage ne mène nulle part')
    return dedans


def lis():
    cartes = json.load(open(os.path.join(RACINE, 'assets/contenu/cartes.json')))
    gens = {p['id']: p for p in
            json.load(open(os.path.join(RACINE, 'assets/contenu/personnages.json')))}
    parId = {c['id']: c for c in cartes}
    tout = []
    for qui, chaine in CHAINES.items():
        rangs = {}
        for c in cartes:
            ch = c.get('chaine') or {}
            if ch.get('id') == chaine:
                rangs[ch['rang']] = c
        manque = [r for r in range(1, 7) if r not in rangs]
        if manque:
            sys.exit(f'{chaine} : rangs absents {manque}')
        rdv = parId.get(f'rdv_{qui}')
        if rdv is None:
            sys.exit(f'{qui} : pas de carte de rendez-vous')
        tout.append({'id': qui, 'personne': gens[qui], 'rangs': rangs, 'rdv': rdv})
    return tout


def chip(reponse, sens):
    m = mouvement(reponse)
    classe = 'chip' + (' chip-monte' if m and m.startswith('+') else '')
    if m in ('mariage', 'rupture'):
        classe = f'chip chip-{m}'
    marque = f'<span class="mouv">{m}</span>' if m else ''
    fleche = '←' if sens == 'g' else '→'
    return (f'<span class="{classe}"><span class="fleche">{fleche}</span>'
            f'{echappe(reponse["libelle"])}{marque}</span>')


def barreau(c, liaison):
    ch = c['chaine']
    cond = c.get('conditions', {})
    rang = ch['rang']
    exige = cond.get('attache_min')
    plafond = cond.get('attache_max')
    if exige is None and plafond == 0:
        porte = 'tant que rien n\'a commencé'
    elif exige is not None and exige == plafond:
        porte = f'au cran {exige} — {CRANS[exige]}'
    elif exige is not None:
        porte = f'à partir du cran {exige} — {CRANS[exige]}'
    else:
        porte = ''
    delai = ch.get('delai_min')
    attente = f' · pas avant {delai} jours' if delai else ''
    return f'''      <li class="barreau">
        <div class="rang">{rang}</div>
        <div class="dit">
          <p class="replique">{echappe(habille(c['texte']))}</p>
          <p class="porte">{echappe(porte)}{echappe(attente)}</p>
          <div class="choix">{chip(c['gauche'], 'g')}{chip(c['droite'], 'd')}</div>
        </div>
      </li>'''


def echelle(e, liaison):
    p = e['personne']
    homme = e['id'] in HOMMES
    attend = 'Il attend habillé.' if homme else 'Elle attend habillée.'
    pronom = 'il' if homme else 'elle'
    barreaux = ''.join(barreau(e['rangs'][r], liaison) for r in range(1, 7))
    rdv = e['rdv']
    return f'''  <section class="personne">
    <div class="tete">
      <img src="visages/{e['id']}.jpg" alt="{echappe(p['nom'])}">
      <div>
        <h2>{echappe(p['nom'])}</h2>
        <p class="titre">{echappe(p.get('titre', ''))}</p>
      </div>
    </div>
    <ol class="echelle">
{barreaux}
    </ol>
    <div class="apres">
      <div class="bloc">
        <p class="etiquette">Puis, tous les dix jours</p>
        <p class="replique">{echappe(habille(rdv['texte']))}</p>
        <div class="choix">{chip(rdv['gauche'], 'g')}{chip(rdv['droite'], 'd')}</div>
      </div>
      <div class="bloc">
        <p class="etiquette">Et la chambre, ce soir-là</p>
        <div class="pellicule">
          <img src="lit/{e['id']}.jpg" alt="Sur le lit">
        </div>
        <p class="porte">{attend} Un appui, {pronom} se déshabille.
        Un second, la scène passe sur le lit.</p>
      </div>
    </div>
  </section>'''


def carte_mariee(c):
    cond = c.get('conditions', {})
    porte = []
    if cond.get('jour_min'):
        porte.append(f"à partir du {cond['jour_min']}ᵉ jour")
    if cond.get('jour_max'):
        porte.append(f"avant le {cond['jour_max']}ᵉ jour")
    if cond.get('mandat_min', 1) > 1:
        porte.append(f"au mandat {cond['mandat_min']}")
    for d in cond.get('drapeaux_requis', []):
        porte.append('si « ' + d.replace('_', ' ') + ' »')
    ch = c.get('chaine')
    if ch:
        porte.append(f"suite {ch['rang']} de « {ch['id'].replace('_', ' ')} »")
    return f'''      <li class="barreau barreau-plat">
        <div class="dit">
          <p class="replique">{echappe(habille(c['texte']))}</p>
          <p class="porte">{echappe(' · '.join(porte))}</p>
          <div class="choix">{chip(c['gauche'], 'g')}{chip(c['droite'], 'd')}</div>
        </div>
      </li>'''


def acte_du_mariage(cartes):
    liste = ''.join(carte_mariee(c) for c in cartes)
    return f'''  <section class="personne mariage">
    <div class="tete">
      <div>
        <h2>Une fois marié</h2>
        <p class="titre">{len(cartes)} cartes, quelle que soit la personne épousée</p>
      </div>
    </div>
    <p class="note">Elles ne nomment personne : c'est la personne que le
    président a épousée qui les dit. Elles n'existent pas pour un célibataire,
    et elles ne s'arrêtent plus — le mariage n'est pas la fin de l'histoire,
    c'est la moitié qu'on joue ensuite.</p>
    <ol class="echelle">
{liste}
    </ol>
  </section>'''


GABARIT = '''<title>Comment une romance se joue</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,700;12..96,800&family=Public+Sans:wght@0,400;0,600&display=swap">
<style>
  :root{
    --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
    --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38; --chair:#C97B6A;
    --serif:"Bricolage Grotesque","Trebuchet MS",sans-serif;
    --corps:"Public Sans",system-ui,-apple-system,sans-serif;
  }
  :root[data-theme="light"]{
    --fond:#F3ECE0; --leve:#FFFBF4; --encre:#1B1922; --douce:#544E5F;
    --faible:#8C8595; --or:#A0700F; --trait:#D9CDB8; --chair:#A4503C;
  }
  @media (prefers-color-scheme: dark){
    :root:not([data-theme="light"]){
      --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
      --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38; --chair:#C97B6A;
    }
  }
  :root[data-theme="dark"]{
    --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
    --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38; --chair:#C97B6A;
  }
  body{background:var(--fond);color:var(--encre);font-family:var(--corps);
    font-size:16px;line-height:1.5}
  .page{max-width:940px;margin:0 auto;padding:0 20px;padding-block:40px 72px}
  h1,h2{font-family:var(--serif);margin:0;text-wrap:balance}
  h1{font-size:clamp(1.9rem,5.5vw,2.9rem);font-weight:800;line-height:1.02;letter-spacing:-.015em}
  p{margin:0 0 .8em;max-width:64ch}
  .surtitre{font-size:.72rem;letter-spacing:.18em;text-transform:uppercase;
    color:var(--faible);font-weight:600;margin:0 0 12px}
  .chapeau{font-size:1.08rem;color:var(--douce);max-width:58ch;margin-top:14px}
  .note{font-size:.84rem;color:var(--faible);max-width:70ch}

  .echelon{display:flex;flex-wrap:wrap;gap:8px;margin:26px 0 0;padding:16px 0;
    border-top:1px solid var(--trait);border-bottom:1px solid var(--trait)}
  .echelon span{font-size:.74rem;letter-spacing:.06em;color:var(--douce);
    background:var(--leve);border:1px solid var(--trait);border-radius:3px;padding:5px 10px}
  .echelon b{font-family:var(--serif);color:var(--or);margin-right:6px}

  .personne{border-top:1px solid var(--trait);margin-top:46px;padding-top:26px}
  .tete{display:flex;align-items:center;gap:16px;margin-bottom:22px}
  .tete img{width:60px;height:60px;border-radius:50%;object-fit:cover;
    border:1px solid var(--trait);flex:none}
  .tete h2{font-size:1.4rem;font-weight:700;line-height:1.1}
  .titre{font-size:.82rem;color:var(--faible);margin:2px 0 0}

  .echelle{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:2px}
  .barreau{display:grid;grid-template-columns:38px 1fr;gap:16px;align-items:start;
    padding:14px 0;border-top:1px solid var(--trait)}
  .barreau:first-child{border-top:none}
  .barreau-plat{grid-template-columns:1fr}
  .mariage .tete{gap:0}
  .acte{font-size:.68rem;letter-spacing:.16em;text-transform:uppercase;
    color:var(--or);font-weight:600;margin:18px 0 4px;padding-top:14px;
    border-top:1px solid var(--trait)}
  .acte:first-child{margin-top:0;padding-top:0;border-top:none}
  .rang{font-family:var(--serif);font-weight:800;font-size:1.05rem;color:var(--or);
    text-align:center;line-height:1.4;border-right:1px solid var(--trait);padding-right:10px}
  .replique{font-size:1rem;color:var(--encre);margin:0 0 6px;max-width:58ch}
  .porte{font-size:.76rem;letter-spacing:.04em;color:var(--faible);margin:0 0 10px}
  .choix{display:flex;flex-wrap:wrap;gap:8px}
  .chip{font-size:.8rem;color:var(--douce);background:var(--leve);
    border:1px solid var(--trait);border-radius:3px;padding:5px 10px;
    display:inline-flex;align-items:center;gap:7px}
  .fleche{color:var(--faible);font-size:.76rem}
  .mouv{font-family:var(--serif);font-weight:700;font-size:.74rem;color:var(--or)}
  .chip-monte{border-color:rgba(233,180,76,.38)}
  .chip-mariage{border-color:var(--chair)}
  .chip-mariage .mouv,.chip-rupture .mouv{color:var(--chair)}
  .chip-rupture{border-color:var(--trait)}

  .apres{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));
    gap:16px;margin-top:22px}
  .bloc{background:var(--leve);border:1px solid var(--trait);border-radius:4px;padding:14px 16px}
  .etiquette{font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;
    color:var(--or);font-weight:600;margin:0 0 8px}
  .pellicule{width:100%;aspect-ratio:3/4;max-height:260px;overflow:hidden;
    border-radius:3px;margin-bottom:10px}
  .pellicule img{width:100%;height:100%;object-fit:cover;display:block}

  footer{border-top:1px solid var(--trait);margin-top:52px;padding-top:20px}
  @media (max-width:520px){
    .barreau{grid-template-columns:28px 1fr;gap:12px}
    .rang{padding-right:6px}
  }
</style>
<div class="page">
  <p class="surtitre">Palabre — Président pour 100 jours · version {{VERSION}}</p>
  <h1>Comment une romance se joue</h1>
  <p class="chapeau">Toutes les cartes d'une romance, dans l'ordre où elles
  sortent : les trois qui mènent à la liaison, les trois qui vont de la liaison
  à la demande, le rendez-vous qui se rejoue ensuite tous les dix jours, et les
  {{MARIAGE}} qui n'existent qu'une fois marié.</p>
  <p class="note">L'attache ne monte jamais toute seule. Aucune jauge, aucun jour
  qui passe ne la déplace : seule une réponse qui la déclare la fait bouger, et
  une carte ne sort que si l'attache est exactement au cran qu'elle attend. On
  ne saute donc pas d'étape, et on peut s'arrêter à n'importe laquelle. Le cran
  3, la liaison, est la charnière : c'est lui qui ouvre le rendez-vous et la
  chambre partagée.</p>

  <div class="echelon">{{ECHELON}}</div>

{{CORPS}}

  <footer><p class="note">{{PIED}}</p></footer>
</div>
'''


def version():
    for ligne in open(os.path.join(RACINE, 'pubspec.yaml')):
        if ligne.startswith('version:'):
            return ligne.split(':', 1)[1].strip().split('+')[0]
    return '?'


def main():
    sortie = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RACINE, 'sources/romances/romances.html')
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    liaison = cran_liaison()
    tout = lis()
    echelon = ''.join(
        f'<span><b>{i}</b>{echappe(nom)}</span>' for i, nom in enumerate(CRANS))
    cartes = json.load(open(os.path.join(RACINE, 'assets/contenu/cartes.json')))
    mariage = apres_le_mariage(cartes)
    corps = '\n'.join(echelle(e, liaison) for e in tout)
    corps += '\n' + acte_du_mariage(mariage)
    pied = (f'{len(tout) * 7 + len(mariage)} cartes en tout, lues dans le contenu '
            'du jeu : ce qui est écrit ici est ce qui se joue. Les jours ordinaires, '
            'la chambre montre seulement que l\'on n\'y dort plus seul — le '
            'déshabillage appartient au soir promis.')
    page = (GABARIT
            .replace('{{VERSION}}', version())
            .replace('{{ECHELON}}', echelon)
            .replace('{{MARIAGE}}', f'{len(mariage)} cartes')
            .replace('{{PIED}}', echappe(pied))
            .replace('{{CORPS}}', corps))
    open(sortie, 'w').write(page)
    print(f'{sortie} — {len(tout)} romances, {len(tout) * 7} cartes')


if __name__ == '__main__':
    main()
