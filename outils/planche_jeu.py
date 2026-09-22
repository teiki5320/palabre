#!/usr/bin/env python3
"""Écrit « Le jeu entier » : tout le contenu de Palabre, en pages liées.

    python3 outils/planche_jeu.py [dossier de sortie]

Sept pages sous un seul dossier, prêtes à publier telles quelles. Rien
n'est écrit à la main ici : les cartes viennent de `cartes.json`, les
décors de `decor.dart`, les états du palais de `planche_etats.json`. Une
carte réécrite change la planche au tour suivant.

Pourquoi une planche plutôt qu'une partie : 89 drapeaux conditionnent la
sortie d'une carte, et la plupart ne se croisent qu'une fois sur des
centaines de mandats. On ne relit pas ce contenu en jouant — on le relit
à plat.
"""

import json
import os
import re
import shutil
import subprocess
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENU = os.path.join(RACINE, 'assets/contenu')
IMAGES = os.path.join(RACINE, 'assets/images')
PLAQUES = os.path.join(IMAGES, 'palais')

LARGEUR_PORTRAIT = 520
LARGEUR_PLAQUE = 620   # une image de bande : dix d'affilée font 6 200 px
LARGEUR_LARGE = 760

# Le conjoint n'a pas de portrait à lui : en jeu, c'est le visage de la
# personne épousée qui parle. La planche en montre un, et le dit.
REMPLACE_CONJOINT = 'epouse'

JAUGES = {'peuple': 'peuple', 'armee': 'armée', 'caisses': 'caisses',
          'presse': 'presse'}


# ─────────────────────────────── lecture ───────────────────────────────

def charge(nom):
    return json.load(open(os.path.join(CONTENU, nom + '.json')))


def version():
    for ligne in open(os.path.join(RACINE, 'pubspec.yaml')):
        if ligne.startswith('version:'):
            return ligne.split(':', 1)[1].strip().split('+')[0]
    return '?'


def echappe(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;')
            .replace('>', '&gt;').replace('"', '&quot;'))


def habille(texte):
    """Le titre et le nom dépendent du parcours choisi ; la planche en pose
    un, et l'annonce en tête de page."""
    return texte.replace('{titre}', 'Monsieur le Président').replace('{nom}', 'Idriss')


# ────────────────────────────── conditions ─────────────────────────────

BORNES = [
    ('peuple', 'le peuple'), ('armee', "l'armée"), ('caisses', 'les caisses'),
    ('presse', 'la presse'), ('style', 'le régime'), ('loyaute', 'la loyauté'),
    ('force', "la force de l'adversaire"), ('attache', "l'attache"),
]
CRANS = ['rien', 'un regard', 'un geste', 'une liaison', 'au grand jour', 'mariés']


def dit_les_conditions(cond, gens, parcours):
    """Ce qui doit être vrai pour que la carte puisse sortir, en clair."""
    if not cond:
        return []
    out = []
    for cle, nom in BORNES:
        bas, haut = cond.get(cle + '_min'), cond.get(cle + '_max')
        if cle == 'attache':
            def cran(v):
                return f'{v} — {CRANS[v]}' if 0 <= v < len(CRANS) else str(v)
            if bas is not None and bas == haut:
                out.append(f'attache au cran {cran(bas)}')
            elif bas is not None and haut is not None:
                out.append(f'attache entre {cran(bas)} et {cran(haut)}')
            elif bas is not None:
                out.append(f'attache au cran {cran(bas)} ou plus')
            elif haut is not None:
                out.append(f'attache au cran {cran(haut)} ou moins')
            continue
        if bas is not None and haut is not None:
            out.append(f'{nom} entre {bas} et {haut}')
        elif bas is not None:
            out.append(f'{nom} à {bas} ou plus')
        elif haut is not None:
            out.append(f'{nom} à {haut} ou moins')
    if cond.get('attache_de'):
        out.append("l'attache visée est celle de "
                   + nom_de(cond['attache_de'], gens))
    if cond.get('loyaute_de'):
        out.append('la loyauté visée est celle de '
                   + nom_de(cond['loyaute_de'], gens))
    if cond.get('jour_min') and cond.get('jour_max'):
        out.append(f"du {cond['jour_min']}ᵉ au {cond['jour_max']}ᵉ jour")
    elif cond.get('jour_min'):
        out.append(f"à partir du {cond['jour_min']}ᵉ jour")
    elif cond.get('jour_max'):
        out.append(f"avant le {cond['jour_max']}ᵉ jour")
    if cond.get('mandat_min', 1) > 1:
        out.append(f"au mandat {cond['mandat_min']} ou plus")
    if cond.get('marie') is True:
        out.append('marié')
    elif cond.get('marie') is False:
        out.append('célibataire')
    if cond.get('parcours'):
        out.append('parcours : ' + ', '.join(
            parcours.get(p, {}).get('nom', p) for p in cond['parcours']))
    if cond.get('parcours_interdits'):
        out.append('sauf : ' + ', '.join(
            parcours.get(p, {}).get('nom', p) for p in cond['parcours_interdits']))
    if cond.get('adversaire'):
        out.append('adversaire : ' + ', '.join(cond['adversaire']))
    return out


def nom_de(qui, gens):
    return gens.get(qui, {}).get('nom', qui)


def puces_drapeaux(cond, lien):
    """Les drapeaux qui ouvrent ou ferment la carte, cliquables."""
    out = []
    for d in cond.get('drapeaux_requis', []):
        out.append(f'<a class="dr req" href="{lien(d)}">exige « {echappe(joli(d))} »</a>')
    for d in cond.get('drapeaux_interdits', []):
        out.append(f'<a class="dr int" href="{lien(d)}">interdit « {echappe(joli(d))} »</a>')
    return out


def joli(drapeau):
    return drapeau.replace('_', ' ')


# ──────────────────────────────── la carte ─────────────────────────────

def effets(reponse, lien):
    out = []
    for nom, v in reponse.get('effets', {}).items():
        signe = 'plus' if v > 0 else 'moins'
        out.append(f'<span class="jauge {signe}">{JAUGES.get(nom, nom)}<b>{v:+d}</b></span>')
    if reponse.get('style'):
        v = reponse['style']
        out.append(f'<span class="jauge {"plus" if v > 0 else "moins"}">régime<b>{v:+d}</b></span>')
    r = reponse.get('romance', {})
    if r.get('epouse'):
        out.append('<span class="jauge romance">mariage</span>')
    elif r.get('rupture'):
        out.append('<span class="jauge romance">rupture</span>')
    elif r.get('mouvement'):
        out.append(f'<span class="jauge romance">attache<b>{r["mouvement"]:+d}</b></span>')
    for d in reponse.get('drapeaux', []):
        out.append(f'<a class="jauge drapeau" href="{lien(d)}">pose « {echappe(joli(d))} »</a>')
    return ''.join(out)


def portrait(carte):
    qui = carte['personnage']
    if qui == 'conjoint':
        qui = REMPLACE_CONJOINT
    return f'gens/{qui}_{carte["humeur"]}.jpg'


def carte_html(c, n, coiffe, gens, lien):
    """La carte comme partie_ecran.dart la dessine : le portrait plein
    cadre, le titre en or, et ce qui se dit. Les deux libellés n'y
    paraissent que pendant le geste — ici ils sont dessous, avec leur prix."""
    qui = c['personnage']
    titre = ('la personne que vous avez épousée' if qui == 'conjoint'
             else gens.get(qui, {}).get('titre') or nom_de(qui, gens))
    marque = ('<span class="tenant">visage de remplacement</span>'
              if qui == 'conjoint' else '')
    return f'''      <figure class="carte" id="c{n}">
        <div class="vignette">
          <img src="{portrait(c)}" alt="" loading="lazy">
          <span class="numero">{n}</span>{marque}
          <div class="bandeau">
            <p class="qualite">{echappe(titre.upper())}</p>
            <p class="dit">{echappe(habille(c['texte']))}</p>
          </div>
        </div>
        <figcaption>
          <p class="porte">{coiffe}</p>
          <div class="deux">
            <div class="geste"><span class="sens">← {echappe(c['gauche']['libelle'])}</span>
              <div class="prix">{effets(c['gauche'], lien)}</div></div>
            <div class="geste"><span class="sens">{echappe(c['droite']['libelle'])} →</span>
              <div class="prix">{effets(c['droite'], lien)}</div></div>
          </div>
        </figcaption>
      </figure>'''


def coiffe_de(c, gens, parcours, lien, avec_rang=True):
    morceaux = []
    ch = c.get('chaine')
    if ch and avec_rang:
        morceaux.append(f'cran {ch["rang"]}')
        if ch.get('delai_min'):
            morceaux.append(f'pas avant {ch["delai_min"]} jours')
    morceaux += dit_les_conditions(c.get('conditions', {}), gens, parcours)
    if c.get('repetable'):
        morceaux.append('peut revenir')
    if c.get('attente'):
        morceaux.append(f'attend {c["attente"]} jours')
    if c.get('poids'):
        morceaux.append(f'poids {c["poids"]}')
    texte = ' · '.join(echappe(m) for m in morceaux) or 'sans condition'
    puces = puces_drapeaux(c.get('conditions', {}), lien)
    return texte + ('<span class="portes">' + ''.join(puces) + '</span>' if puces else '')


# ──────────────────────────────── images ───────────────────────────────

def reduis(src, dst, largeur):
    if os.path.exists(dst):
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', src,
                    '-vf', f'scale={largeur}:-2', '-q:v', '4', dst], check=True)


def bande(sources, dst, largeur):
    """Une seule image pour toute une boucle, les vues à la file.

    Un décor du balcon pèse six images, jouées en aller-retour : dix vues.
    Soixante-deux décors feraient plus de deux cents fichiers, et un
    artifact n'en accepte que deux cent cinquante-cinq. Mis bout à bout,
    chaque décor n'en fait qu'un, et la page l'anime en décalant l'image
    d'un cran — c'est le même mouvement qu'en jeu, en un fichier."""
    if os.path.exists(dst):
        return
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    args = ['ffmpeg', '-loglevel', 'error', '-y']
    for s in sources:
        args += ['-i', s]
    filtre = ''.join(f'[{i}:v]scale={largeur}:-2[v{i}];' for i in range(len(sources)))
    filtre += ''.join(f'[v{i}]' for i in range(len(sources)))
    filtre += f'hstack=inputs={len(sources)}[out]'
    args += ['-filter_complex', filtre, '-map', '[out]', '-q:v', '4', dst]
    subprocess.run(args, check=True)


def prepare_les_images(sortie, gens, parcours, fins, etats):
    """Tout ce que les pages affichent, réduit à la taille d'un écran."""
    for qui in list(gens) + [REMPLACE_CONJOINT]:
        for humeur in ('neutre', 'fache', 'content'):
            src = os.path.join(IMAGES, f'personnages/{qui}_{humeur}.jpg')
            if os.path.exists(src):
                reduis(src, os.path.join(sortie, f'gens/{qui}_{humeur}.jpg'),
                       LARGEUR_PORTRAIT)
    for p in parcours:
        reduis(os.path.join(IMAGES, f'parcours/{p["id"]}.jpg'),
               os.path.join(sortie, f'parcours/{p["id"]}.jpg'), LARGEUR_PORTRAIT)
    for f in {x['image'] for x in fins}:
        reduis(os.path.join(IMAGES, f),
               os.path.join(sortie, 'fins/' + os.path.basename(f)), LARGEUR_LARGE)
    romances = os.path.join(RACINE, 'sources/romances')
    for qui in CHAINES_DE_COEUR.values():
        for sous in (f'lit/{qui}.jpg', f'noces/{qui}_etat.jpg', f'noces/{qui}_discretes.jpg'):
            src = os.path.join(romances, sous)
            if not os.path.exists(src):
                sys.exit(f'{sous} : absent de sources/romances — relancer '
                         'planche_romances.py')
            dst = os.path.join(sortie, sous)
            if not os.path.exists(dst):
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copyfile(src, dst)
    for e in etats:
        if e['n'] == 1:
            reduis(os.path.join(PLAQUES, e['sequence'][0]),
                   os.path.join(sortie, 'decor/' + e['fichier']), LARGEUR_LARGE)
        else:
            bande([os.path.join(PLAQUES, s) for s in e['sequence']],
                  os.path.join(sortie, 'decor/' + e['fichier']), LARGEUR_PLAQUE)


def lis_les_etats():
    """Les décors du palais, tels que planche_palais.py les lit : le nombre
    d'images vient des dossiers, l'aller-retour vient de decor.dart."""
    sys.path.insert(0, os.path.join(RACINE, 'outils'))
    import planche_palais as pp
    retours = pp.allers_retours()
    etats = json.load(open(os.path.join(RACINE, 'outils/planche_etats.json')))
    manquants = []
    for e in etats:
        e['n'] = pp.combien(e['dossier'])
        if e['n'] == 0:
            manquants.append(e['dossier'])
        e['retour'] = e['dossier'] in retours
        e['sequence'] = pp.sequence(e['dossier'], e['n'], e['retour'])
        e['fichier'] = e['dossier'].replace('/', '_') + '.jpg'
        e['portrait'] = 'chambre_lit' in e['dossier']
    if manquants:
        sys.exit('plaques absentes : ' + ', '.join(manquants))
    return etats


# ──────────────────────────────── le cadre ─────────────────────────────

PAGES = [
    ('index', 'Le jeu entier'),
    ('histoires', 'Les histoires'),
    ('drapeaux', 'Les drapeaux'),
    ('cartes', 'Les cartes seules'),
    ('gens', 'Les gens'),
    ('palais', 'Le palais'),
    ('reste', 'Le reste'),
]


def barre(courante):
    return ('  <nav class="passes">' + ''.join(
        f'<a href="{n}.html" data-page="{n}" '
        f'aria-current="{str(n == courante).lower()}">{echappe(t)}</a>'
        for n, t in PAGES) + '</nav>')


def page(nom, titre, chapeau, corps, pied=''):
    seule = nom != 'index'
    gabarit = EN_TETE + GABARIT + PIED_PAGE if seule else GABARIT
    return (gabarit
            .replace('{{OUVRE_CORPS}}', '</head>\n<body>\n' if seule else '')
            .replace('{{TITRE}}', echappe(titre))
            .replace('{{VERSION}}', version())
            .replace('{{BARRE}}', barre(nom))
            .replace('{{CHAPEAU}}', chapeau)
            .replace('{{CORPS}}', corps)
            .replace('{{PIED}}', pied))
# ────────────────────────────── les histoires ──────────────────────────

# La chaîne de chacune des dix personnes qu'on peut courtiser. Deux ne
# portent pas leur identifiant : l'épouse et l'époux d'avant la romance ont
# gardé leurs noms de rôle.
CHAINES_DE_COEUR = {
    'coeur_redactrice': 'redactrice', 'coeur_cabinet': 'cabinet',
    'coeur_emissaire': 'emissaire', 'coeur_militante': 'militante',
    'coeur_protocole': 'epouse', 'coeur_international': 'international',
    'coeur_ministre': 'ministre', 'coeur_renseignements': 'renseignements',
    'coeur_maire': 'maire', 'coeur_intendant': 'epoux',
}

# Ce que chaque cérémonie montre.
NOCES = {
    'etat': "Dans la cour d'honneur — deux cents invités, la garde en grande "
            'tenue, la ville arrêtée trois heures.',
    'discretes': 'À la salle des mariages — dix minutes, quatre témoins, '
                 'aucune photographie officielle.',
}


def cran_de_la_liaison():
    """Le cran qui ouvre le rendez-vous, lu dans romance.dart."""
    src = open(os.path.join(RACINE, 'lib/moteur/romance.dart')).read()
    trouve = re.search(r'attacheLiaison\s*=\s*(\d+)', src)
    if trouve is None:
        sys.exit('romance.dart : cran de liaison introuvable')
    return int(trouve.group(1))


def rangs_de(cartes_de_la_chaine):
    rangs = {}
    for c in cartes_de_la_chaine:
        rangs.setdefault(c['chaine']['rang'], []).append(c)
    return rangs


def ordre_des_chaines(par_chaine):
    """Les histoires qui bifurquent d'abord, les romances à la fin : ce
    sont les seules qui ont déjà leur planche à elles."""
    def cle(kv):
        nom, cartes = kv
        rangs = rangs_de(cartes)
        embranche = any(len(v) > 1 for v in rangs.values())
        return (nom.startswith('coeur_'), not embranche, -len(cartes), nom)
    return [nom for nom, _ in sorted(par_chaine.items(), key=cle)]


def titre_de_chaine(nom, premiere, gens):
    """Le nom de l'histoire et celle qui l'ouvre. La première carte est
    celle du cran 1, pas la première du fichier : elles ne sont pas
    forcément rangées, et l'en-tête annonçait le mauvais visage."""
    return joli(nom).capitalize() + ' · ' + nom_de(premiere['personnage'], gens).lower()


def bloc_du_rendez_vous(qui, numero, gens, parcours, lien, par_id):
    """La soirée promise : la carte qui l'ouvre, et ce que la chambre montre
    alors. Elle se place à la charnière de l'histoire, pas à sa fin — on ne
    dort pas ensemble le soir des noces."""
    rdv = par_id.get(f'rdv_{qui}')
    if rdv is None:
        sys.exit(f'{qui} : pas de carte de rendez-vous')
    homme = qui in HOMMES
    return f"""      <div class="cran">
        <p class="acte">Le rendez-vous, et la chambre</p>
        <div class="galerie">
{carte_html(rdv, numero[rdv['id']], coiffe_de(rdv, gens, parcours, lien), gens, lien)}
        </div>
        <div class="bloc">
          <p class="etiquette">Et la chambre, ce soir-là</p>
          <div class="issue">
            <img src="lit/{qui}.jpg" alt="" loading="lazy">
            <p class="porte">{'Il attend habillé.' if homme else 'Elle attend habillée.'}
            Un appui, {'il' if homme else 'elle'} se déshabille. Un second, la scène
            passe sur le lit. Les jours ordinaires, la chambre dit seulement
            qu'on n'y dort plus seul.</p>
          </div>
        </div>
      </div>"""


def bloc_des_noces(qui):
    vues = ''.join(
        f'<figure class="noce"><img src="noces/{qui}_{v}.jpg" alt="" loading="lazy">'
        f'<figcaption>{echappe(NOCES[v])}</figcaption></figure>'
        for v in ('etat', 'discretes'))
    return f"""      <div class="cran">
        <p class="acte">Le jour des noces</p>
        <div class="bloc">
          <div class="noces">{vues}</div>
          <p class="porte">La cérémonie se joue une fois, en plein écran, après
          la réponse — comme une fin, mais au milieu du mandat. C'est le seul
          moment du jeu qu'on ne peut pas revoir.</p>
        </div>
      </div>"""


# Ceux dont la chambre se raconte au masculin. Le jeu ne porte pas le genre
# de ses personnages — seule cette planche a besoin de l'accord.
HOMMES = {'international', 'ministre', 'renseignements', 'maire', 'epoux'}


def page_des_histoires(par_chaine, numero, gens, parcours, lien, par_id, liaison):
    blocs = []
    for i, nom in enumerate(ordre_des_chaines(par_chaine), 1):
        cartes = par_chaine[nom]
        rangs = rangs_de(cartes)
        manque = [r for r in range(1, max(rangs) + 1) if r not in rangs]
        if manque:
            sys.exit(f'{nom} : crans absents {manque}')
        premiere = rangs[min(rangs)][0]
        embranche = sum(1 for v in rangs.values() if len(v) > 1)
        delai = {c['chaine'].get('delai_min', 0) for c in cartes if c['chaine'].get('delai_min')}
        etiquettes = [f'{len(cartes)} cartes', f'{max(rangs)} crans']
        if embranche:
            etiquettes.append(f'{embranche} embranchement' + ('s' if embranche > 1 else ''))
        if delai:
            etiquettes.append('délai ' + ' et '.join(f'{d} j' for d in sorted(delai)))
        qui = CHAINES_DE_COEUR.get(nom)
        crans = []
        for r in sorted(rangs):
            choix = rangs[r]
            titre = f'Cran {r}' + (f' — {len(choix)} cartes possibles' if len(choix) > 1 else '')
            galerie = ''.join(
                carte_html(c, numero[c['id']],
                           coiffe_de(c, gens, parcours, lien, avec_rang=False), gens, lien)
                for c in choix)
            crans.append(f'''      <div class="cran">
        <p class="acte">{echappe(titre)}</p>
        <div class="galerie">
{galerie}
        </div>
      </div>''')
            if qui and r == liaison:
                crans.append(bloc_du_rendez_vous(qui, numero, gens, parcours, lien, par_id))
        if qui:
            crans.append(bloc_des_noces(qui))
        blocs.append(f'''  <section class="personne" id="h{i}">
    <div class="tete">
      <img src="{portrait(premiere)}" alt="" loading="lazy">
      <div>
        <h2><span class="rang-h">H{i}</span>{echappe(titre_de_chaine(nom, premiere, gens))}</h2>
        <p class="titre">{echappe(' · '.join(etiquettes))}</p>
      </div>
    </div>
{chr(10).join(crans)}
  </section>''')
    return '\n'.join(blocs)


# ────────────────────────────── les drapeaux ───────────────────────────

# Les drapeaux que le moteur lit lui-même, hors de toute carte : la page
# les dirait « posés pour mémoire » alors qu'ils commandent un décor, une
# cérémonie ou un coffre. Chacun est vérifié dans lib/ au passage — un nom
# qui changerait sans qu'on le suive rendrait la planche menteuse.
LUS_PAR_LE_MOTEUR = {
    'fete_nationale': 'décor du balcon — le défilé',
    'deuil_national': 'décor du balcon — le deuil',
    'noces_etat': 'la cérémonie en grande pompe',
    'noces_discretes': 'la cérémonie à la sauvette',
    'noces_vues': 'la cérémonie a déjà été montrée',
    'objet_coffre_fort': 'le coffre du bureau',
    'coffre_ouvert': 'le coffre a déjà été ouvert',
}


def verifie_les_drapeaux_du_moteur():
    """Que les noms cités existent encore dans le code."""
    code = ''
    for dossier, _, fichiers in os.walk(os.path.join(RACINE, 'lib')):
        for f in fichiers:
            if f.endswith('.dart'):
                code += open(os.path.join(dossier, f)).read()
    absents = [d for d in LUS_PAR_LE_MOTEUR if f"'{d}'" not in code]
    if absents:
        sys.exit('drapeaux du moteur introuvables dans lib/ : ' + ', '.join(absents))


def lu_par_le_moteur(d):
    if d in LUS_PAR_LE_MOTEUR:
        return LUS_PAR_LE_MOTEUR[d]
    if d.startswith('rdv_'):
        return 'le rendez-vous du soir, dans la chambre'
    return None


def releve_des_drapeaux(cartes):
    """Qui pose quoi, qui le lit. C'est la vraie carte des ramifications :
    une carte n'appelle pas la suivante, elle pose un drapeau que la
    suivante exige."""
    pose, exige, interdit = {}, {}, {}
    for c in cartes:
        for sens, cle in (('←', 'gauche'), ('→', 'droite')):
            for d in c[cle].get('drapeaux', []):
                pose.setdefault(d, []).append((c, sens, c[cle]['libelle']))
        cond = c.get('conditions', {})
        for d in cond.get('drapeaux_requis', []):
            exige.setdefault(d, []).append(c)
        for d in cond.get('drapeaux_interdits', []):
            interdit.setdefault(d, []).append(c)
    return pose, exige, interdit


def page_des_drapeaux(cartes, numero, ou, gens):
    pose, exige, interdit = releve_des_drapeaux(cartes)
    tous = sorted(set(pose) | set(exige) | set(interdit))

    def renvoi(c):
        return (f'<a class="renvoi" href="{ou[c["id"]]}.html#c{numero[c["id"]]}">'
                f'{numero[c["id"]]}</a>')

    lignes = []
    for i, d in enumerate(tous, 1):
        mis = ''.join(
            f'<li>{renvoi(c)} <span class="sens-min">{sens} {echappe(lib)}</span> '
            f'<span class="qui">{echappe(nom_de(c["personnage"], gens))}</span></li>'
            for c, sens, lib in pose.get(d, []))
        lus = ''.join(
            f'<li>{renvoi(c)} <span class="qui">{echappe(nom_de(c["personnage"], gens))}</span></li>'
            for c in exige.get(d, []))
        fermes = ''.join(
            f'<li>{renvoi(c)} <span class="qui">{echappe(nom_de(c["personnage"], gens))}</span></li>'
            for c in interdit.get(d, []))
        moteur = lu_par_le_moteur(d)
        alerte = ''
        if not pose.get(d) and exige.get(d):
            alerte = ('<p class="alerte">Personne ne le pose, et des cartes l\'exigent : '
                      'elles ne sortiront jamais.</p>')
        elif not pose.get(d) and interdit.get(d):
            alerte = ('<p class="alerte">Personne ne le pose : le garde-fou ne joue '
                      'jamais, et la carte qui s\'en protège sort toujours.</p>')
        elif moteur:
            alerte = f'<p class="tiede">Lu par le jeu lui-même : {echappe(moteur)}.</p>'
        elif not exige.get(d) and not interdit.get(d):
            alerte = '<p class="tiede">Personne ne le lit : il est posé pour mémoire.</p>'
        lignes.append(f'''    <article class="drapeau" id="d-{echappe(d)}">
      <div class="dr-tete"><span class="rang-h">D{i}</span>
        <h3>{echappe(joli(d))}</h3></div>
      {alerte}
      <div class="colonnes">
        <div><p class="etiquette">Posé par</p><ul>{mis or '<li class="rien">personne</li>'}</ul></div>
        <div><p class="etiquette">Exigé par</p><ul>{lus or '<li class="rien">personne</li>'}</ul></div>
        <div><p class="etiquette">Interdit à</p><ul>{fermes or '<li class="rien">personne</li>'}</ul></div>
      </div>
    </article>''')
    return '\n'.join(lignes), len(tous)


# ─────────────────────────── les cartes seules ─────────────────────────

def ordre_des_seules(seules):
    """Les cartes hors histoire, par personne, la plus bavarde d'abord. Le
    même ordre sert à numéroter et à dessiner : sans ça la carte 512 de la
    page des drapeaux ne serait pas la 512 de la page des cartes."""
    par_qui = {}
    for c in seules:
        par_qui.setdefault(c['personnage'], []).append(c)
    return [(qui, par_qui[qui]) for qui in sorted(par_qui, key=lambda q: -len(par_qui[q]))]


def page_des_cartes(lots, numero, gens, parcours, lien):
    blocs = []
    for qui, lot in lots:
        galerie = ''.join(
            carte_html(c, numero[c['id']], coiffe_de(c, gens, parcours, lien), gens, lien)
            for c in lot)
        jauge = gens.get(qui, {}).get('jauge', '')
        blocs.append(f'''  <section class="personne" id="p-{qui}">
    <div class="tete">
      <img src="{portrait(lot[0])}" alt="" loading="lazy">
      <div>
        <h2>{echappe(nom_de(qui, gens))}</h2>
        <p class="titre">{len(lot)} cartes hors histoire{' · jauge ' + JAUGES.get(jauge, jauge) if jauge else ''}</p>
      </div>
    </div>
    <div class="galerie">
{galerie}
    </div>
  </section>''')
    return '\n'.join(blocs)


# ──────────────────────────────── les gens ─────────────────────────────

HUMEURS = [('neutre', 'Neutre'), ('fache', 'Fâché'), ('content', 'Content')]


def page_des_gens(gens, cartes, parcours, adversaires):
    compte = {}
    for c in cartes:
        compte[c['personnage']] = compte.get(c['personnage'], 0) + 1
    fiches = []
    for i, (qui, p) in enumerate(
            sorted(gens.items(), key=lambda kv: -compte.get(kv[0], 0)), 1):
        vues = ''.join(
            f'<figure class="humeur"><img src="gens/{qui}_{h}.jpg" alt="" loading="lazy">'
            f'<figcaption>{echappe(nom)}</figcaption></figure>'
            for h, nom in HUMEURS
            if os.path.exists(os.path.join(IMAGES, f'personnages/{qui}_{h}.jpg')))
        jauge = p.get('jauge', '')
        fiches.append(f'''    <article class="fiche-gens" id="g{i}">
      <div class="dr-tete"><span class="rang-h">G{i}</span><h3>{echappe(p['nom'])}</h3></div>
      <p class="titre">{compte.get(qui, 0)} cartes{' · jauge ' + JAUGES.get(jauge, jauge) if jauge else ''}
        · <a href="cartes.html#p-{qui}">voir ses cartes</a></p>
      <div class="humeurs">{vues}</div>
    </article>''')

    lots = ''.join(
        f'''    <article class="fiche-gens" id="j{i}">
      <div class="dr-tete"><span class="rang-h">J{i}</span><h3>{echappe(p['nom'])}</h3></div>
      <p class="titre">{echappe(p['titre'])} · départ {', '.join(
          f"{JAUGES.get(k, k)} {v}" for k, v in p['depart'].items())}</p>
      <div class="humeurs"><figure class="humeur">
        <img src="parcours/{p['id']}.jpg" alt="" loading="lazy">
        <figcaption>{echappe(p['accroche'])}</figcaption></figure></div>
    </article>''' for i, p in enumerate(parcours, 1))

    duels = ''.join(
        f'''    <article class="fiche-gens plat" id="a{i}">
      <div class="dr-tete"><span class="rang-h">A{i}</span><h3>{echappe(a['nom'])}</h3></div>
      <p class="titre">{echappe(a['titre'])}</p>
      <p class="note">{echappe(a['accroche'])}</p>
    </article>''' for i, a in enumerate(adversaires, 1))

    return (f'''  <section class="personne">
    <h2>Les {len(gens)} personnages</h2>
    <p class="note">Trois humeurs chacun : c'est l'humeur écrite sur la carte
    qui choisit le portrait, pas l'état du pays.</p>
    <div class="fiches">
{''.join(fiches)}
    </div>
  </section>
  <section class="personne">
    <h2>Les {len(parcours)} parcours</h2>
    <p class="note">Le parcours choisi fixe les quatre jauges de départ, le
    titre que les cartes emploient, et lesquelles peuvent sortir.</p>
    <div class="fiches">
{lots}
    </div>
  </section>
  <section class="personne">
    <h2>Les {len(adversaires)} adversaires</h2>
    <p class="note">Celui qui se présente contre vous à la fin du mandat.</p>
    <div class="fiches">
{duels}
    </div>
  </section>''')


# ─────────────────────────────── le palais ─────────────────────────────

def page_du_palais(etats):
    ordre = ['Le bureau', 'Le balcon, de jour', 'Le balcon, de nuit',
             'La chambre', 'La chambre partagée', 'Le rendez-vous',
             'La cour des voitures', 'La piscine']
    n = 0
    blocs = []
    for piece in ordre:
        dedans = [e for e in etats if e['piece'] == piece]
        if not dedans:
            continue
        fiches = []
        for e in dedans:
            n += 1
            pas = len(e['sequence'])
            if pas == 1:
                vue = (f'<img class="plaque" src="decor/{e["fichier"]}" alt="" loading="lazy">')
                compte = '1 image'
            else:
                # La bande se charge quand la fiche arrive à l'écran : douze
                # boucles ouvertes d'un coup mettraient le navigateur à genoux.
                vue = (f'<div class="plaque bande" data-bande="decor/{e["fichier"]}" '
                       f'style="background-size:{pas * 100}% 100%;'
                       f'animation-duration:{pas * 0.42:.2f}s;'
                       f'animation-timing-function:steps({pas},jump-none)"></div>')
                compte = f'{e["n"]} images' + (' ↔' if e['retour'] else '')
            classe = 'decor portrait' if e['portrait'] else 'decor'
            note = f'<p class="note">{echappe(e["note"])}</p>' if e.get('note') else ''
            fiches.append(f'''      <article class="{classe}" id="pa{n}">
        <div class="cadre">{vue}<span class="rang-h">P{n}</span>
          <span class="compte-img">{compte}</span></div>
        <p class="nom-decor">{echappe(e['nom'])}</p>
        <p class="cond">{echappe(e['cond'])}</p>
        {note}
      </article>''')
        blocs.append(f'''  <section class="personne">
    <h2>{echappe(piece)}</h2>
    <p class="titre">{len(dedans)} états · la première règle qui s'applique gagne</p>
    <div class="decors">
{''.join(fiches)}
    </div>
  </section>''')
    return '\n'.join(blocs), n


# ──────────────────────────────── le reste ─────────────────────────────

def page_du_reste(objets, fins, exploits):
    par_piece = {}
    for o in objets:
        par_piece.setdefault(o['piece'], []).append(o)
    n = 0
    lots = []
    for piece in sorted(par_piece):
        lignes = []
        for o in par_piece[piece]:
            n += 1
            lignes.append(
                f'<li><span class="rang-h">O{n}</span><b>{echappe(o["nom"])}</b>'
                f'<span class="prix-objet">{o["prix"]} caisses</span>'
                f'<span class="natures">{echappe(", ".join(o["natures"]))}</span>'
                f'<p class="note">{echappe(o["description"])}</p></li>')
        lots.append(f'''    <div class="lot">
      <p class="etiquette">{echappe(piece)}</p>
      <ul class="liste">{''.join(lignes)}</ul>
    </div>''')

    issues = ''.join(
        f'''      <article class="fin" id="f{i}">
        <img src="fins/{os.path.basename(f['image'])}" alt="" loading="lazy">
        <div><div class="dr-tete"><span class="rang-h">F{i}</span>
          <h3>{echappe(f['titre'])}</h3></div>
          <p class="cond">{echappe(JAUGES.get(f.get('jauge', ''), f.get('jauge', '')))}
            {'au plus haut' if f.get('vers_le_haut') else 'au plus bas'}</p>
          <p class="note">{echappe(f['texte'])}</p></div>
      </article>''' for i, f in enumerate(fins, 1))

    hauts = ''.join(
        f'''      <li><span class="rang-h">E{i}</span><b>{echappe(e['titre'])}</b>
        <p class="note">{echappe(e['description'])}</p></li>'''
        for i, e in enumerate(exploits, 1))

    return f'''  <section class="personne">
    <h2>Les {len(objets)} objets du palais</h2>
    <p class="note">Ce qu'on achète avec les caisses. Certains changent le
    décor d'une pièce, d'autres ouvrent une carte.</p>
    <div class="lots">
{''.join(lots)}
    </div>
  </section>
  <section class="personne">
    <h2>Les {len(fins)} fins</h2>
    <p class="note">Une jauge au bout arrête le mandat. Chaque jauge a sa fin
    par le haut et sa fin par le bas.</p>
    <div class="fins">
{issues}
    </div>
  </section>
  <section class="personne">
    <h2>Les {len(exploits)} exploits</h2>
    <ul class="liste">{hauts}</ul>
  </section>'''


# ──────────────────────────────── l'accueil ────────────────────────────

def page_index(chiffres):
    lignes = ''.join(
        f'''      <a class="porte-page" href="{nom}.html">
        <span class="rang-h">{marque}</span>
        <span class="porte-titre">{echappe(titre)}</span>
        <span class="porte-quoi">{echappe(quoi)}</span>
      </a>''' for nom, marque, titre, quoi in chiffres)
    return f'''  <div class="portes-pages">
{lignes}
  </div>'''


# ───────────────────────────────── la page ─────────────────────────────

# L'accueil part dans l'enveloppe de l'artifact, qui pose déjà le doctype,
# le charset et la fenêtre. Les pages voisines sont servies brutes : sans
# ces quatre lignes, tous les accents partent en carrés.
EN_TETE = '''<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
'''

PIED_PAGE = '''
</body>
</html>
'''

GABARIT = '''<title>{{TITRE}}</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,700;12..96,800&family=Public+Sans:wght@0,400;0,600&display=swap">
<link rel="stylesheet" href="jeu.css">
{{OUVRE_CORPS}}<div class="page">
  <p class="surtitre">Palabre — Président pour 100 jours · version {{VERSION}}</p>
  <h1>{{TITRE}}</h1>
  <div class="chapeau">{{CHAPEAU}}</div>
{{BARRE}}
{{CORPS}}
  <footer><p class="note">{{PIED}}</p></footer>
</div>
<script>
  // Les bandes du palais ne se chargent qu'une fois à l'écran : soixante-deux
  // boucles ouvertes d'un coup useraient la mémoire du navigateur pour rien.
  (function () {
    var bandes = document.querySelectorAll('.bande[data-bande]');
    if (!bandes.length) return;
    if (!('IntersectionObserver' in window)) {
      bandes.forEach(function (b) { b.style.backgroundImage = 'url(' + b.dataset.bande + ')'; });
      return;
    }
    var oeil = new IntersectionObserver(function (vues) {
      vues.forEach(function (v) {
        var b = v.target;
        if (v.isIntersecting) {
          if (!b.style.backgroundImage) b.style.backgroundImage = 'url(' + b.dataset.bande + ')';
          b.style.animationPlayState = 'running';
        } else {
          b.style.animationPlayState = 'paused';
        }
      });
    }, {rootMargin: '300px'});
    bandes.forEach(function (b) { oeil.observe(b); });
  })();
</script>'''


FEUILLE = ''':root{
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
:root{color-scheme:light dark}
body{margin:0;background:var(--fond);color:var(--encre);font-family:var(--corps);
  font-size:16px;line-height:1.5}
img{max-width:100%}
[hidden]{display:none!important}
.page{max-width:1000px;margin:0 auto;padding:0 20px;padding-block:40px 72px}
h1,h2,h3{font-family:var(--serif);margin:0;text-wrap:balance}
h1{font-size:clamp(1.9rem,5.5vw,2.9rem);font-weight:800;line-height:1.02;letter-spacing:-.015em}
h2{font-size:1.4rem;font-weight:700;line-height:1.1}
h3{font-size:1.02rem;font-weight:700}
p{margin:0 0 .8em;max-width:64ch}
a{color:var(--or)}
.surtitre{font-size:.72rem;letter-spacing:.18em;text-transform:uppercase;
  color:var(--faible);font-weight:600;margin:0 0 12px}
.chapeau{font-size:1.06rem;color:var(--douce);max-width:60ch;margin-top:14px}
.chapeau p{color:var(--douce)}
.note{font-size:.84rem;color:var(--faible);max-width:70ch}
.titre{font-size:.82rem;color:var(--faible);margin:2px 0 0}
.etiquette{font-size:.7rem;letter-spacing:.14em;text-transform:uppercase;
  color:var(--or);font-weight:600;margin:0 0 10px}

/* La barre des pages, collée en haut : le document se lit par sauts. */
.passes{position:sticky;top:0;z-index:5;display:flex;flex-wrap:wrap;gap:.4rem;
  margin:26px 0 8px;padding:.7rem 0;background:var(--fond);
  border-top:1px solid var(--trait);border-bottom:1px solid var(--trait)}
.passes a{font:600 .8rem/1.2 var(--corps);color:var(--douce);text-decoration:none;
  background:var(--leve);border:1px solid var(--trait);border-radius:999px;
  padding:.5rem .9rem}
.passes a[aria-current="true"]{color:var(--nuit);background:var(--or);border-color:var(--or)}

.rang-h{font-family:var(--serif);font-size:.72rem;font-weight:700;color:var(--nuit);
  background:var(--or);border-radius:3px;padding:2px 7px;letter-spacing:.02em;flex:none}

.personne{border-top:1px solid var(--trait);margin-top:46px;padding-top:26px}
.tete{display:flex;align-items:center;gap:16px;margin-bottom:22px}
.tete img{width:60px;height:60px;border-radius:50%;object-fit:cover;
  border:1px solid var(--trait);flex:none}
.tete h2{display:flex;align-items:center;gap:10px;flex-wrap:wrap}

/* La carte, telle que partie_ecran.dart la dessine. */
.galerie{display:grid;grid-template-columns:repeat(auto-fill,minmax(258px,1fr));gap:22px}
.carte{margin:0;scroll-margin-top:90px}
.numero{position:absolute;top:10px;left:10px;z-index:2;font-family:var(--serif);
  font-size:.78rem;font-weight:700;color:var(--nuit);background:var(--or);
  border-radius:3px;padding:2px 7px}
.tenant{position:absolute;top:10px;right:10px;z-index:2;font-size:.6rem;
  letter-spacing:.06em;color:var(--douce);background:rgba(8,7,9,.8);
  border:1px solid var(--trait);border-radius:3px;padding:2px 6px}
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
.portes{display:flex;flex-wrap:wrap;gap:4px;margin-top:6px}
.dr{font-size:.64rem;border-radius:2px;padding:2px 5px;text-decoration:none;
  border:1px solid var(--trait);color:var(--douce)}
.dr.req{border-color:var(--or);color:var(--or)}
.dr.int{border-color:var(--chair);color:var(--chair)}
.deux{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.geste{min-width:0}
.sens{display:block;font-size:.78rem;font-weight:600;color:var(--douce);margin-bottom:5px}
.geste:last-child .sens{text-align:right}
.prix{display:flex;flex-wrap:wrap;gap:4px}
.geste:last-child .prix{justify-content:flex-end}
.jauge{font-size:.66rem;color:var(--faible);border:1px solid var(--trait);
  border-radius:2px;padding:2px 5px;white-space:nowrap;text-decoration:none}
.jauge b{font-family:var(--serif);margin-left:4px}
.jauge.plus b{color:var(--or)}
.jauge.moins b{color:var(--chair)}
.jauge.romance{border-color:var(--chair);color:var(--chair)}
.jauge.drapeau{font-style:italic;color:var(--douce)}
.issue{display:flex;gap:16px;align-items:flex-start}
.issue img{width:120px;aspect-ratio:3/4;object-fit:cover;border-radius:3px;flex:none}
.issue .porte{margin:0;max-width:52ch}
.noces{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px;margin-bottom:12px}
.noce{margin:0}
.noce img{width:100%;aspect-ratio:3/2;object-fit:cover;border-radius:3px;display:block}
.noce figcaption{font-size:.76rem;color:var(--douce);margin-top:7px}
.acte{font-size:.7rem;letter-spacing:.16em;text-transform:uppercase;color:var(--or);
  font-weight:600;margin:26px 0 14px;padding-top:14px;border-top:1px solid var(--trait)}
.cran:first-of-type .acte{margin-top:0;padding-top:0;border-top:none}

/* Les drapeaux : qui pose, qui lit. */
.drapeau{border-top:1px solid var(--trait);padding:18px 0;scroll-margin-top:90px}
.dr-tete{display:flex;align-items:center;gap:10px;margin-bottom:8px}
.colonnes{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px}
.colonnes ul{list-style:none;margin:0;padding:0}
.colonnes li{font-size:.8rem;color:var(--douce);padding:3px 0;display:flex;
  gap:7px;align-items:baseline;flex-wrap:wrap}
.renvoi{font-family:var(--serif);font-size:.72rem;font-weight:700;color:var(--nuit);
  background:var(--or);border-radius:3px;padding:1px 6px;text-decoration:none;flex:none}
.sens-min{color:var(--encre)}
.qui{color:var(--faible);font-size:.74rem}
.rien{color:var(--faible);font-style:italic}
.alerte{font-size:.8rem;color:var(--chair);margin:0 0 10px}
.tiede{font-size:.8rem;color:var(--faible);margin:0 0 10px}

/* Les gens, les parcours, les adversaires. */
.fiches{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:24px}
.fiche-gens{scroll-margin-top:90px}
.humeurs{display:grid;grid-template-columns:repeat(3,1fr);gap:8px;margin-top:10px}
.fiche-gens .humeurs:has(figure:only-child){grid-template-columns:1fr}
.humeur{margin:0}
.humeur img{width:100%;aspect-ratio:3/4;object-fit:cover;border-radius:4px;display:block}
.humeur figcaption{font-size:.72rem;color:var(--faible);margin-top:5px}
.plat{background:var(--leve);border:1px solid var(--trait);border-radius:4px;padding:14px 16px}

/* Le palais : une bande par boucle, décalée d'un cran à la fois. */
.decors{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:24px}
.decor{margin:0;scroll-margin-top:90px}
.cadre{position:relative;aspect-ratio:3/2;border-radius:6px;overflow:hidden;
  background:var(--leve);border:1px solid var(--trait)}
.decor.portrait .cadre{aspect-ratio:3/4}
.plaque{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
.bande{background-repeat:no-repeat;background-position-x:0%;
  animation-name:defile;animation-iteration-count:infinite}
@keyframes defile{from{background-position-x:0%}to{background-position-x:100%}}
@media (prefers-reduced-motion:reduce){.bande{animation:none}}
.compte-img{position:absolute;top:8px;right:8px;font-size:.62rem;color:var(--douce);
  background:rgba(8,7,9,.78);border-radius:3px;padding:2px 6px}
.cadre .rang-h{position:absolute;top:8px;left:8px}
.nom-decor{font-family:var(--serif);font-weight:700;margin:10px 0 2px}
.cond{font-size:.78rem;color:var(--faible);margin:0 0 4px}

/* Le reste : objets, fins, exploits. */
.lots{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:24px}
.liste{list-style:none;margin:0;padding:0}
.liste li{border-top:1px solid var(--trait);padding:10px 0;display:flex;
  flex-wrap:wrap;align-items:baseline;gap:8px}
.liste b{font-family:var(--serif)}
.liste .note{width:100%;margin:2px 0 0}
.prix-objet{font-size:.72rem;color:var(--or)}
.natures{font-size:.7rem;color:var(--faible);font-style:italic}
.fins{display:grid;gap:18px}
.fin{display:flex;gap:16px;align-items:flex-start;scroll-margin-top:90px}
.fin img{width:200px;aspect-ratio:3/2;object-fit:cover;border-radius:4px;flex:none}

/* L'accueil : sept portes. */
.portes-pages{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));
  gap:16px;margin-top:30px}
.porte-page{display:flex;flex-direction:column;gap:6px;text-decoration:none;
  background:var(--leve);border:1px solid var(--trait);border-radius:6px;padding:16px 18px}
.porte-page .rang-h{align-self:flex-start}
.porte-titre{font-family:var(--serif);font-weight:700;font-size:1.1rem;color:var(--encre)}
.porte-quoi{font-size:.82rem;color:var(--faible)}

@media (max-width:520px){
  .galerie{grid-template-columns:1fr}
  .fin{flex-direction:column}
  .fin img{width:100%}
  .passes a{padding:.45rem .7rem;font-size:.74rem}
}
'''


# ──────────────────────────────── le tour ──────────────────────────────

def main():
    sortie = (sys.argv[1] if len(sys.argv) > 1
              else os.path.join(RACINE, 'sources/jeu'))
    os.makedirs(sortie, exist_ok=True)

    cartes = charge('cartes')
    gens = {p['id']: p for p in charge('personnages')}
    parcours = charge('parcours')
    parcours_par_id = {p['id']: p for p in parcours}
    objets, fins, exploits = charge('objets'), charge('fins'), charge('exploits')
    adversaires = charge('adversaires')

    par_id = {c['id']: c for c in cartes}
    par_chaine = {}
    seules = []
    for c in cartes:
        ch = c.get('chaine')
        if ch:
            par_chaine.setdefault(ch['id'], []).append(c)
        else:
            seules.append(c)
    lots = ordre_des_seules(seules)

    # Un seul espace de numéros pour les 650 cartes, posé dans l'ordre de
    # lecture : les histoires d'abord, les cartes seules ensuite. C'est par
    # ces numéros qu'on se parle d'une carte.
    numero, ou, n = {}, {}, 0
    for nom in ordre_des_chaines(par_chaine):
        rangs = rangs_de(par_chaine[nom])
        for r in sorted(rangs):
            for c in rangs[r]:
                n += 1
                numero[c['id']], ou[c['id']] = n, 'histoires'
    for qui, lot in lots:
        for c in lot:
            n += 1
            numero[c['id']], ou[c['id']] = n, 'cartes'
    if n != len(cartes):
        sys.exit(f'{n} cartes numérotées pour {len(cartes)} lues')

    def lien(d):
        return f'drapeaux.html#d-{d}'

    verifie_les_drapeaux_du_moteur()
    etats = lis_les_etats()
    prepare_les_images(sortie, gens, parcours, fins, etats)

    marqueurs = ('Les numéros ne bougent pas d\'une planche à l\'autre : une '
                 'carte porte le même de bout en bout. Les cartes disent '
                 '« Monsieur le Président » et « Idriss » ici — en jeu, le '
                 'titre et le nom viennent du parcours choisi.')

    corps_h = page_des_histoires(par_chaine, numero, gens, parcours_par_id, lien,
                                 par_id, cran_de_la_liaison())
    corps_d, combien_drapeaux = page_des_drapeaux(cartes, numero, ou, gens)
    corps_c = page_des_cartes(lots, numero, gens, parcours_par_id, lien)
    corps_g = page_des_gens(gens, cartes, parcours, adversaires)
    corps_p, combien_decors = page_du_palais(etats)
    corps_r = page_du_reste(objets, fins, exploits)

    en_chaine = sum(len(v) for v in par_chaine.values())
    embranchees = sum(1 for v in par_chaine.values()
                      if any(len(l) > 1 for l in rangs_de(v).values()))

    pages = {
        'histoires': (
            'Les histoires',
            f'<p>Les {len(par_chaine)} suites de plusieurs cartes, cran par cran : '
            f'{en_chaine} cartes en tout, dont {embranchees} histoires qui bifurquent. '
            'Une carte n\'appelle pas la suivante — elle pose un drapeau que la '
            'suivante exige. Les drapeaux sont cliquables.</p>'
            f'<p class="note">{marqueurs}</p>', corps_h,
            f'{en_chaine} cartes en chaîne sur {len(cartes)}.'),
        'drapeaux': (
            'Les drapeaux',
            f'<p>Les {combien_drapeaux} drapeaux que le jeu pose et relit. C\'est '
            'ici que sont les ramifications : un drapeau posé par une réponse '
            'ouvre ou ferme des cartes des dizaines de jours plus tard. Aucune '
            'partie ne les montre tous.</p>', corps_d,
            'Un drapeau que personne ne pose rend muettes les cartes qui l\'exigent : '
            'la page le signale en rouge.'),
        'cartes': (
            'Les cartes seules',
            f'<p>Les {len(seules)} cartes qui ne tiennent à aucune suite, rangées '
            'par personne. Ce sont elles qui remplissent le mandat entre deux '
            f'histoires.</p><p class="note">{marqueurs}</p>', corps_c,
            f'{len(seules)} cartes seules sur {len(cartes)}.'),
        'gens': (
            'Les gens',
            f'<p>Les {len(gens)} personnages et leurs trois humeurs, les '
            f'{len(parcours)} parcours jouables et leurs jauges de départ, et les '
            f'{len(adversaires)} adversaires de fin de mandat.</p>', corps_g,
            'Le conjoint n\'a pas de portrait à lui : en jeu, c\'est le visage de '
            'la personne épousée qui parle.'),
        'palais': (
            'Le palais',
            f'<p>Les {combien_decors} décors des cinq pièces, animés comme en jeu. '
            'La règle de chaque pièce est une cascade : la première ligne qui '
            's\'applique gagne, et c\'est elle qui est écrite sous chaque image.</p>',
            corps_p,
            'Les boucles jouées « ↔ » repassent par où elles sont venues : c\'est '
            'ce qui leur évite un raccord sec toutes les huit secondes.'),
        'reste': (
            'Le reste',
            f'<p>Les {len(objets)} objets du palais, les {len(fins)} fins et les '
            f'{len(exploits)} exploits.</p>', corps_r, ''),
    }

    for nom, (titre, chapeau, corps, pied) in pages.items():
        open(os.path.join(sortie, nom + '.html'), 'w').write(
            page(nom, titre, chapeau, corps, pied))

    accueil = page_index([
        ('histoires', 'H', 'Les histoires',
         f'{len(par_chaine)} suites, {en_chaine} cartes, {embranchees} qui bifurquent'),
        ('drapeaux', 'D', 'Les drapeaux',
         f'{combien_drapeaux} drapeaux : qui les pose, qui les lit'),
        ('cartes', 'C', 'Les cartes seules',
         f'{len(seules)} cartes, par personne'),
        ('gens', 'G', 'Les gens',
         f'{len(gens)} personnages, {len(parcours)} parcours, {len(adversaires)} adversaires'),
        ('palais', 'P', 'Le palais', f'{combien_decors} décors animés, cinq pièces'),
        ('reste', 'O', 'Le reste',
         f'{len(objets)} objets, {len(fins)} fins, {len(exploits)} exploits'),
    ])
    open(os.path.join(sortie, 'index.html'), 'w').write(page(
        'index', 'Le jeu entier',
        f'<p>Tout le contenu de Palabre à plat : {len(cartes)} cartes, '
        f'{combien_drapeaux} drapeaux, {combien_decors} décors, '
        f'{len(gens)} personnages. Écrit depuis le contenu du jeu — ce qui est '
        'ici est ce qui se joue.</p>'
        '<p class="note">Il faudrait des centaines de mandats pour croiser tout '
        'ça en jouant : la plupart des drapeaux ne se rencontrent qu\'une fois '
        'sur des dizaines de parties. Cette planche les montre tous d\'un coup.</p>',
        accueil,
        'Chaque famille a sa lettre : H pour les histoires, D pour les drapeaux, '
        'G pour les gens, P pour les décors, O pour les objets, F pour les fins, '
        'E pour les exploits, J pour les parcours, A pour les adversaires. Les '
        'cartes, elles, portent un numéro nu, de 1 à '
        f'{len(cartes)}.'))

    open(os.path.join(sortie, 'jeu.css'), 'w').write(FEUILLE)

    fichiers = sum(len(f) for _, _, f in os.walk(sortie))
    poids = sum(os.path.getsize(os.path.join(d, f))
                for d, _, fs in os.walk(sortie) for f in fs)
    print(f'{sortie} — {len(cartes)} cartes, {len(par_chaine)} histoires, '
          f'{combien_drapeaux} drapeaux, {combien_decors} décors')
    print(f'{fichiers} fichiers, {poids / 1e6:.1f} Mo')


if __name__ == '__main__':
    main()
