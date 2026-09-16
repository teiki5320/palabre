"""Fusionne les lots de cartes écrits dans .tmp/lots/ avec le contenu du jeu.

Refuse un lot qui ferait doublon d'identifiant, et laisse le contrôle du
dépôt (flutter test test/contenu/) juger le reste : il est plus sévère que
les scripts des rédacteurs.
"""
import json
import pathlib
import sys

racine = pathlib.Path(__file__).resolve().parent.parent
cartes_json = racine / 'assets/contenu/cartes.json'
lots = sorted((racine / '.tmp/lots').glob('lot-*.json'))

cartes = json.loads(cartes_json.read_text())
connus = {c['id'] for c in cartes}
ajoutees = 0

for lot in lots:
    nouvelles = json.loads(lot.read_text())
    doublons = [c['id'] for c in nouvelles if c['id'] in connus]
    if doublons:
        sys.exit(f"{lot.name} : identifiants deja pris — {', '.join(doublons)}")
    interne = [c['id'] for c in nouvelles]
    if len(set(interne)) != len(interne):
        sys.exit(f"{lot.name} : doublons internes")
    cartes += nouvelles
    connus |= set(interne)
    ajoutees += len(nouvelles)
    print(f"{lot.name} : {len(nouvelles)} cartes")

cartes_json.write_text(
    '[\n' + ',\n'.join('  ' + json.dumps(c, ensure_ascii=False) for c in cartes) + '\n]\n'
)
print(f"{ajoutees} cartes ajoutees, {len(cartes)} en tout")
