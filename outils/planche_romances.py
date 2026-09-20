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


def habille(texte, president_femme):
    """Le texte tel que le joueur le lit, titre et nom posés.

    Une romance ne s'ouvre qu'aux parcours du sexe opposé : c'est donc un
    président que la rédactrice courtise, et une présidente que le maire
    courtise. Poser le mauvais titre ici ferait lire toute la page de
    travers.
    """
    titre = 'Madame la Présidente' if president_femme else 'Monsieur le Président'
    nom = 'Awa' if president_femme else 'Idriss'
    return texte.replace('{titre}', titre).replace('{nom}', nom)


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


JAUGES = {'peuple': 'peuple', 'armee': 'armée', 'caisses': 'caisses', 'presse': 'presse'}


def effets(reponse):
    """Ce que la réponse coûte, dans l'ordre où le jeu les écrit."""
    out = []
    for nom, v in reponse.get('effets', {}).items():
        signe = 'plus' if v > 0 else 'moins'
        out.append(f'<span class="jauge {signe}">{JAUGES.get(nom, nom)}'
                   f'<b>{v:+d}</b></span>')
    r = reponse.get('romance', {})
    if r.get('epouse'):
        out.append('<span class="jauge romance">mariage</span>')
    elif r.get('rupture'):
        out.append('<span class="jauge romance">rupture</span>')
    elif r.get('mouvement'):
        out.append(f'<span class="jauge romance">attache<b>{r["mouvement"]:+d}</b></span>')
    for d in reponse.get('drapeaux', []):
        out.append(f'<span class="jauge drapeau">{echappe(d.replace("_", " "))}</span>')
    return ''.join(out)


def vraie_carte(c, qui, coiffe, president_femme):
    """La carte comme l'ecran la dessine : le portrait plein cadre, le titre
    en or, et ce que la personne dit. Les deux libelles n'apparaissent en
    jeu que pendant le geste — ici ils sont dessous, avec leur prix."""
    return f'''      <figure class="carte">
        <div class="vignette">
          <img src="portraits/{qui}_{c['humeur']}.jpg" alt="">
          <div class="bandeau">
            <p class="qualite">{echappe(coiffe['titre'].upper())}</p>
            <p class="dit">{echappe(habille(c['texte'], president_femme))}</p>
          </div>
        </div>
        <figcaption>
          <p class="porte">{echappe(coiffe['porte'])}</p>
          <div class="deux">
            <div class="geste"><span class="sens">← {echappe(c['gauche']['libelle'])}</span>
              <div class="prix">{effets(c['gauche'])}</div></div>
            <div class="geste"><span class="sens">{echappe(c['droite']['libelle'])} →</span>
              <div class="prix">{effets(c['droite'])}</div></div>
          </div>
        </figcaption>
      </figure>'''


def chip(reponse, sens):
    m = mouvement(reponse)
    classe = 'chip' + (' chip-monte' if m and m.startswith('+') else '')
    if m in ('mariage', 'rupture'):
        classe = f'chip chip-{m}'
    marque = f'<span class="mouv">{m}</span>' if m else ''
    fleche = '←' if sens == 'g' else '→'
    return (f'<span class="{classe}"><span class="fleche">{fleche}</span>'
            f'{echappe(reponse["libelle"])}{marque}</span>')


def coiffe_du_rang(c, liaison):
    """Ce qui ouvre la carte, en clair : le cran exige et le delai."""
    ch = c['chaine']
    cond = c.get('conditions', {})
    exige, plafond = cond.get('attache_min'), cond.get('attache_max')
    if exige is None and plafond == 0:
        porte = "tant que rien n'a commencé"
    elif exige is not None and exige == plafond:
        porte = f'attache au cran {exige} — {CRANS[exige]}'
    elif exige is not None:
        porte = f'attache au cran {exige} ou plus — {CRANS[exige]}'
    else:
        porte = ''
    if cond.get('marie') is False:
        porte += ', et célibataire'
    delai = ch.get('delai_min')
    if delai:
        porte += f' · pas avant {delai} jours'
    return porte


def echelle(e, liaison):
    p = e['personne']
    homme = e['id'] in HOMMES
    courtise_une_presidente = homme
    cartes = []
    for r in range(1, 7):
        c = e['rangs'][r]
        cartes.append(vraie_carte(c, e['id'], {
            'titre': p.get('titre', ''),
            'porte': f'{r} · ' + coiffe_du_rang(c, liaison),
        }, courtise_une_presidente))
    rdv = e['rdv']
    cartes.append(vraie_carte(rdv, e['id'], {
        'titre': p.get('titre', ''),
        'porte': 'le rendez-vous · attache au cran '
                 f'{liaison} ou plus · se rejoue tous les 10 jours',
    }, courtise_une_presidente))
    return f'''  <section class="personne">
    <div class="tete">
      <img src="visages/{e['id']}.jpg" alt="{echappe(p['nom'])}">
      <div>
        <h2>{echappe(p['nom'])}</h2>
        <p class="titre">sept cartes · {'une présidente' if homme else 'un président'} seulement</p>
      </div>
    </div>
    <div class="galerie">
{''.join(cartes)}
    </div>
    <div class="bloc">
      <p class="etiquette">Et la chambre, ce soir-là</p>
      <div class="issue">
        <img src="lit/{e['id']}.jpg" alt="Sur le lit">
        <p class="porte">{'Il attend habillé.' if homme else 'Elle attend habillée.'}
        Un appui, {'il' if homme else 'elle'} se déshabille. Un second, la scène
        passe sur le lit. Les jours ordinaires, la chambre dit seulement
        qu'on n'y dort plus seul.</p>
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
    return vraie_carte(c, 'conjoint', {
        'titre': 'la personne que vous avez épousée',
        'porte': ' · '.join(porte) or 'une fois marié',
    }, True)


def acte_du_mariage(cartes):
    liste = ''.join(carte_mariee(c) for c in cartes)
    return f'''  <section class="personne">
    <div class="tete">
      <div>
        <h2>Une fois marié</h2>
        <p class="titre">{len(cartes)} cartes, quelle que soit la personne épousée</p>
      </div>
    </div>
    <p class="note">Elles ne nomment personne : c'est la personne que le
    président a épousée qui les dit, et c'est son visage qui apparaît. Elles
    n'existent pas pour un célibataire, et elles ne s'arrêtent plus — le
    mariage n'est pas la fin de l'histoire, c'est la moitié qu'on joue
    ensuite.</p>
    <div class="galerie">
{liste}
    </div>
  </section>'''


GABARIT = '''<title>Comment une romance se joue</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,700;12..96,800&family=Public+Sans:wght@0,400;0,600&display=swap">
<style>
  :root{
    --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
    --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38; --chair:#C97B6A;
    --nuit:#14131A;
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

  /* La carte, telle que partie_ecran.dart la dessine : le portrait plein
     cadre, un degrade vers l encre, le titre en or et ce qui se dit. */
  .galerie{display:grid;grid-template-columns:repeat(auto-fill,minmax(258px,1fr));gap:22px}
  .carte{margin:0}
  .vignette{position:relative;aspect-ratio:3/4;border-radius:24px;overflow:hidden;
    background:var(--nuit);box-shadow:0 18px 40px rgba(0,0,0,.45)}
  .vignette img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;
    object-position:50% 32%}
  .bandeau{position:absolute;left:0;right:0;bottom:0;padding:88px 16px 18px;
    background:linear-gradient(to bottom,rgba(8,7,9,0) 0%,rgba(8,7,9,.95) 55%)}
  .qualite{font-size:.62rem;font-weight:800;letter-spacing:.16em;color:var(--or);
    margin:0 0 7px;text-transform:uppercase}
  .dit{font-size:.9rem;line-height:1.38;color:#F6EFE4;margin:0}
  figcaption{padding:12px 2px 0}
  .porte{font-size:.72rem;letter-spacing:.04em;color:var(--faible);margin:0 0 9px}
  .deux{display:grid;grid-template-columns:1fr 1fr;gap:10px}
  .geste{min-width:0}
  .sens{display:block;font-size:.78rem;font-weight:600;color:var(--douce);
    margin-bottom:5px}
  .geste:last-child .sens{text-align:right}
  .prix{display:flex;flex-wrap:wrap;gap:4px}
  .geste:last-child .prix{justify-content:flex-end}
  .jauge{font-size:.66rem;letter-spacing:.02em;color:var(--faible);
    border:1px solid var(--trait);border-radius:2px;padding:2px 5px;white-space:nowrap}
  .jauge b{font-family:var(--serif);margin-left:4px}
  .jauge.plus b{color:var(--or)}
  .jauge.moins b{color:var(--chair)}
  .jauge.romance{border-color:var(--chair);color:var(--chair)}
  .jauge.romance b{color:var(--chair)}
  .jauge.drapeau{font-style:italic}

  .bloc{background:var(--leve);border:1px solid var(--trait);border-radius:4px;
    padding:14px 16px;margin-top:24px}
  .etiquette{font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;
    color:var(--or);font-weight:600;margin:0 0 10px}
  .issue{display:flex;gap:16px;align-items:flex-start}
  .issue img{width:120px;aspect-ratio:3/4;object-fit:cover;border-radius:3px;flex:none}
  .issue .porte{margin:0;max-width:52ch}

  footer{border-top:1px solid var(--trait);margin-top:52px;padding-top:20px}
  @media (max-width:520px){
    .galerie{grid-template-columns:1fr}
    .issue{flex-direction:column}
  }
</style>
<div class="page">
  <p class="surtitre">Palabre — Président pour 100 jours · version {{VERSION}}</p>
  <h1>Comment une romance se joue</h1>
  <p class="chapeau">Toutes les cartes d'une romance, dans l'ordre où elles
  sortent : les trois qui mènent à la liaison, les trois qui vont de la liaison
  à la demande, le rendez-vous qui se rejoue ensuite tous les dix jours, et les
  {{MARIAGE}} qui n'existent qu'une fois marié.</p>
  <p class="note">Une romance ne s'ouvre qu'aux parcours du sexe opposé : les
  cinq femmes ne se laissent courtiser que par un président, les cinq hommes
  que par une présidente. Chaque partie a donc cinq personnes à courtiser, pas
  dix, et le titre change avec le parcours choisi.</p>
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
