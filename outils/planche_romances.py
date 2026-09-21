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
CRANS = ['rien', 'un regard', 'un geste', 'une liaison', 'au grand jour', 'mariés']

# Ce que chaque drapeau de noces montre.
NOCES = {
    'noces_etat': "Dans la cour d'honneur — deux cents invités, la garde en "
                  'grande tenue, la ville arrêtée trois heures.',
    'noces_discretes': 'À la salle des mariages — dix minutes, quatre témoins, '
                       'aucune photographie officielle.',
}

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
                rangs.setdefault(ch['rang'], []).append(c)
        manque = [r for r in range(1, max(rangs) + 1) if r not in rangs]
        if manque:
            sys.exit(f'{chaine} : rangs absents {manque}')
        rdv = parId.get(f'rdv_{qui}')
        if rdv is None:
            sys.exit(f'{qui} : pas de carte de rendez-vous')
        tout.append({'id': qui, 'personne': gens[qui], 'rangs': rangs, 'rdv': rdv,
                     'cartes': [c for r in sorted(rangs) for c in rangs[r]]})
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


def vraie_carte(c, qui, coiffe, president_femme, n=None):
    """La carte comme l'ecran la dessine : le portrait plein cadre, le titre
    en or, et ce que la personne dit. Les deux libelles n'apparaissent en
    jeu que pendant le geste — ici ils sont dessous, avec leur prix."""
    return f'''      <figure class="carte">
        <div class="vignette">
          <img src="portraits/{qui}_{c['humeur']}.jpg" alt="">
          {'<span class="numero">' + str(n) + '</span>' if n else ''}
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


def _bloc_des_noces_inutilise(e):
    """Les deux cérémonies, quand une carte de la chaîne les propose."""
    lieux = set()
    for c in e['rangs'].values():
        for r in (c['gauche'], c['droite']):
            lieux.update(d for d in r.get('drapeaux', []) if d.startswith('noces_')
                         and d != f"noces_{e['id']}")
    if not lieux:
        return ''
    vues = ''.join(
        f'<figure class="noce"><img src="noces/{e["id"]}_{d.split("_", 1)[1]}.jpg" alt="">'
        f'<figcaption>{echappe(NOCES[d])}</figcaption></figure>'
        for d in sorted(lieux))
    return f'''    <div class="bloc">
      <p class="etiquette">Le jour des noces</p>
      <div class="noces">{vues}</div>
      <p class="porte">La cérémonie se joue une fois, en plein écran, après la
      réponse — comme une fin, mais au milieu du mandat. C'est le seul moment
      du jeu qu'on ne peut pas revoir.</p>
    </div>'''


def issue(c):
    """Le drapeau qui conditionne une carte d'issue : noces ou rupture."""
    for d in c.get('conditions', {}).get('drapeaux_requis', []):
        if d.startswith('noces_'):
            return 'noces'
        if d.startswith('rompu_'):
            return 'rupture'
    return None


# Les passes de relecture. On valide une colonne du tableau à la fois,
# sur les dix personnes : les numéros sont posés avant le filtre, donc
# la carte 17 reste la carte 17, qu'on lise la planche entière ou une
# seule passe.
ACTES = {
    'avant': "Jusqu'à la liaison",
    'liaison': 'La liaison — le rendez-vous, et la chambre',
    'apres': 'De la liaison à la demande',
    'noces': "Si l'on dit oui — le jour des noces",
    'rupture': "Si l'on dit non — ce qu'il en reste",
    'marie': 'Une fois marié',
}


def echelle(e, liaison, suivant, actes):
    p = e['personne']
    homme = e['id'] in HOMMES
    coiffe = {'titre': p.get('titre', '')}

    # Avant la liaison, après la liaison, puis les deux issues. Le
    # rendez-vous et la chambre se placent à la charnière, pas à la fin :
    # on ne dort pas ensemble le soir des noces.
    avant, apres, noces, rupture = [], [], [], []
    for c in e['cartes']:
        cond = c.get('conditions', {})
        porte = cond.get('attache_min', cond.get('attache_max', 0))
        quelle = issue(c)
        if quelle == 'noces':
            noces.append(c)
        elif quelle == 'rupture':
            rupture.append(c)
        elif porte < liaison:
            avant.append(c)
        else:
            apres.append(c)

    def dessine(c):
        rang = c['chaine']['rang']
        return vraie_carte(c, e['id'], {**coiffe,
            'porte': f'{rang} · ' + coiffe_du_rang(c, liaison)}, homme, suivant())

    # Numéroter d'abord, filtrer ensuite : c'est ce qui rend les passes
    # comparables entre elles, et ce qui permet de dire « 17 à refaire ».
    vu = {'avant': [dessine(c) for c in avant]}
    vu['liaison'] = [vraie_carte(e['rdv'], e['id'], {**coiffe,
        'porte': f'le rendez-vous · attache au cran {liaison} ou plus · '
                 'se rejoue tous les 10 jours'}, homme, suivant())]
    vu['apres'] = [dessine(c) for c in apres]
    vu['noces'] = [dessine(c) for c in noces]
    vu['rupture'] = [dessine(c) for c in rupture]

    montre = sum(len(vu[a]) for a in actes if a in vu)
    if not montre:
        return ''

    vues = ''.join(
        f'<figure class="noce"><img src="noces/{e["id"]}_{v}.jpg" alt=""> '
        f'<figcaption>{echappe(NOCES["noces_" + v])}</figcaption></figure>'
        for v in ('etat', 'discretes'))

    blocs = []
    if 'avant' in actes:
        blocs.append('    <p class="acte">' + ACTES['avant'] + '</p>\n'
                     '    <div class="galerie">\n' + ''.join(vu['avant']) + '\n    </div>')
    if 'liaison' in actes:
        blocs.append(
            "    <p class=\"acte\">La liaison — à partir d'ici, et tant qu'elle dure</p>\n"
            '    <div class="galerie">\n' + vu['liaison'][0] + '\n    </div>\n'
            '    <div class="bloc">\n'
            '      <p class="etiquette">Et la chambre, ce soir-là</p>\n'
            '      <div class="issue">\n'
            f'        <img src="lit/{e["id"]}.jpg" alt="Sur le lit">\n'
            '        <p class="porte">'
            + ('Il attend habillé.' if homme else 'Elle attend habillée.')
            + ' Un appui, ' + ('il' if homme else 'elle') + " se déshabille. Un second,\n"
            '        la scène passe sur le lit. Les jours ordinaires, la chambre dit\n'
            "        seulement qu'on n'y dort plus seul.</p>\n"
            '      </div>\n'
            '    </div>')
    if 'apres' in actes:
        blocs.append('    <p class="acte">' + ACTES['apres'] + '</p>\n'
                     '    <div class="galerie">\n' + ''.join(vu['apres']) + '\n    </div>')
    if 'noces' in actes:
        blocs.append(
            '    <p class="acte">' + ACTES['noces'] + '</p>\n'
            '    <div class="galerie">\n' + ''.join(vu['noces']) + '\n    </div>\n'
            '    <div class="bloc">\n'
            '      <p class="etiquette">La cérémonie, une seule fois</p>\n'
            f'      <div class="noces">{vues}</div>\n'
            '      <p class="porte">Elle se joue en plein écran après la réponse, puis\n'
            "      ne revient jamais — c'est le seul moment du jeu qu'on ne peut pas\n"
            '      revoir.</p>\n'
            '    </div>')
    if 'rupture' in actes:
        blocs.append(
            '    <p class="acte">' + ACTES['rupture'] + '</p>\n'
            '    <div class="galerie">\n' + ''.join(vu['rupture']) + '\n    </div>\n'
            "    <p class=\"note\">L'attache retombe à zéro et cette histoire-là s'arrête\n"
            "    pour de bon. Une autre peut commencer avec quelqu'un d'autre : rien ne\n"
            "    l'empêche, et le jeu ne compte pas les cœurs.</p>")

    compte = (f'{montre} cartes ici' if len(actes) < len(ACTES)
              else f"{len(e['cartes']) + 1} cartes")
    seulement = 'une présidente' if homme else 'un président'
    return ('  <section class="personne">\n'
            '    <div class="tete">\n'
            f'      <img src="visages/{e["id"]}.jpg" alt="{echappe(p["nom"])}">\n'
            '      <div>\n'
            f'        <h2>{echappe(p["nom"])}</h2>\n'
            f'        <p class="titre">{compte} · {seulement} seulement</p>\n'
            '      </div>\n'
            '    </div>\n'
            + '\n'.join(blocs) + '\n'
            '  </section>')


def carte_mariee(c, n=None):
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
    }, True, n)


def acte_du_mariage(cartes, suivant):
    liste = ''.join(carte_mariee(c, suivant()) for c in cartes)
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


GABARIT = '''<title>{{TITRE}}</title>
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
  .numero{position:absolute;top:10px;left:10px;z-index:2;font-family:var(--serif);
    font-size:.78rem;font-weight:700;color:var(--nuit);background:var(--or);
    border-radius:3px;padding:2px 7px;letter-spacing:.02em}
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
  .noces{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px;margin-bottom:12px}
  .noce{margin:0}
  .noce img{width:100%;aspect-ratio:3/2;object-fit:cover;border-radius:3px;display:block}
  .noce figcaption{font-size:.76rem;color:var(--douce);margin-top:7px}
  .acte{font-size:.7rem;letter-spacing:.16em;text-transform:uppercase;color:var(--or);
    font-weight:600;margin:30px 0 14px;padding-top:16px;border-top:1px solid var(--trait)}
  .personne > .acte:first-of-type{margin-top:0;padding-top:0;border-top:none}

  footer{border-top:1px solid var(--trait);margin-top:52px;padding-top:20px}
  @media (max-width:520px){
    .galerie{grid-template-columns:1fr}
    .issue{flex-direction:column}
  }
</style>
<div class="page">
  <p class="surtitre">Palabre — Président pour 100 jours · version {{VERSION}}</p>
  <h1>{{TITRE}}</h1>
  <p class="chapeau">{{CHAPEAU}}</p>
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
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    seul = next((a.split('=', 1)[1] for a in sys.argv[1:] if a.startswith('--seul=')), None)
    acte = next((a.split('=', 1)[1] for a in sys.argv[1:] if a.startswith('--acte=')), None)
    if acte and acte not in ACTES:
        sys.exit('actes connus : ' + ', '.join(ACTES))
    actes = [acte] if acte else list(ACTES)
    sortie = args[0] if args else os.path.join(RACINE, 'sources/romances/romances.html')
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    liaison = cran_liaison()
    tout = lis()
    titre = 'Comment une romance se joue'
    chapeau = ("Toutes les cartes d'une romance, dans l'ordre où elles sortent : "
               'celles qui mènent à la liaison, celles qui vont de la liaison à '
               'la demande, le jour des noces, le rendez-vous qui se rejoue '
               'ensuite tous les dix jours, et les {{MARIAGE}} qui n\'existent '
               "qu'une fois marié.")
    if seul:
        tout = [e for e in tout if e['id'] == seul]
        if not tout:
            sys.exit(f'{seul} : personne de ce nom')
        titre = 'Une romance entière'
        chapeau = ('Une romance entière, de la première carte aux deux façons '
                   "dont elle peut finir — le mariage, ou le refus. Les cartes "
                   'sont dessinées comme le jeu les dessine.')
    if acte:
        titre = ACTES[acte]
        chapeau = ('Une passe de relecture : le même moment de la romance, chez '
                   'les dix personnes, pour les juger ensemble. Les numéros ne '
                   'changent pas d\'une passe à l\'autre — « 17 » désigne la même '
                   'carte ici et sur la planche entière.')
    echelon = ''.join(
        f'<span><b>{i}</b>{echappe(nom)}</span>' for i, nom in enumerate(CRANS))
    cartes = json.load(open(os.path.join(RACINE, 'assets/contenu/cartes.json')))
    mariage = apres_le_mariage(cartes)

    # Un seul compteur pour toute la page, posé dans l'ordre de lecture.
    compteur = [0]

    def suivant():
        compteur[0] += 1
        return compteur[0]

    corps = '\n'.join(x for x in (echelle(e, liaison, suivant, actes) for e in tout) if x)
    if not seul:
        bloc = acte_du_mariage(mariage, suivant)
        corps += ('\n' + bloc) if 'marie' in actes else ''
    # Le compteur court sur toute la romance pour garder les numéros
    # stables ; le pied, lui, annonce ce que la page montre vraiment.
    total = corps.count('<figure class="carte">')
    pied = (f'{total} cartes, lues dans le contenu '
            'du jeu : ce qui est écrit ici est ce qui se joue. Les jours ordinaires, '
            'la chambre montre seulement que l\'on n\'y dort plus seul — le '
            'déshabillage appartient au soir promis.')
    page = (GABARIT
            .replace('{{VERSION}}', version())
            .replace('{{ECHELON}}', echelon)
            .replace('{{TITRE}}', titre)
            .replace('{{CHAPEAU}}', chapeau)
            .replace('{{MARIAGE}}', f'{len(mariage)} cartes')
            .replace('{{PIED}}', echappe(pied))
            .replace('{{CORPS}}', corps))
    open(sortie, 'w').write(page)
    print(f'{sortie} — {len(tout)} romance(s), {total} cartes')


if __name__ == '__main__':
    main()
