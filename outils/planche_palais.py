#!/usr/bin/env python3
"""Refait « Le palais état par état » à partir du code et des images.

La planche a dérivé trois fois : une boucle ajoutée dans decor.dart, et la
page continuait d'annoncer « 1 image ». Elle n'est donc plus écrite à la
main. Le nombre d'images vient des dossiers, l'aller-retour vient de
decor.dart, et seule la prose — ce qui déclenche l'état — reste dans
etats.json.

    python3 outils/planche_palais.py <dossier de sortie>

Écrit <sortie>/palais.html et <sortie>/<les images réduites>, prêts à
publier tels quels.
"""

import json
import os
import re
import subprocess
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAQUES = os.path.join(RACINE, 'assets/images/palais')
PROSE = os.path.join(RACINE, 'outils/planche_etats.json')
LARGEUR = 760  # de quoi juger le cadrage sans traîner douze méga

ORDRE = [
    'Le bureau', 'Le balcon, de jour', 'Le balcon, de nuit',
    'La chambre partagée', 'Le rendez-vous', 'La chambre', 'La cour des voitures',
    'La piscine',
]


def blocs_decor(src):
    """Le contenu de chaque `Decor(...)`, parenthèses équilibrées — le
    balcon écrit `dossier: d('emeute')`, une expression régulière naïve
    s'arrête sur cette parenthèse-là et rate les dix-huit états."""
    for depart in (m.end() for m in re.finditer(r'\bDecor\(', src)):
        creux, i = 1, depart
        while creux:
            if src[i] == '(':
                creux += 1
            elif src[i] == ')':
                creux -= 1
            i += 1
        yield src[depart:i - 1]


def allers_retours():
    """Les dossiers que decor.dart joue en aller-retour.

    Le tour échoue si une forme de `dossier:` lui échappe : mieux vaut
    s'arrêter que republier une planche qui annonce des images fixes là où
    le jeu joue une boucle.
    """
    src = open(os.path.join(RACINE, 'lib/moteur/decor.dart')).read()
    dedans = set()
    for bloc in blocs_decor(src):
        if bloc.lstrip().startswith('{'):
            continue  # la déclaration du constructeur, pas un décor
        retour = 'allerRetour: true' in bloc
        litteral = re.search(r"dossier:\s*'([^'$]+)'", bloc)
        aide = re.search(r"dossier:\s*d\('([^']+)'\)", bloc)
        # « pieces/chambre_lit/$qui » : on garde le début littéral et on
        # le complète par chacune des dix personnes.
        interpole = re.search(r"dossier:\s*'([^'$]*)\$", bloc)
        if litteral:
            noms = [litteral.group(1)]
        elif aide:
            # `d(nom)` construit 'balcon/$heure/nom' : les deux heures.
            noms = [f'balcon/{h}/{aide.group(1)}' for h in ('jour', 'nuit')]
        elif interpole:
            noms = [interpole.group(1) + qui for qui in chambres()]
        else:
            sys.exit('decor.dart : dossier illisible dans ' + bloc.strip()[:60])
        if retour:
            dedans.update(noms)
    return dedans


def chambres():
    src = open(os.path.join(RACINE, 'lib/moteur/decor.dart')).read()
    bloc = re.search(r'_chambresPartagees\s*=\s*\{(.*?)\}', src, re.S).group(1)
    return re.findall(r"'([^']+)'", bloc)


def combien(dossier):
    """Les images livrées pour cet état, telles qu'elles sont sur le disque."""
    plein = os.path.join(PLAQUES, dossier)
    if os.path.isdir(plein):
        return len([f for f in os.listdir(plein) if f.endswith('.jpg')])
    return 1 if os.path.exists(plein + '.jpg') else 0


def sequence(dossier, n, retour):
    """L'ordre de lecture, exactement celui du jeu : en rond, ou en
    aller-retour quand les images viennent d'un plan filmé."""
    if n <= 1:
        return [dossier + '.jpg']
    cles = list(range(1, n + 1))
    if retour:
        cles += list(range(n - 1, 1, -1))
    return [f'{dossier}/k{k}.jpg' for k in cles]


def reduis(dossier_sortie, chemins):
    for rel in chemins:
        src = os.path.join(PLAQUES, rel)
        dst = os.path.join(dossier_sortie, rel)
        if os.path.exists(dst):
            continue
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        subprocess.run(
            ['ffmpeg', '-loglevel', 'error', '-y', '-i', src,
             '-vf', f'scale={LARGEUR}:-2', '-q:v', '4', dst],
            check=True)


def echappe(s):
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
             .replace('"', '&quot;'))


def fiche(num, e):
    images = ''.join(
        f'<img src="{src}" alt="{echappe(e["nom"])} {i + 1}" loading="lazy" '
        f'style="opacity:{1 if i == 0 else 0}">'
        for i, src in enumerate(e['sequence']))
    n = e['n']
    compte = '1 image' if n == 1 else f'{n} images' + (' ↔' if e['retour'] else '')
    # La scène du lit est la seule plaque en portrait : elle remplit
    # l'écran du téléphone au lieu d'en occuper un tiers.
    classe = 'fiche portrait' if e.get('portrait') else 'fiche'
    avert = f'<div class="avert">{echappe(e["note"])}</div>' if e.get('note') else ''
    return f'''    <article class="{classe}">
      <div class="cadre"><span class="num">{num:02d}</span><span class="compte-img">{compte}</span>{images}</div>
      <div class="bas">
        <div class="nom">{echappe(e['nom'])}</div>
        <div class="cond">{echappe(e['cond'])}</div>
        {avert}
      </div>
    </article>'''


def taille(rel):
    r = subprocess.run(
        ['ffprobe', '-v', 'error', '-select_streams', 'v',
         '-show_entries', 'stream=width,height', '-of', 'csv=p=0',
         os.path.join(PLAQUES, rel)],
        capture_output=True, text=True, check=True)
    w, h = r.stdout.strip().split(',')[:2]
    return f'{w} × {h}'


def formats(etats):
    """Le pied de page dit la vérité sur les définitions livrées, parce que
    c'est justement ce qui a été refait deux fois."""
    par_taille = {}
    for e in etats:
        # « Le balcon, de jour » et « de nuit » sont un seul lieu ici.
        lieu = e['piece'].split(',')[0]
        par_taille.setdefault(taille(e['sequence'][0]), set()).add(lieu)
    morceaux = []
    for t, lieux in sorted(par_taille.items(), key=lambda kv: -len(kv[1])):
        ordonnes = [l.split(',')[0].lower() for l in ORDRE if l.split(',')[0] in lieux]
        morceaux.append(f'{t} pour ' + ', '.join(dict.fromkeys(ordonnes)))
    return 'Définitions livrées : ' + ' ; '.join(morceaux) + '.'


def version():
    for ligne in open(os.path.join(RACINE, 'pubspec.yaml')):
        if ligne.startswith('version:'):
            return ligne.split(':', 1)[1].strip().split('+')[0]
    return '?'


def main():
    sortie = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RACINE, 'sources/planche')
    os.makedirs(sortie, exist_ok=True)
    retours = allers_retours()
    etats = json.load(open(PROSE))

    manquants = []
    for e in etats:
        e['n'] = combien(e['dossier'])
        if e['n'] == 0:
            manquants.append(e['dossier'])
        e['retour'] = e['dossier'] in retours
        e['sequence'] = sequence(e['dossier'], e['n'], e['retour'])
    if manquants:
        sys.exit('plaques absentes : ' + ', '.join(manquants))

    reduis(sortie, [s for e in etats for s in e['sequence']])

    total = sum(e['n'] for e in etats)
    corps = []
    # Les numéros suivent la page, pas le fichier : c'est par eux qu'on
    # valide un état à voix haute, ils doivent se lire de haut en bas.
    # Le rendez-vous, ajouté en fin de fichier mais affiché au milieu,
    # portait les numéros 43 à 52 au beau milieu des trentièmes.
    numero = 0
    for piece in ORDRE:
        dedans = [e for e in etats if e['piece'] == piece]
        if not dedans:
            continue
        n = sum(e['n'] for e in dedans)
        corps.append(
            f'  <div class="titre-piece"><h2>{echappe(piece)}</h2>'
            f'<span class="combien">{len(dedans)} états · {n} images</span></div>\n'
            '  <div class="grille">')
        for e in dedans:
            numero += 1
            corps.append(fiche(numero, e))
        corps.append('  </div>')

    gabarit = open(os.path.join(RACINE, 'outils/planche_palais.html')).read()
    page = (gabarit
            .replace('{{VERSION}}', version())
            .replace('{{ETATS}}', str(len(etats)))
            .replace('{{IMAGES}}', str(total))
            .replace('{{FORMATS}}', echappe(formats(etats)))
            .replace('{{CORPS}}', '\n'.join(corps)))
    chemin = os.path.join(sortie, 'palais.html')
    open(chemin, 'w').write(page)
    print(f'{chemin} — {len(etats)} états, {total} images')


if __name__ == '__main__':
    main()
