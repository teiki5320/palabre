#!/usr/bin/env python3
"""Incruste les quatre poses d'une planche sur fond vert dans la chambre.

    python3 outils/incruste_chambre.py <planche.png> <plaque.png> <sortie/>

La planche fait quatre poses côte à côte, sur un vert qui n'est jamais tout
à fait le même d'une planche à l'autre ni d'un bord à l'autre : on le
relève donc pose par pose, dans un coin, au lieu d'en coder un en dur.

Le fond part au `colorkey`, qui compare en RVB, et jamais au `chromakey`,
qui ne regarde que la chrominance : un cheveu noir ou un jean sombre n'en
ont presque pas, il les juge donc aussi verts que le fond et les efface à
moitié. C'est ce qui rendait la militante et la cheffe du protocole
transparentes — on voyait la penderie à travers elles.

L'alpha est ensuite binarisé, puis fermé, puis refeutré d'un pixel : pas
de demi-transparence du tout, et les trous que le vert perce dans un
vêtement se rebouchent.

Une robe verte, elle, ne se rattrape pas : le tour s'arrête et demande une
autre planche.
"""

import os
import subprocess
import sys

POSES = 4
# Le cadrage d'origine, mesuré sur les plaques déjà livrées : la personne
# fait 928 pixels de haut, les pieds posés à 1397, au milieu de la pièce.
HAUTEUR = 928
SOL = 1397
MILIEU = 1285


def dimensions(chemin):
    r = subprocess.run(
        ['ffprobe', '-v', 'error', '-select_streams', 'v',
         '-show_entries', 'stream=width,height', '-of', 'csv=p=0', chemin],
        capture_output=True, text=True, check=True)
    w, h = r.stdout.strip().split(',')[:2]
    return int(w), int(h)


def vert(planche, x, y):
    """La couleur du fond, relevée sur un carré de vingt pixels."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', planche,
         '-vf', f'crop=20:20:{x}:{y},scale=1:1', '-f', 'rawvideo',
         '-pix_fmt', 'rgb24', '-'], capture_output=True).stdout
    return '0x%02X%02X%02X' % tuple(raw[:3])


def detoure(planche, panneau, i, couleur, sortie):
    """Une pose détourée, alpha durci, en PNG."""
    largeur, hauteur = panneau
    subprocess.run(
        ['ffmpeg', '-v', 'error', '-y', '-i', planche, '-filter_complex',
         f'crop={largeur}:{hauteur}:{i * largeur}:0,format=rgba,'
         # `colorkey` compare en RVB. `chromakey`, qui travaille en YUV,
         # ne regarde que la chrominance : un cheveu noir ou un jean sombre
         # n'ont presque pas de chrominance, il les trouve donc aussi
         # proches du vert que le fond lui-même et les efface. C'est ce
         # qui rendait les gens transparents.
         f'colorkey={couleur}:0.18:0.03,'
         # Le fond n'est pas d'un vert unique : sous la personne il passe
         # à l'ombre, et le `colorkey`, qui mesure une distance à une seule
         # couleur, ne l'y reconnaît plus. Il le laissait opaque, et le
         # dévert le retournait en bleu marine — la cheffe du protocole
         # avait une flaque bleue à ses pieds. Est aussi du fond tout ce
         # dont le vert domine franchement les deux autres canaux : une
         # peau, un jean, un satin ivoire n'en sont jamais là.
         "geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':"
         "a='if(gt(g(X,Y),50)*gt(g(X,Y),1.25*r(X,Y))*gt(g(X,Y),1.25*b(X,Y)),"
         "0,alpha(X,Y))',"
         'split[c][a];'
         '[c]despill=type=green:mix=0.5:expand=0[cc];'
         # L'alpha est binarisé, puis fermé — une dilatation suivie d'une
         # érosion — pour boucher les trous que le vert a percés dans les
         # vêtements, avant d'être refeutré d'un pixel sur le bord.
         "[a]format=rgba,alphaextract,format=gray,lut=y='if(gt(val,128),255,0)',"
         'dilation,dilation,dilation,dilation,'
         'erosion,erosion,erosion,erosion,'
         # Puis une ouverture, qui fait l'inverse : elle rogne les
         # filaments que le vert a laissés pendre au bord d'un vêtement —
         # la militante gardait des fils de jean accrochés à sa manche —
         # sans entamer un corps, bien plus large que trois pixels.
         'erosion,erosion,erosion,'
         'dilation,dilation,dilation,boxblur=1:1[m];'
         '[cc][m]alphamerge',
         '-frames:v', '1', '-update', '1', sortie],
        check=True)


def _alpha(png, w, h):
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', png, '-vf', 'alphaextract',
         '-f', 'rawvideo', '-pix_fmt', 'gray', '-'],
        capture_output=True).stdout
    if len(raw) < w * h:
        sys.exit(f'{png} : alpha illisible')
    return bytearray(raw[:w * h])


def _composantes(op, w, h, cherchee):
    """Les paquets de pixels qui se touchent, du plus gros au plus petit."""
    vu = bytearray(w * h)
    paquets = []
    for depart in range(w * h):
        if vu[depart] or op[depart] != cherchee:
            continue
        pile, paquet = [depart], []
        vu[depart] = 1
        while pile:
            i = pile.pop()
            paquet.append(i)
            x, y = i % w, i // w
            if x and not vu[i - 1] and op[i - 1] == cherchee:
                vu[i - 1] = 1; pile.append(i - 1)
            if x + 1 < w and not vu[i + 1] and op[i + 1] == cherchee:
                vu[i + 1] = 1; pile.append(i + 1)
            if y and not vu[i - w] and op[i - w] == cherchee:
                vu[i - w] = 1; pile.append(i - w)
            if y + 1 < h and not vu[i + w] and op[i + w] == cherchee:
                vu[i + w] = 1; pile.append(i + w)
        paquets.append(paquet)
    paquets.sort(key=len, reverse=True)
    return paquets


def recoud(png):
    """Rend à la découpe ce que le vert lui a pris.

    Le `colorkey` compare des couleurs une à une, sans savoir ce qu'il
    découpe : un jean éclairé passe à moins de deux dixièmes du vert du
    fond, et il en perce des plaques entières — la militante avait la
    penderie au travers de sa chemise, et un morceau de cette chemise
    traînait tout seul sur le tapis. La fermeture morphologique ne rebouche
    que les petits trous ; celui-là faisait deux cents pixels.

    Deux règles suffisent, et elles ne regardent plus les couleurs :
    une personne est d'un seul tenant — donc on jette les morceaux
    détachés ; et une personne n'a pas de fenêtres — donc tout trou qui
    ne communique pas avec le bord se rebouche.
    """
    w, h = dimensions(png)
    a = _alpha(png, w, h)
    op = bytearray(1 if v > 127 else 0 for v in a)

    morceaux = _composantes(op, w, h, 1)
    if not morceaux:
        sys.exit(f'{png} : rien à détourer — le fond a tout mangé')
    jetes = sum(len(m) for m in morceaux[1:])
    for m in morceaux[1:]:
        for i in m:
            op[i] = 0

    bouches = 0
    for trou in _composantes(op, w, h, 0):
        x = trou[0] % w
        y = trou[0] // w
        # Un paquet transparent qui touche le bord, c'est le fond.
        if any(p % w in (0, w - 1) or p // w in (0, h - 1) for p in trou):
            continue
        bouches += len(trou)
        for i in trou:
            op[i] = 1

    if not jetes and not bouches:
        return 0, 0
    brut = png + '.alpha'
    open(brut, 'wb').write(bytes(255 if v else 0 for v in op))
    recousu = png + '.recousu.png'
    subprocess.run(
        ['ffmpeg', '-v', 'error', '-y', '-i', png,
         '-f', 'rawvideo', '-pix_fmt', 'gray', '-s', f'{w}x{h}', '-i', brut,
         '-filter_complex', '[0]format=rgba[c];[1]format=gray,boxblur=1:1[m];'
         '[c][m]alphamerge', '-frames:v', '1', '-update', '1', recousu],
        check=True)
    os.replace(recousu, png)
    os.remove(brut)
    return jetes, bouches


def boite(png):
    """Le rectangle occupé par la personne, lu dans l'alpha."""
    w, h = dimensions(png)
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', png, '-vf', 'alphaextract',
         '-f', 'rawvideo', '-pix_fmt', 'gray', '-'],
        capture_output=True).stdout
    x1, y1, x2, y2 = w, h, -1, -1
    for y in range(h):
        ligne = raw[y * w:(y + 1) * w]
        i = next((k for k in range(w) if ligne[k] > 200), -1)
        if i < 0:
            continue
        j = next((k for k in range(w - 1, -1, -1) if ligne[k] > 200), i)
        x1, x2 = min(x1, i), max(x2, j)
        y1, y2 = min(y1, y), max(y2, y)
    if x2 < 0:
        sys.exit(f'{png} : rien à détourer — le fond a tout mangé')
    return x1, y1, x2 - x1 + 1, y2 - y1 + 1


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    planche, plaque, sortie = sys.argv[1:4]
    os.makedirs(sortie, exist_ok=True)
    pw, ph = dimensions(planche)
    panneau = (pw // POSES, ph)
    pl_w, pl_h = dimensions(plaque)

    for i in range(POSES):
        decoupe = os.path.join(sortie, f'_pose{i + 1}.png')
        # Le vert se relève en haut à gauche du panneau, loin de la personne.
        couleur = vert(planche, i * panneau[0] + 20, 20)
        detoure(planche, panneau, i, couleur, decoupe)
        jetes, bouches = recoud(decoupe)
        if jetes or bouches:
            print(f'  k{i + 1}  recousu : {jetes} pixels détachés jetés, '
                  f'{bouches} rebouchés')
        bx, by, bw, bh = boite(decoupe)
        if bh < ph * 0.5:
            sys.exit(f'{planche} pose {i + 1} : la découpe ne fait que {bh} '
                     'pixels de haut — un vêtement de la couleur du fond a '
                     'été mangé, il faut refaire la planche.')
        echelle = HAUTEUR / bh
        large = round(bw * echelle)
        # On garde le décalage de la pose par rapport au centre du panneau :
        # c'est lui qui fait qu'elle avance vers nous d'une image à l'autre.
        centre = bx + bw / 2 - panneau[0] / 2
        x = round(MILIEU + centre * echelle - large / 2)
        y = SOL - HAUTEUR
        cle = os.path.join(sortie, f'k{i + 1}.jpg')
        subprocess.run(
            ['ffmpeg', '-v', 'error', '-y', '-i', plaque, '-i', decoupe,
             '-filter_complex',
             f'[1]crop={bw}:{bh}:{bx}:{by},scale={large}:{HAUTEUR}[p];'
             f'[0][p]overlay={x}:{y}',
             '-q:v', '4', '-frames:v', '1', '-update', '1', cle],
            check=True)
        os.remove(decoupe)
        print(f'  k{i + 1}  découpe {bw}×{bh} → {large}×{HAUTEUR} en {x},{y}')

    print(f'{sortie} — quatre clés sur {pl_w}×{pl_h}')


if __name__ == '__main__':
    main()
