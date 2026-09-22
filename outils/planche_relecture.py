#!/usr/bin/env python3
"""Écrit « La relecture » : les 675 cartes, une par une, à valider.

    python3 outils/planche_relecture.py [fichier.html]

Tout ce qu'il faut pour juger une carte tient dans son bloc : le texte tel
que le joueur le lit, les deux libellés, ce que chacun coûte, les deux
lendemains, et ce qui doit être vrai pour qu'elle sorte. Pas de portrait :
on relit des phrases, pas des visages, et six cent soixante-quinze images
rendraient la page inutilisable.

Le verdict de chaque carte est gardé dans la base de l'artifact, donc il
survit au rechargement et se relit d'ici.
"""

import json
import os
import re
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RACINE, 'outils'))
import planche_jeu as pj  # noqa: E402  (le même vocabulaire, les mêmes numéros)


def marques(carte):
    """Les repères automatiques, pour guider l'œil — jamais pour juger."""
    out = []
    t = carte['texte']
    if re.search(r'\bou\b[^?]{0,60}\?\s*$', t):
        out.append('question en deux termes')
    if '?' not in t:
        out.append('pas de question')
    g, d = carte['gauche'], carte['droite']
    if len(g.get('effets', {})) != len(d.get('effets', {})):
        out.append('réponses de portée inégale')
    ecart = abs(sum(g.get('effets', {}).values()) - sum(d.get('effets', {}).values()))
    if ecart >= 12:
        out.append(f'écart de prix {ecart}')
    if carte.get('conditions', {}).get('parcours'):
        out.append('un seul camp de parcours')
    return out


def bloc(carte, n, gens, parcours, page):
    qui = carte['personnage']
    titre = ('la personne épousée' if qui == 'conjoint'
             else gens.get(qui, {}).get('titre') or pj.nom_de(qui, gens))
    porte = pj.coiffe_de(carte, gens, parcours, lambda d: '#', avec_rang=True)
    porte = re.sub(r'<[^>]+>', '', porte)
    reps = []
    for cote, fleche in (('gauche', '←'), ('droite', '→')):
        r = carte[cote]
        prix = ' · '.join(
            f'{pj.JAUGES.get(k, k)} {v:+d}' for k, v in r.get('effets', {}).items())
        if r.get('style'):
            prix += f" · régime {r['style']:+d}"
        for dr in r.get('drapeaux', []):
            prix += f" · pose « {pj.joli(dr)} »"
        reps.append(
            f'<div class="rep">'
            f'<p class="lib">{fleche} {pj.echappe(r["libelle"])}</p>'
            f'<p class="prix">{pj.echappe(prix)}</p>'
            f'<p class="jour">{pj.echappe(r["journal"])}</p></div>')
    reperes = ''.join(f'<span class="marque">{pj.echappe(m)}</span>'
                      for m in marques(carte))
    return f'''    <article class="carte" id="c{n}" data-id="{carte['id']}"
      data-qui="{qui}" data-page="{page}">
      <div class="haut">
        <span class="num">{n}</span>
        <div class="qui"><b>{pj.echappe(titre)}</b>
          <span class="ident">{pj.echappe(carte['id'])}</span></div>
        <div class="verdicts">
          <button class="v ok" data-v="ok" type="button">Bonne</button>
          <button class="v revoir" data-v="revoir" type="button">À revoir</button>
        </div>
      </div>
      <p class="dit">{pj.echappe(pj.habille(carte['texte']))}</p>
      <p class="porte">{pj.echappe(porte)}{reperes}</p>
      <div class="reps">{''.join(reps)}</div>
      <textarea class="note" rows="1" placeholder="Ce qui ne va pas…"></textarea>
    </article>'''


GABARIT = '''<title>La relecture</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,700;12..96,800&family=Public+Sans:wght@0,400;0,600;0,700&display=swap">
<style>
  :root{
    --fond:#14131A; --leve:#1C1A23; --encre:#F6EFE4; --douce:#C3BBB0;
    --faible:#857E8F; --or:#E9B44C; --trait:#2E2A38; --chair:#C97B6A;
    --vert:#7FB069; --nuit:#14131A;
    --titre:"Bricolage Grotesque","Trebuchet MS",sans-serif;
    --corps:"Public Sans",system-ui,-apple-system,sans-serif;
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--fond);color:var(--encre);font-family:var(--corps);
    font-size:16px;line-height:1.5}
  .page{max-width:900px;margin:0 auto;padding:0 20px;padding-block:36px 90px}
  h1{font-family:var(--titre);font-weight:800;font-size:clamp(1.8rem,5vw,2.6rem);
    line-height:1.03;letter-spacing:-.015em;margin:0}
  .surtitre{font-size:.72rem;letter-spacing:.18em;text-transform:uppercase;
    color:var(--faible);font-weight:600;margin:0 0 12px}
  .chapeau{font-size:1.02rem;color:var(--douce);max-width:62ch;margin:13px 0 0}
  .note-page{font-size:.84rem;color:var(--faible);max-width:70ch}

  .barre{position:sticky;top:0;z-index:9;background:var(--fond);padding:12px 0;
    margin:24px 0 8px;border-top:1px solid var(--trait);border-bottom:1px solid var(--trait);
    display:flex;gap:10px;align-items:center;flex-wrap:wrap}
  .barre select,.barre button{font:600 .78rem var(--corps);color:var(--douce);
    background:var(--leve);border:1px solid var(--trait);border-radius:999px;
    padding:7px 13px;cursor:pointer}
  .barre button[aria-pressed="true"]{background:var(--or);color:var(--nuit);border-color:var(--or)}
  .compte{margin-left:auto;font-size:.8rem;color:var(--faible);font-variant-numeric:tabular-nums}
  .compte b{font-family:var(--titre);color:var(--encre)}
  .compte .b-ok{color:var(--vert)} .compte .b-revoir{color:var(--chair)}

  .carte{border-top:1px solid var(--trait);padding:20px 0 22px;scroll-margin-top:80px}
  .carte[hidden]{display:none}
  .haut{display:flex;align-items:center;gap:12px;flex-wrap:wrap}
  .num{font-family:var(--titre);font-weight:700;font-size:.76rem;color:var(--nuit);
    background:var(--or);border-radius:4px;padding:3px 8px;flex:none}
  .qui{font-size:.82rem;color:var(--douce);min-width:0}
  .qui b{font-family:var(--titre);font-weight:700;color:var(--encre)}
  .ident{display:block;font-size:.68rem;color:var(--faible);font-family:ui-monospace,monospace}
  .verdicts{margin-left:auto;display:flex;gap:7px}
  .v{font:600 .74rem var(--corps);color:var(--douce);background:var(--leve);
    border:1px solid var(--trait);border-radius:999px;padding:6px 13px;cursor:pointer}
  .v:focus-visible{outline:2px solid var(--or);outline-offset:2px}
  .carte[data-etat="ok"] .v.ok{background:var(--vert);border-color:var(--vert);color:#0e1a0b}
  .carte[data-etat="revoir"] .v.revoir{background:var(--chair);border-color:var(--chair);color:#1b0f0c}
  .carte[data-etat="ok"]{opacity:.62}
  .carte[data-etat="revoir"]{box-shadow:inset 3px 0 0 var(--chair);padding-left:14px}

  .dit{font-size:1.04rem;line-height:1.45;margin:14px 0 8px;max-width:64ch}
  .porte{font-size:.72rem;color:var(--faible);margin:0 0 14px;display:flex;
    flex-wrap:wrap;gap:6px;align-items:baseline}
  .marque{font-size:.64rem;color:var(--or);border:1px solid rgba(233,180,76,.4);
    border-radius:3px;padding:1px 6px}
  .reps{display:grid;grid-template-columns:1fr 1fr;gap:14px}
  .rep{background:var(--leve);border:1px solid var(--trait);border-radius:6px;padding:11px 13px}
  .lib{font-family:var(--titre);font-weight:700;font-size:.92rem;margin:0}
  .prix{font-size:.72rem;color:var(--or);margin:4px 0 7px}
  .jour{font-size:.8rem;color:var(--douce);margin:0;line-height:1.42}
  .note{width:100%;margin-top:12px;background:transparent;color:var(--encre);
    border:1px solid var(--trait);border-radius:6px;padding:8px 11px;
    font:400 .84rem var(--corps);resize:vertical;min-height:38px}
  .note:focus{outline:none;border-color:var(--or)}
  .carte[data-etat="revoir"] .note{border-color:rgba(201,123,106,.5)}

  .etat-base{position:fixed;left:0;right:0;bottom:0;background:var(--leve);
    border-top:1px solid var(--trait);padding:9px 20px;font-size:.76rem;
    color:var(--faible);text-align:center}
  .etat-base b{color:var(--or)}
  @media (max-width:620px){ .reps{grid-template-columns:1fr} }
</style>
<div class="page">
  <p class="surtitre">Palabre — Président pour 100 jours · version {{VERSION}}</p>
  <h1>La relecture</h1>
  <p class="chapeau">Les {{TOTAL}} cartes du jeu, une par une : le texte tel que le
  joueur le lit, les deux réponses avec ce qu'elles coûtent, et les deux lendemains.
  Marque chaque carte <b>Bonne</b> ou <b>À revoir</b>, et écris ce qui cloche.</p>
  <p class="note-page">Ce qu'il faut regarder : la grammaire, ce qu'on comprend sans
  rien savoir d'autre, et si les deux réponses répondent vraiment à la question posée.
  Les étiquettes dorées sont des repères automatiques, pas des verdicts.</p>
  <p class="note-page">Tes verdicts sont enregistrés à mesure : tu peux fermer la page
  et revenir. Les numéros sont ceux de la planche du jeu.</p>

  <nav class="barre">
    <button type="button" data-filtre="tout" aria-pressed="true">Tout</button>
    <button type="button" data-filtre="reste" aria-pressed="false">Pas encore vues</button>
    <button type="button" data-filtre="revoir" aria-pressed="false">À revoir</button>
    <button type="button" data-filtre="ok" aria-pressed="false">Bonnes</button>
    <select id="qui"><option value="">Tout le monde</option>{{GENS}}</select>
    <span class="compte" id="compte"></span>
  </nav>

{{CORPS}}
</div>
<div class="etat-base" id="etat">Ouverture de la fiche…</div>
<script>
  // Le verdict de chaque carte vit dans la base de l'artifact : il survit au
  // rechargement, et il se relit depuis la conversation. Sans base — page
  // ouverte hors de claude.ai — la fiche reste lisible, simplement muette.
  (function () {
    var cartes = Array.prototype.slice.call(document.querySelectorAll('.carte'));
    var etats = {};
    var db = null;
    var barre = document.getElementById('etat');
    var enAttente = {};
    var minuteur = null;

    function compte() {
      var ok = 0, revoir = 0;
      cartes.forEach(function (c) {
        var e = etats[c.dataset.id];
        if (e && e.etat === 'ok') ok++;
        if (e && e.etat === 'revoir') revoir++;
      });
      document.getElementById('compte').innerHTML =
        '<b class="b-ok">' + ok + '</b> bonnes · <b class="b-revoir">' + revoir +
        '</b> à revoir · <b>' + (cartes.length - ok - revoir) + '</b> à voir';
    }

    function peint(c) {
      var e = etats[c.dataset.id];
      if (e && e.etat) c.dataset.etat = e.etat; else c.removeAttribute('data-etat');
      var n = c.querySelector('.note');
      if (e && typeof e.note === 'string' && document.activeElement !== n) n.value = e.note;
    }

    function filtre() {
      var actif = document.querySelector('.barre button[aria-pressed="true"]').dataset.filtre;
      var qui = document.getElementById('qui').value;
      cartes.forEach(function (c) {
        var e = etats[c.dataset.id] || {};
        var garde = actif === 'tout' ? true
          : actif === 'reste' ? !e.etat
          : e.etat === actif;
        c.hidden = !(garde && (!qui || c.dataset.qui === qui));
      });
    }

    function pousse() {
      if (!db) return;
      clearTimeout(minuteur);
      minuteur = setTimeout(function () {
        var lot = enAttente; enAttente = {};
        Object.keys(lot).forEach(function (id) {
          db.doc('relecture/' + id).set(lot[id]).catch(function (err) {
            barre.innerHTML = 'Enregistrement impossible (<b>' + err.code + '</b>) — ' +
              'les verdicts restent à l\\'écran mais ne seront pas gardés.';
          });
        });
      }, 400);
    }

    function pose(c, valeur) {
      var id = c.dataset.id;
      var e = etats[id] || {};
      e.etat = (e.etat === valeur) ? '' : valeur;
      e.note = c.querySelector('.note').value;
      e.numero = Number(c.querySelector('.num').textContent);
      etats[id] = e;
      peint(c); compte(); filtre();
      enAttente[id] = e; pousse();
    }

    cartes.forEach(function (c) {
      c.querySelectorAll('.v').forEach(function (b) {
        b.addEventListener('click', function () { pose(c, b.dataset.v); });
      });
      c.querySelector('.note').addEventListener('input', function () {
        var id = c.dataset.id;
        var e = etats[id] || {};
        e.note = c.querySelector('.note').value;
        e.numero = Number(c.querySelector('.num').textContent);
        etats[id] = e; enAttente[id] = e; pousse();
      });
    });

    document.querySelectorAll('.barre button').forEach(function (b) {
      b.addEventListener('click', function () {
        document.querySelectorAll('.barre button').forEach(function (a) {
          a.setAttribute('aria-pressed', String(a === b));
        });
        filtre();
      });
    });
    document.getElementById('qui').addEventListener('change', filtre);
    compte();

    (window.claude && window.claude.use ? window.claude.use('db') : Promise.resolve(null))
      .then(function (base) {
        db = base;
        if (!db) {
          barre.innerHTML = 'Page ouverte hors de claude.ai : <b>les verdicts ne ' +
            'seront pas gardés</b>.';
          return;
        }
        barre.innerHTML = 'Verdicts enregistrés à mesure.';
        return db.collection('relecture').get().then(function (q) {
          q.docs.forEach(function (d) { etats[d.id] = d.data; });
          cartes.forEach(peint); compte(); filtre();
        });
      })
      .catch(function () {
        barre.innerHTML = 'Page ouverte hors de claude.ai : <b>les verdicts ne ' +
          'seront pas gardés</b>.';
      });
  })();
</script>'''


def main():
    sortie = (sys.argv[1] if len(sys.argv) > 1
              else os.path.join(RACINE, 'sources/relecture/relecture.html'))
    os.makedirs(os.path.dirname(sortie), exist_ok=True)

    cartes = pj.charge('cartes')
    gens = {p['id']: p for p in pj.charge('personnages')}
    parcours = {p['id']: p for p in pj.charge('parcours')}

    # Le même ordre et les mêmes numéros que la planche du jeu : « la 412 »
    # doit désigner la même carte des deux côtés.
    par_chaine, seules = {}, []
    for c in cartes:
        ch = c.get('chaine')
        (par_chaine.setdefault(ch['id'], []).append(c) if ch else seules.append(c))
    lots = pj.ordre_des_seules(seules)
    ordre, n = [], 0
    for nom in pj.ordre_des_chaines(par_chaine):
        rangs = pj.rangs_de(par_chaine[nom])
        for r in sorted(rangs):
            for c in rangs[r]:
                n += 1
                ordre.append((c, n, 'histoires'))
    for qui, lot in lots:
        for c in lot:
            n += 1
            ordre.append((c, n, 'cartes'))
    if n != len(cartes):
        sys.exit(f'{n} numéros pour {len(cartes)} cartes')

    corps = '\n'.join(bloc(c, i, gens, parcours, page) for c, i, page in ordre)
    presents = sorted({c['personnage'] for c in cartes},
                      key=lambda q: pj.nom_de(q, gens))
    options = ''.join(
        f'<option value="{q}">{pj.echappe(pj.nom_de(q, gens) if q != "conjoint" else "La personne épousée")}</option>'
        for q in presents)

    page = (GABARIT
            .replace('{{VERSION}}', pj.version())
            .replace('{{TOTAL}}', str(len(cartes)))
            .replace('{{GENS}}', options)
            .replace('{{CORPS}}', corps))
    open(sortie, 'w').write(page)
    print(f'{sortie} — {len(cartes)} cartes, {os.path.getsize(sortie) / 1000:.0f} ko')


if __name__ == '__main__':
    main()
