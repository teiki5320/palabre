"""Contrôles automatiques d'un sujet de question de la semaine. Fonctions pures, testées.

Un sujet est un dict : {id, fait, question, contexte, options: [str], sources: [{titre, url, date, media}],
points_d_attention}. Chaque contrôle renvoie une liste de motifs de rejet (vide si le sujet passe).
"""
import datetime as dt
import re
import unicodedata
from urllib.parse import urlparse

SANS_AVIS = 'sans avis'
QUESTION_MAX = 200
CONTEXTE_MAX = 600
OPTIONS_MIN, OPTIONS_MAX = 3, 5
FENETRE_JOURS = 9


def lundi_vise(jour):
    """Lundi de la semaine à servir : le prochain lundi strictement après `jour`."""
    delta = (7 - jour.weekday()) % 7 or 7
    return jour + dt.timedelta(days=delta)


def fenetre(lundi, jour_execution):
    """Dates admises pour les sources : les huit jours avant l'exécution, et au moins depuis lundi − 9
    (identique quand on tourne le dimanche ; plus large si on tourne plus tôt)."""
    debut = min(lundi - dt.timedelta(days=FENETRE_JOURS), jour_execution - dt.timedelta(days=FENETRE_JOURS - 1))
    return debut, jour_execution


def normaliser(texte):
    s = unicodedata.normalize('NFKD', texte or '').encode('ascii', 'ignore').decode().lower()
    return re.sub(r'[^a-z0-9]+', ' ', s).strip()


def variantes_nom(nom):
    """Formes sous lesquelles un nom de personne peut apparaître : tel quel et prénom/nom inversés."""
    toks = normaliser(nom).split()
    if len(toks) < 2:
        return set()
    formes = {' '.join(toks), ' '.join(toks[1:] + toks[:1]), ' '.join(toks[-1:] + toks[:-1])}
    return {f for f in formes if len(f) >= 6}


def contient_personne(texte, noms):
    """Nom de la table person trouvé dans le texte, ou None."""
    t = f' {normaliser(texte)} '
    for nom in noms:
        for forme in variantes_nom(nom):
            if f' {forme} ' in t:
                return nom
    return None


def hote(url):
    h = (urlparse(url).netloc or '').lower()
    return h[4:] if h.startswith('www.') else h


def parse_date(s):
    try:
        return dt.date.fromisoformat(str(s)[:10])
    except (TypeError, ValueError):
        return None


def controler(sujet, lundi, jour_execution, noms_personnes=(), statuts_http=None):
    """Motifs de rejet d'un sujet. `statuts_http` : {url: code} déjà mesurés (None = non vérifié)."""
    motifs = []
    q = (sujet.get('question') or '').strip()
    if not q.endswith('?'):
        motifs.append('la question ne se termine pas par « ? »')
    if len(q) > QUESTION_MAX:
        motifs.append(f'question trop longue ({len(q)} > {QUESTION_MAX})')
    ctx = (sujet.get('contexte') or '').strip()
    if not ctx:
        motifs.append('contexte vide')
    if len(ctx) > CONTEXTE_MAX:
        motifs.append(f'contexte trop long ({len(ctx)} > {CONTEXTE_MAX})')

    options = [o.strip() for o in sujet.get('options') or [] if o and o.strip()]
    if not OPTIONS_MIN <= len(options) <= OPTIONS_MAX:
        motifs.append(f'{len(options)} options (attendu {OPTIONS_MIN} à {OPTIONS_MAX})')
    if not any(normaliser(o) == SANS_AVIS for o in options):
        motifs.append('pas d’option « Sans avis »')
    if len({normaliser(o) for o in options}) != len(options):
        motifs.append('options en double')

    # Sources : au moins deux sites différents datés de la période et joignables. Les sources plus
    # anciennes sont tolérées comme contexte, mais ne comptent pas.
    sources = sujet.get('sources') or []
    debut, fin = fenetre(lundi, jour_execution)
    hotes_recents = set()
    for s in sources:
        url = s.get('url') or ''
        if not url.startswith('http'):
            motifs.append(f'source sans URL valide : {s.get("titre")}')
            continue
        if statuts_http is not None:
            code = statuts_http.get(url)
            if code is None or code >= 400:
                motifs.append(f'source injoignable (HTTP {code}) : {url}')
                continue
        d = parse_date(s.get('date'))
        if d is None:
            motifs.append(f'source sans date : {url}')
        elif debut <= d <= fin:
            hotes_recents.add(hote(url))
    if len(hotes_recents) < 2:
        motifs.append(f'{len(hotes_recents)} site source distinct daté du {debut} au {fin} (attendu au moins 2)')

    for champ, texte in (('question', q), ('contexte', ctx), *((f'option « {o} »', o) for o in options)):
        nom = contient_personne(texte, noms_personnes)
        if nom:
            motifs.append(f'{champ} cite une personne de la base : {nom}')
    return motifs


def filtrer(sujets, lundi, jour_execution, noms_personnes=(), statuts_http=None):
    """(retenus, rejets) ; rejets = [{id, motifs}]."""
    retenus, rejets = [], []
    for s in sujets:
        m = controler(s, lundi, jour_execution, noms_personnes, statuts_http)
        (rejets.append({'id': s.get('id'), 'motifs': m}) if m else retenus.append(s))
    return retenus, rejets
