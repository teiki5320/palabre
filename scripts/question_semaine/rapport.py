"""Rapport Markdown d'une exécution : corps de l'issue GitHub et artefact du workflow."""

STATUTS = {'publie': 'question publiée', 'aucun': 'pas de question cette semaine', 'erreur': 'erreur technique', 'simule': 'simulation (rien d’écrit)'}


def _sujet_md(s):
    lignes = [f"**{s['question']}**", '']
    lignes += [f"- {o}" for o in s.get('options') or []]
    lignes += ['', s.get('contexte') or '', '', 'Sources :']
    for src in s.get('sources') or []:
        lignes.append(f"- [{src.get('titre') or src.get('url')}]({src.get('url')}) — {src.get('media') or ''} {src.get('date') or ''}".rstrip())
    return '\n'.join(lignes)


def rendre_rapport(lundi, resultats, url_retrait, dry_run=False):
    titre = f"Question de la semaine du {lundi.isoformat()}"
    out = [f"# {titre}", '', 'Les questions publiées ouvrent lundi à 8 h, heure locale de chaque pays.',
           f"Pour retirer une question avant l’ouverture : lancer [retirer-question]({url_retrait}) avec le pays et la semaine `{lundi.isoformat()}`.", '']
    if dry_run:
        out += ['> Simulation : rien n’a été écrit en base.', '']
    for r in resultats:
        statut = 'simule' if dry_run and r['statut'] == 'publie' else r['statut']
        out += [f"## {r['nom']} ({r['pays']}) — {STATUTS.get(statut, statut)}", '']
        if r['statut'] == 'publie':
            out += [_sujet_md(r['sujet']), '', f"Avis du relecteur : {r.get('avis') or '—'}", '']
        else:
            out += [f"Raison : {r.get('raison') or '—'}", '']
        if r.get('rejets'):
            out += ['<details><summary>Sujets écartés</summary>', '']
            for rej in r['rejets']:
                out.append(f"- `{rej.get('id')}` : " + ' ; '.join(rej.get('motifs') or []))
            out += ['', '</details>', '']
    return '\n'.join(out)
