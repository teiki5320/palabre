#!/usr/bin/env python3
"""Retire (dépublie) la question de la semaine d'un pays si elle n'est pas encore ouverte.

Usage : retirer.py PAYS AAAA-MM-JJ   (env : SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
"""
import datetime as dt
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run import Supabase  # noqa: E402


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    pays, semaine = sys.argv[1].upper(), sys.argv[2]
    sb = Supabase(os.environ['SUPABASE_URL'], os.environ['SUPABASE_SERVICE_ROLE_KEY'])
    rows = sb.get(f'poll?select=id,question,publie,ouverture&country_code=eq.{pays}&semaine=eq.{semaine}')
    if not rows:
        sys.exit(f'aucun sondage {pays} pour la semaine du {semaine}')
    p = rows[0]
    if not p['publie']:
        print(f'déjà en brouillon : {p["question"]}')
        return
    if dt.datetime.fromisoformat(p['ouverture']) <= dt.datetime.now(dt.timezone.utc):
        sys.exit(f'refus : le sondage est déjà ouvert (depuis {p["ouverture"]}), on ne retire pas une question en cours de vote')
    sb._req('PATCH', f'poll?id=eq.{p["id"]}', {'publie': False}, prefer='return=minimal')
    print(f'retirée (repassée en brouillon) : {p["question"]}')


if __name__ == '__main__':
    main()
