#!/usr/bin/env python3
"""Relit les 650 cartes et signale ce que le contrôle du jeu ne voit pas.

    python3 outils/audit_cartes.py

`lib/contenu/validation.dart` garde déjà les bornes : longueur des textes,
effets hors limites, réponse qui en domine une autre, jour_min après
jour_max, drapeau exigé que personne ne pose. Ce tour-ci regarde ce qui
demande de croiser plusieurs cartes : les chaînes qui ne peuvent pas
avancer, les gardes qui ne servent à rien, les textes qui se répètent, la
typographie.

Rien n'est corrigé ici : la sortie est une liste à trancher.
"""

import json
import os
import re
import sys
import unicodedata
from collections import Counter, defaultdict

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def charge(nom):
    return json.load(open(os.path.join(RACINE, 'assets/contenu', nom + '.json')))


# Les drapeaux que le moteur pose ou lit lui-même, hors de toute carte.
POSES_PAR_LE_MOTEUR = {'coffre_ouvert', 'noces_vues'} | {
    'rdv_' + q for q in ('redactrice', 'cabinet', 'emissaire', 'militante',
                         'epouse', 'international', 'ministre',
                         'renseignements', 'maire', 'epoux')}
LUS_PAR_LE_MOTEUR = {'fete_nationale', 'deuil_national', 'noces_etat',
                     'noces_discretes', 'noces_vues', 'objet_coffre_fort',
                     'coffre_ouvert'} | {d for d in POSES_PAR_LE_MOTEUR}


# Les objets dont le moteur fait quelque chose sans passer par une carte :
# les quatre véhicules remplissent la cour, le dimanche ouvre la piscine au
# quartier, le coffre-fort renfloue les caisses une fois.
OBJETS_LUS_PAR_LE_MOTEUR = {'velo', 'quatre_quatre', 'motos', 'limousine',
                            'dimanche', 'coffre_fort', 'pompe'}


def sans_accent(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s.lower())
                   if unicodedata.category(c) != 'Mn')


def rangs_de(lot):
    r = defaultdict(list)
    for c in lot:
        r[c['chaine']['rang']].append(c)
    return r


def paires_exclusives(cartes):
    """Les couples de drapeaux qui ne peuvent jamais coexister.

    Le cas courant : une carte pose « cholera_cache » d'un côté et
    « cholera_avoue » de l'autre. Deux cartes qui les exigent séparément
    ne se disputent donc rien, et il ne faut pas les signaler comme deux
    branches en concurrence."""
    ensemble = set()
    poseurs = defaultdict(set)
    for c in cartes:
        for cote in ('gauche', 'droite'):
            for d in c[cote].get('drapeaux', []):
                poseurs[d].add((c['id'], cote))
    for c in cartes:
        g = set(c['gauche'].get('drapeaux', []))
        d = set(c['droite'].get('drapeaux', []))
        for a in g - d:
            for b in d - g:
                # Il faut que les deux drapeaux ne soient posés que par les
                # deux faces de cette carte-là : posé ailleurs, un drapeau
                # peut revenir par une autre porte.
                if (poseurs[a] == {(c['id'], 'gauche')}
                        and poseurs[b] == {(c['id'], 'droite')}):
                    ensemble.add(frozenset((a, b)))
    return ensemble


def etend_les_exclusifs(cartes, ensemble):
    """Deuxième tour : deux drapeaux qu'aucune partie ne peut porter tous
    les deux.

    Le cas simple est déjà traité — les deux faces d'une même carte. Ici on
    prend le cas général : aucune réponse ne pose les deux, et deux cartes
    qui les posent séparément ne peuvent jamais sortir toutes les deux, soit
    parce que c'est la même carte par ses deux faces, soit parce que leurs
    conditions s'excluent."""
    poseurs = defaultdict(set)
    par_id = {c['id']: c for c in cartes}
    for c in cartes:
        for cote in ('gauche', 'droite'):
            for d in c[cote].get('drapeaux', []):
                poseurs[d].add(c['id'])
    noms = sorted(poseurs)
    ajouts = set()
    for i, a in enumerate(noms):
        for b in noms[i + 1:]:
            if frozenset((a, b)) in ensemble:
                continue
            if any(a in c[cote].get('drapeaux', []) and b in c[cote].get('drapeaux', [])
                   for c in cartes for cote in ('gauche', 'droite')):
                continue
            if all(x == y or conditions_exclusives(par_id[x], par_id[y], ensemble)
                   for x in poseurs[a] for y in poseurs[b]):
                ajouts.add(frozenset((a, b)))
    return ensemble | ajouts


def conditions_exclusives(a, b, exclusifs=frozenset()):
    """Vrai quand deux cartes du même cran ne peuvent jamais sortir en même
    temps. Sert à repérer un cran dont aucune branche ne couvre un cas."""
    ca, cb = a.get('conditions', {}), b.get('conditions', {})
    for cle in ('peuple', 'armee', 'caisses', 'presse', 'style', 'attache'):
        amin, amax = ca.get(cle + '_min'), ca.get(cle + '_max')
        bmin, bmax = cb.get(cle + '_min'), cb.get(cle + '_max')
        if amin is not None and bmax is not None and amin > bmax:
            return True
        if bmin is not None and amax is not None and bmin > amax:
            return True
    if set(ca.get('drapeaux_requis', [])) & set(cb.get('drapeaux_interdits', [])):
        return True
    if set(cb.get('drapeaux_requis', [])) & set(ca.get('drapeaux_interdits', [])):
        return True
    for x in ca.get('drapeaux_requis', []):
        for y in cb.get('drapeaux_requis', []):
            if frozenset((x, y)) in exclusifs:
                return True
    if ca.get('marie') is not None and cb.get('marie') is not None \
            and ca['marie'] != cb['marie']:
        return True
    pa, pb = set(ca.get('parcours', [])), set(cb.get('parcours', []))
    if pa and pb and not (pa & pb):
        return True
    return False


def audit():
    cartes = charge('cartes')
    gens = {p['id']: p for p in charge('personnages')}
    parcours = {p['id']: p for p in charge('parcours')}
    adversaires = {a['id'] for a in charge('adversaires')}
    objets = {o['id'] for o in charge('objets')}
    par_id = {c['id']: c for c in cartes}
    exclusifs = paires_exclusives(cartes)
    exclusifs = etend_les_exclusifs(cartes, exclusifs)
    trouvailles = defaultdict(list)

    def note(famille, texte):
        trouvailles[famille].append(texte)

    # ── les drapeaux ───────────────────────────────────────────────────
    pose, exige, interdit = defaultdict(list), defaultdict(list), defaultdict(list)
    for c in cartes:
        for cote in ('gauche', 'droite'):
            for d in c[cote].get('drapeaux', []):
                pose[d].append(c['id'])
        cond = c.get('conditions', {})
        for d in cond.get('drapeaux_requis', []):
            exige[d].append(c['id'])
        for d in cond.get('drapeaux_interdits', []):
            interdit[d].append(c['id'])
    # Acheter un objet pose son drapeau : c'est le moteur qui le fait, pas
    # une réponse. Sans ça, toute carte ouverte par un achat passerait pour
    # une carte morte.
    poses = set(pose) | POSES_PAR_LE_MOTEUR | {'objet_' + o for o in objets}

    for d in sorted(set(interdit) - poses):
        note('drapeaux', f'« {d} » : personne ne le pose, mais '
                         f'{len(interdit[d])} carte(s) s\'en protègent — '
                         f'la garde ne joue jamais ({", ".join(interdit[d])})')
    for d in sorted(set(exige) - poses):
        note('drapeaux', f'« {d} » : personne ne le pose, et '
                         f'{len(exige[d])} carte(s) l\'exigent — elles ne '
                         f'sortiront jamais ({", ".join(exige[d])})')
    for d in sorted(set(pose) - set(exige) - set(interdit) - LUS_PAR_LE_MOTEUR):
        note('drapeaux', f'« {d} » : posé par {", ".join(pose[d])}, lu par personne')

    # Deux drapeaux presque identiques : une faute de frappe rend la carte
    # muette sans que rien ne s'en plaigne.
    noms = sorted(set(pose) | set(exige) | set(interdit))
    for i, a in enumerate(noms):
        for b in noms[i + 1:]:
            if a != b and sans_accent(a).replace('_', '') == sans_accent(b).replace('_', ''):
                note('drapeaux', f'« {a} » et « {b} » ne diffèrent que par la casse '
                                 'ou les tirets bas')

    # ── les chaînes ────────────────────────────────────────────────────
    chaines = defaultdict(list)
    for c in cartes:
        if c.get('chaine'):
            chaines[c['chaine']['id']].append(c)

    for nom, lot in sorted(chaines.items()):
        rangs = rangs_de(lot)
        creux = [r for r in range(1, max(rangs) + 1) if r not in rangs]
        if creux:
            note('chaines', f'{nom} : crans absents {creux} — la suite s\'arrête là')
        for r in sorted(rangs):
            if r == 1:
                continue
            if not any(c['chaine'].get('delai_min') for c in rangs[r]):
                note('chaines', f'{nom} cran {r} : sans délai, il peut tomber '
                                'le lendemain du précédent')
            # Un cran dont toutes les branches s'excluent deux à deux et
            # portent une condition laisse un cas sans carte : la chaîne
            # s'arrête sans que rien ne le dise.
            branches = rangs[r]
            if len(branches) > 1:
                paires = [(a, b) for i, a in enumerate(branches) for b in branches[i + 1:]]
                if all(conditions_exclusives(a, b, exclusifs) for a, b in paires):
                    continue
                note('chaines', f'{nom} cran {r} : {len(branches)} branches dont '
                                'certaines peuvent sortir dans le même cas — le '
                                'tirage choisira au hasard')
        # Un cran qui exige un drapeau qu'aucun cran précédent ne pose, et
        # que rien d'autre ne pose non plus, ne sortira jamais.
        poses_avant = defaultdict(set)
        vus = set()
        for r in sorted(rangs):
            for c in rangs[r]:
                for d in c.get('conditions', {}).get('drapeaux_requis', []):
                    if d in vus or d in POSES_PAR_LE_MOTEUR:
                        continue
                    dehors = [x for x in pose.get(d, []) if x not in {y['id'] for y in lot}]
                    if not dehors:
                        note('chaines', f'{nom} cran {r} ({c["id"]}) exige « {d} » '
                                        'qu\'aucun cran précédent ne pose')
            for c in rangs[r]:
                for cote in ('gauche', 'droite'):
                    vus.update(c[cote].get('drapeaux', []))
        del poses_avant

    # ── les conditions ─────────────────────────────────────────────────
    for c in cartes:
        cond = c.get('conditions', {})
        ou = c['id']
        croise = set(cond.get('drapeaux_requis', [])) & set(cond.get('drapeaux_interdits', []))
        if croise:
            note('conditions', f'{ou} : exige et interdit à la fois {sorted(croise)}')
        croise = set(cond.get('parcours', [])) & set(cond.get('parcours_interdits', []))
        if croise:
            note('conditions', f'{ou} : parcours à la fois requis et interdit {sorted(croise)}')
        for p in cond.get('parcours', []) + cond.get('parcours_interdits', []):
            if p not in parcours:
                note('conditions', f'{ou} : parcours inconnu « {p} »')
        for a in cond.get('adversaire', []):
            if a not in adversaires:
                note('conditions', f'{ou} : adversaire inconnu « {a} »')
        for cle in ('attache', 'loyaute', 'force'):
            bas, haut = cond.get(cle + '_min'), cond.get(cle + '_max')
            if bas is not None and haut is not None and bas > haut:
                note('conditions', f'{ou} : {cle} entre {bas} et {haut}, impossible')
        for qui in (cond.get('attache_de'), cond.get('loyaute_de')):
            if qui and qui not in gens:
                note('conditions', f'{ou} : vise « {qui} », qui n\'est pas un personnage')
        if cond.get('marie') is True and cond.get('attache_max') == 0:
            note('conditions', f'{ou} : marié et attache nulle, impossible')

    # ── l'écriture ─────────────────────────────────────────────────────
    textes = Counter(c['texte'] for c in cartes)
    for t, n in textes.items():
        if n > 1:
            qui = [c['id'] for c in cartes if c['texte'] == t]
            note('ecriture', f'texte identique sur {n} cartes : {", ".join(qui)}')
    debuts = defaultdict(list)
    for c in cartes:
        debuts[sans_accent(c['texte'])[:45]].append(c['id'])
    for d, ids in debuts.items():
        if len(ids) > 1 and textes[par_id[ids[0]]['texte']] == 1:
            note('ecriture', f'même début de phrase : {", ".join(ids)}')

    journaux = Counter(c[cote]['journal'] for c in cartes for cote in ('gauche', 'droite'))
    for t, n in journaux.items():
        if n > 1:
            note('ecriture', f'lendemain identique à {n} endroits : « {t[:60]}… »')

    for c in cartes:
        ou = c['id']
        if c['gauche']['libelle'].strip().lower() == c['droite']['libelle'].strip().lower():
            note('ecriture', f'{ou} : les deux libellés sont les mêmes')
        for champ, t in [('texte', c['texte'])] + [
                (cote + '/journal', c[cote]['journal']) for cote in ('gauche', 'droite')]:
            if '  ' in t:
                note('typographie', f'{ou} · {champ} : deux espaces à la suite')
            if '...' in t:
                note('typographie', f'{ou} · {champ} : trois points au lieu de « … »')
            if re.search(r'\s[,.]', t):
                note('typographie', f'{ou} · {champ} : espace avant une virgule ou un point')
            if re.search(r'[a-zàâäéèêëîïôöùûüç][!?;:]', t):
                note('typographie', f'{ou} · {champ} : pas d\'espace avant « {re.search(chr(91) + "!?;:" + chr(93), t).group()} »')
            if '"' in t:
                note('typographie', f'{ou} · {champ} : guillemets droits')
            if re.search(r"\w'\w", t.replace('’', "'")) and '’' in t:
                note('typographie', f'{ou} · {champ} : apostrophes mélangées')
            if t and not t.rstrip().endswith(('.', '!', '?', '…', '»')):
                note('typographie', f'{ou} · {champ} : ne finit pas par une ponctuation')
        for marque in re.findall(r'\{(\w+)\}', c['texte']):
            if marque not in ('titre', 'nom'):
                note('ecriture', f'{ou} : marque inconnue « {{{marque}}} »')
        if not c['gauche'].get('journal') or not c['droite'].get('journal'):
            note('ecriture', f'{ou} : une réponse sans lendemain')

    # ── l'équilibre ────────────────────────────────────────────────────
    for c in cartes:
        g, d = c['gauche'], c['droite']
        if g.get('effets') == d.get('effets') and g.get('style', 0) == d.get('style', 0) \
                and not g.get('drapeaux') and not d.get('drapeaux') \
                and not g.get('romance') and not d.get('romance'):
            note('equilibre', f'{c["id"]} : les deux réponses coûtent exactement pareil')
        for cote, r in (('gauche', g), ('droite', d)):
            if r.get('romance') and not (c.get('chaine') or {}).get('id', '').startswith('coeur_') \
                    and not c['id'].startswith('rdv_'):
                note('equilibre', f'{c["id"]} · {cote} : déplace une attache hors '
                                  'd\'une chaîne de romance')

    # ── les objets ─────────────────────────────────────────────────────
    lus_par_une_carte = set()
    for c in cartes:
        for d in (c.get('conditions', {}).get('drapeaux_requis', [])
                  + c.get('conditions', {}).get('drapeaux_interdits', [])):
            if d.startswith('objet_'):
                if d[6:] not in objets:
                    note('conditions', f'{c["id"]} : objet inconnu « {d[6:]} »')
                lus_par_une_carte.add(d[6:])

    # Acheter pose `objet_<id>` « pour que les cartes qu'il ouvre puissent
    # sortir », dit palais.dart. Un objet que rien ne lit se paie et ne
    # change rien : ni décor, ni carte, ni jauge.
    catalogue = charge('objets')
    # Une fin et un exploit peuvent exiger un objet tout autant qu'une carte.
    lus_ailleurs = set()
    for f in charge('fins'):
        for d in f.get('drapeaux_requis', []):
            if d.startswith('objet_'):
                lus_ailleurs.add(d[6:])
    for e in charge('exploits'):
        cond = e.get('condition', {})
        for d in cond.get('drapeaux_requis', []) + cond.get('drapeaux_interdits', []):
            if d.startswith('objet_'):
                lus_ailleurs.add(d[6:])
    for o in catalogue:
        if (o['id'] in lus_par_une_carte or o['id'] in OBJETS_LUS_PAR_LE_MOTEUR
                or o['id'] in lus_ailleurs):
            continue
        if o.get('effet_achat') or o.get('style_achat'):
            continue
        note('objets', f'« {o["nom"]} » ({o["prix"]} caisses, {", ".join(o["natures"])}) : '
                       'rien ne lit son drapeau — l\'acheter ne change rien')
    promis = [o for o in catalogue if 'contenu' in o['natures']
              and o['id'] not in lus_par_une_carte
              and o['id'] not in OBJETS_LUS_PAR_LE_MOTEUR
              and o['id'] not in lus_ailleurs]
    if promis:
        note('objets', f'{len(promis)} objets portent la nature « contenu » mais '
                       'aucune carte n\'exige leur drapeau : '
                       + ', '.join(o['id'] for o in promis))

    # ── les impasses ───────────────────────────────────────────────────
    partielles = 0
    for nom, lot in sorted(chaines.items()):
        rangs = rangs_de(lot)
        for r in sorted(rangs):
            if r == 1:
                continue
            besoin = set()
            for x in rangs[r]:
                besoin.update(x.get('conditions', {}).get('drapeaux_requis', []))
            avant = rangs.get(r - 1, [])
            if not besoin or not avant:
                continue
            portes = sum(1 for x in avant for cote in ('gauche', 'droite')
                         if besoin & set(x[cote].get('drapeaux', [])))
            if portes < 2 * len(avant):
                partielles += 1
    if partielles:
        note('impasses', f'{partielles} crans ne s\'ouvrent qu\'à une partie des '
                         'réponses du cran précédent : l\'autre réponse arrête '
                         'l\'histoire sans le dire')

    return trouvailles


FAMILLES = [
    ('drapeaux', 'Les drapeaux'),
    ('chaines', 'Les chaînes'),
    ('conditions', 'Les conditions'),
    ('ecriture', "L'écriture"),
    ('typographie', 'La typographie'),
    ('equilibre', "L'équilibre"),
    ('objets', 'Les objets'),
    ('impasses', 'Les impasses'),
]


def main():
    trouvailles = audit()
    total = 0
    for cle, titre in FAMILLES:
        lot = trouvailles.get(cle, [])
        if not lot:
            continue
        total += len(lot)
        print(f'\n{titre} — {len(lot)}')
        for i, t in enumerate(sorted(lot), 1):
            print(f'  {i:3}. {t}')
    print(f'\n{total} remarques.' if total else '\nRien à signaler.')


if __name__ == '__main__':
    main()
