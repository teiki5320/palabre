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
         f'colorkey={couleur}:0.18:0.03,split[c][a];'
         '[c]despill=type=green:mix=0.5:expand=0[cc];'
         # L'alpha est binarisé, puis fermé — une dilatation suivie d'une
         # érosion — pour boucher les trous que le vert a percés dans les
         # vêtements, avant d'être refeutré d'un pixel sur le bord.
         "[a]format=rgba,alphaextract,format=gray,lut=y='if(gt(val,128),255,0)',"
         'dilation,dilation,dilation,dilation,'
         'erosion,erosion,erosion,erosion,boxblur=1:1[m];'
         '[cc][m]alphamerge',
         '-frames:v', '1', '-update', '1', sortie],
        check=True)


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
