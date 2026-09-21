#!/usr/bin/env python3
"""Écrit « Ce qui se dit dans la chambre », à partir des répliques et des images.

    python3 outils/planche_chambre.py <fichier.html>

Trois appuis, trois images, une réplique sur chacune — et deux fois, parce
que la même personne ne parle pas pareil quand c'est caché et quand c'est
légal. Les textes viennent de `chambre.json`, les images des dossiers du
palais, les libellés du bas de `palais_ecran.dart`. Rien n'est écrit à la
main ici.
"""

import json
import os
import re
import shutil
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PALAIS = os.path.join(RACINE, 'assets/images/palais/pieces')

# Ceux dont la chambre se raconte au masculin, et qu'une présidente
# courtise. Le jeu ne porte pas le genre de ses personnages — seule
# cette page a besoin de l'accord.
HOMMES = {'international', 'ministre', 'renseignements', 'maire', 'epoux'}

# Les trois temps de la scène, dans l'ordre des appuis. Pour chacun :
# l'image que l'écran montre, et ce que la page en dit.
TEMPS = [
    ('habille', 'chambre_conjoint/{qui}/k1.jpg',
     "{Elle} apparaît {habillee}, debout au pied du lit."),
    ('deshabille', 'chambre_conjoint/{qui}/k4.jpg',
     "Un appui : quatre poses, et {elle} ne se rhabille pas."),
    ('lit', 'chambre_lit/{qui}/k1.jpg',
     'Un second appui : la boucle du lit, en plein écran.'),
]

SITUATIONS = [
    ('liaison', "Tant que c'est caché",
     "Personne ne sait, et ce qui {la} préoccupe est d'être {entree} sans "
     "qu'on {la} voie."),
    ('marie', 'Une fois mariés',
     "Plus de porte dérobée : ce qui reste, c'est la journée qu'ils "
     'viennent de passer chacun de leur côté.'),
]


# Le registre ne se décrète pas : il se lit dans les répliques. Tout le
# monde ne vouvoie pas tant que c'est caché — la militante ne le ferait
# jamais — et prétendre le contraire sur la planche ferait juger les
# textes sur une règle qu'ils ne suivent pas.
TU = re.compile(r"\b(tu|te|toi|ton|ta|tes)\b|\bt'", re.I)
VOUS = re.compile(r'\b(vous|votre|vos)\b', re.I)
# Un impératif de politesse en tête de phrase : « Dormez. », « Éteignez, »
IMPERATIF = re.compile(r'(?:^|[.!?…]\s+)([A-ZÉÈÀ][a-zà-ÿ]*ez)\b')


def registre(lignes):
    texte = ' '.join(lignes.values())
    vous = bool(VOUS.search(texte)) or bool(IMPERATIF.search(texte))
    tu = bool(TU.search(texte))
    if vous and not tu:
        return 'vouvoiement'
    if tu and not vous:
        return 'tutoiement'
    return None


# Quand aucune des trois répliques ne porte de pronom, on se tait : la
# planche préfère ne rien dire à trancher de travers.
DITS_DU_REGISTRE = {
    'vouvoiement': '{Elle} vouvoie encore.',
    'tutoiement': '{Elle} tutoie déjà.',
    None: '',
}


def invites():
    """Les trois libellés du bas, lus dans l'écran plutôt que recopiés."""
    src = open(os.path.join(RACINE, 'lib/ecrans/palais_ecran.dart')).read()
    bloc = re.search(r'String\?\s+get\s+_invite\s*=>\s*switch\s*\(_temps\)\s*\{(.*?)\};',
                     src, re.S)
    if bloc is None:
        sys.exit('palais_ecran.dart : les libellés du rendez-vous sont introuvables')
    trouve = dict(re.findall(r"_Temps\.(\w+)\s*=>[^,]*?'([^']+)'", bloc.group(1)))
    if set(trouve) != {'habille', 'deshabille', 'lit'}:
        sys.exit(f'palais_ecran.dart : libellés incomplets {sorted(trouve)}')
    return trouve


def accorde(texte, homme):
    """La page parle d'eux ; le jeu, lui, ne connaît pas leur genre."""
    mots = {'Elle': 'Il', 'elle': 'il', 'la': 'le', 'habillee': 'habillé',
            'entree': 'entré', 'vue': 'vu'} if homme else {
            'Elle': 'Elle', 'elle': 'elle', 'la': 'la', 'habillee': 'habillée',
            'entree': 'entrée', 'vue': 'vue'}
    for k, v in mots.items():
        texte = texte.replace('{' + k + '}', v)
    return texte


def habille(texte, homme):
    """Le texte tel que le joueur le lit. Une romance ne s'ouvre qu'aux
    parcours du sexe opposé : les cinq hommes sont courtisés par une
    présidente, les cinq femmes par un président."""
    titre = 'Madame la Présidente' if homme else 'Monsieur le Président'
    nom = 'Awa' if homme else 'Idriss'
    return texte.replace('{titre}', titre).replace('{nom}', nom)


def echappe(s):
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
             .replace('"', '&quot;'))


def version():
    for ligne in open(os.path.join(RACINE, 'pubspec.yaml')):
        if ligne.startswith('version:'):
            return ligne.split(':', 1)[1].strip().split('+')[0]
    return '?'


def rassemble(sortie):
    """Copie les images dont la page a besoin à côté d'elle, et rend le
    chemin de chacune. Une image manquante arrête tout : mieux vaut pas
    de planche qu'une planche trouée."""
    dossier = os.path.dirname(sortie)
    chemins = {}
    for qui in dits():
        os.makedirs(os.path.join(dossier, 'scene'), exist_ok=True)
        os.makedirs(os.path.join(dossier, 'visages'), exist_ok=True)
        for temps, motif, _ in TEMPS:
            source = os.path.join(PALAIS, motif.format(qui=qui))
            if not os.path.exists(source):
                sys.exit(f'image absente : {source}')
            cible = f'scene/{qui}_{temps}.jpg'
            shutil.copyfile(source, os.path.join(dossier, cible))
            chemins[(qui, temps)] = cible
        visage = os.path.join(RACINE, 'assets/images/personnages', f'{qui}_neutre.jpg')
        if not os.path.exists(visage):
            sys.exit(f'portrait absent : {visage}')
        shutil.copyfile(visage, os.path.join(dossier, f'visages/{qui}.jpg'))
    return chemins


_dits = None


def dits():
    global _dits
    if _dits is None:
        _dits = json.load(open(os.path.join(RACINE, 'assets/contenu/chambre.json')))
        for qui, jeux in _dits.items():
            if set(jeux) != {'liaison', 'marie'}:
                sys.exit(f'{qui} : il manque une situation')
            for sit, lignes in jeux.items():
                if set(lignes) != {t for t, _, _ in TEMPS}:
                    sys.exit(f'{qui}/{sit} : il manque une réplique')
    return _dits


def ecran(qui, temps, ligne, n, chemins, libelles, homme):
    """L'écran tel que le joueur le voit : l'image qui remplit le
    téléphone, ce qui se dit en bas, et l'invitation à toucher."""
    _, _, dit = next(t for t in TEMPS if t[0] == temps)
    return f'''      <figure class="ecran">
        <div class="tel">
          <img src="{chemins[(qui, temps)]}" alt="">
          <span class="numero">{n}</span>
          <div class="bas">
            <p class="replique">{echappe(habille(ligne, homme))}</p>
            <p class="invite">{echappe(libelles[temps].upper())}</p>
          </div>
        </div>
        <figcaption>{echappe(accorde(dit, homme))}</figcaption>
      </figure>'''


def section(qui, gens, chemins, libelles, suivant):
    homme = qui in HOMMES
    p = gens[qui]
    blocs = []
    for sit, titre, note in SITUATIONS:
        lignes = dits()[qui][sit]
        ecrans = ''.join(ecran(qui, t, lignes[t], suivant(), chemins, libelles, homme)
                         for t, _, _ in TEMPS)
        dit = DITS_DU_REGISTRE[registre(lignes)]
        blocs.append(f'''    <p class="acte">{echappe(titre)}</p>
    <p class="note">{echappe(accorde(note, homme))}{' ' + echappe(accorde(dit, homme)) if dit else ''}</p>
    <div class="scene">
{ecrans}
    </div>''')
    courtise = 'une présidente' if homme else 'un président'
    return f'''  <section class="personne">
    <div class="tete">
      <img src="visages/{qui}.jpg" alt="{echappe(p['nom'])}">
      <div>
        <h2>{echappe(p['nom'])}</h2>
        <p class="titre">{echappe(p.get('titre', ''))} · {courtise} seulement</p>
      </div>
    </div>
{chr(10).join(blocs)}
  </section>'''


GABARIT = '''<title>Ce qui se dit dans la chambre</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,700;12..96,800&family=Public+Sans:wght@0,400;0,600&display=swap">
<style>
  :root{
    --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
    --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38; --nuit:#0E0D12;
    --serif:"Bricolage Grotesque","Trebuchet MS",sans-serif;
    --corps:"Public Sans",system-ui,-apple-system,sans-serif;
  }
  :root[data-theme="light"]{
    --fond:#F3ECE0; --leve:#FFFBF4; --encre:#1B1922; --douce:#544E5F;
    --faible:#8C8595; --or:#A0700F; --trait:#D9CDB8;
  }
  @media (prefers-color-scheme: dark){
    :root:not([data-theme="light"]){
      --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
      --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38;
    }
  }
  :root[data-theme="dark"]{
    --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
    --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38;
  }
  body{background:var(--fond);color:var(--encre);font-family:var(--corps);
    font-size:16px;line-height:1.5}
  .page{max-width:1040px;margin:0 auto;padding:0 20px;padding-block:40px 72px}
  h1,h2{font-family:var(--serif);margin:0;text-wrap:balance}
  h1{font-size:clamp(1.9rem,5.5vw,2.9rem);font-weight:800;line-height:1.02;letter-spacing:-.015em}
  p{margin:0 0 .8em;max-width:64ch}
  .surtitre{font-size:.72rem;letter-spacing:.18em;text-transform:uppercase;
    color:var(--faible);font-weight:600;margin:0 0 12px}
  .chapeau{font-size:1.08rem;color:var(--douce);max-width:58ch;margin-top:14px}
  .note{font-size:.84rem;color:var(--faible);max-width:70ch}

  .personne{border-top:1px solid var(--trait);margin-top:46px;padding-top:26px}
  .tete{display:flex;align-items:center;gap:16px;margin-bottom:8px}
  .tete img{width:60px;height:60px;border-radius:50%;object-fit:cover;
    object-position:center 20%;border:1px solid var(--trait);flex:none}
  .tete h2{font-size:1.4rem;font-weight:700;line-height:1.1}
  .titre{font-size:.82rem;color:var(--faible);margin:2px 0 0}

  .acte{font-family:var(--serif);font-size:1.02rem;font-weight:700;color:var(--or);
    margin:30px 0 4px;letter-spacing:.01em}

  /* Le téléphone : l'image remplit l'écran comme BoxFit.cover le fait,
     la réplique se pose sur le voile, et le libellé du bas est celui
     que le jeu affiche vraiment. */
  .scene{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));
    gap:20px;margin-top:14px}
  .ecran{margin:0}
  .tel{position:relative;aspect-ratio:9/16;border-radius:26px;overflow:hidden;
    background:var(--nuit);box-shadow:0 18px 40px rgba(0,0,0,.45)}
  .tel img{width:100%;height:100%;object-fit:cover;display:block}
  .numero{position:absolute;top:10px;left:10px;z-index:2;font-family:var(--serif);
    font-size:.78rem;font-weight:700;color:var(--nuit);background:var(--or);
    border-radius:3px;padding:2px 7px}
  .bas{position:absolute;inset:auto 0 0 0;padding:70px 18px 18px;text-align:center;
    background:linear-gradient(to top,rgba(14,13,18,.94) 12%,rgba(14,13,18,.72) 46%,transparent)}
  .replique{color:#F6EFE4;font-size:.94rem;line-height:1.35;margin:0 0 14px;
    max-width:none;text-wrap:balance}
  .invite{margin:0;font-size:.62rem;letter-spacing:.14em;color:rgba(246,239,228,.62);
    font-weight:600}
  figcaption{font-size:.8rem;color:var(--faible);margin-top:10px;max-width:34ch}

  footer{border-top:1px solid var(--trait);margin-top:52px;padding-top:20px}
</style>
<div class="page">
  <p class="surtitre">Palabre — Président pour 100 jours · version {{VERSION}}</p>
  <h1>Ce qui se dit dans la chambre</h1>
  <p class="chapeau">Les soixante répliques du rendez-vous, posées sur les
  images de la scène, à l'endroit exact où le joueur les lira. Trois appuis,
  trois phrases — et deux fois, parce que la même personne ne parle pas de la
  même façon quand c'est caché et quand c'est légal.</p>
  <p class="note">Le président ne répond jamais : c'est le joueur, et il n'a
  de réplique nulle part ailleurs dans le jeu. La troisième phrase est courte
  exprès — elle s'affiche pendant que l'image bouge, et une phrase longue à cet
  endroit se lit mal.</p>
  <p class="note">Les images sont celles du jeu, cadrées comme l'écran les
  cadre. Les deux premières viennent des quatre poses debout — la première et
  la dernière ; la troisième est le premier plan de la boucle du lit. Les
  répliques ne changent rien aux images : ce sont les mêmes dans les deux
  situations, seule la façon de parler change.</p>

{{CORPS}}

  <footer><p class="note">{{PIED}}</p></footer>
</div>
'''


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    sortie = args[0] if args else os.path.join(RACINE, 'sources/dits/chambre.html')
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    gens = {p['id']: p for p in
            json.load(open(os.path.join(RACINE, 'assets/contenu/personnages.json')))}
    manque = [q for q in dits() if q not in gens]
    if manque:
        sys.exit(f'personnes inconnues : {manque}')
    chemins = rassemble(sortie)
    libelles = invites()
    compteur = [0]

    def suivant():
        compteur[0] += 1
        return compteur[0]

    corps = '\n'.join(section(q, gens, chemins, libelles, suivant) for q in dits())
    pied = (f'{compteur[0]} répliques, lues dans assets/contenu/chambre.json. '
            'Rien de tout cela n\'est encore branché : la scène se joue '
            'aujourd\'hui sans une parole.')
    page = (GABARIT.replace('{{VERSION}}', version())
            .replace('{{PIED}}', echappe(pied))
            .replace('{{CORPS}}', corps))
    open(sortie, 'w').write(page)
    print(f'{sortie} — {len(dits())} personnes, {compteur[0]} répliques')


if __name__ == '__main__':
    main()
