import datetime as dt
import unittest

from controles import contient_personne, controler, fenetre, filtrer, hote, lundi_vise, variantes_nom
from rapport import rendre_rapport

LUNDI = dt.date(2026, 9, 21)
DIMANCHE = dt.date(2026, 9, 20)


def sujet(**kw):
    base = {
        'id': 'cantines',
        'fait': 'Le 2 septembre 2026, le gouvernement a étendu les cantines scolaires.',
        'question': 'Pour les cantines scolaires, quelle priorité vous paraît la plus importante ?',
        'contexte': 'Le Conseil des ministres du 16 septembre 2026 a étendu les cantines à 1,9 million d’écoliers.',
        'options': ['Plus d’écoliers', 'Meilleurs repas', 'Ouverture dès la rentrée', 'Sans avis'],
        'sources': [
            {'titre': 'SGG', 'url': 'https://sgg.gouv.bj/cm/2026-09-16/', 'date': '2026-09-16', 'media': 'SGG'},
            {'titre': 'SRTB', 'url': 'https://srtb.bj/cantines', 'date': '2026-09-17', 'media': 'SRTB'},
        ],
        'points_d_attention': '',
    }
    base.update(kw)
    return base


class LundiVise(unittest.TestCase):
    def test_dimanche_donne_lendemain(self):
        self.assertEqual(lundi_vise(DIMANCHE), LUNDI)

    def test_lundi_donne_semaine_suivante(self):
        self.assertEqual(lundi_vise(LUNDI), dt.date(2026, 9, 28))

    def test_mercredi(self):
        self.assertEqual(lundi_vise(dt.date(2026, 9, 16)), LUNDI)

    def test_fenetre(self):
        self.assertEqual(fenetre(LUNDI, DIMANCHE), (dt.date(2026, 9, 12), DIMANCHE))

    def test_fenetre_execution_anticipee(self):
        self.assertEqual(fenetre(LUNDI, dt.date(2026, 9, 12)), (dt.date(2026, 9, 4), dt.date(2026, 9, 12)))


class Personnes(unittest.TestCase):
    def test_variantes(self):
        self.assertIn('romuald wadagni', variantes_nom('Romuald WADAGNI'))
        self.assertIn('wadagni romuald', variantes_nom('Romuald WADAGNI'))
        self.assertEqual(variantes_nom('Wadagni'), set())

    def test_detection_accents_et_ordre(self):
        noms = ['DJOGBENOU JOSEPH', 'Alimatou Shadiya ASSOUMAN']
        self.assertEqual(contient_personne('Le président Joseph Djogbénou a annoncé…', noms), 'DJOGBENOU JOSEPH')
        self.assertIsNone(contient_personne('Le président de l’Assemblée a annoncé…', noms))

    def test_pas_de_faux_positif_sur_sous_mot(self):
        self.assertIsNone(contient_personne('Les cantines de Kandi ouvrent', ['KANDI ABDOU']))


class Controles(unittest.TestCase):
    def test_sujet_valide(self):
        self.assertEqual(controler(sujet(), LUNDI, DIMANCHE), [])

    def test_question_sans_point_d_interrogation(self):
        m = controler(sujet(question='Quelle priorité.'), LUNDI, DIMANCHE)
        self.assertTrue(any('« ? »' in x for x in m))

    def test_sans_avis_obligatoire(self):
        m = controler(sujet(options=['A', 'B', 'C']), LUNDI, DIMANCHE)
        self.assertTrue(any('Sans avis' in x for x in m))

    def test_nombre_d_options(self):
        self.assertTrue(controler(sujet(options=['A', 'Sans avis']), LUNDI, DIMANCHE))
        self.assertTrue(controler(sujet(options=['A', 'B', 'C', 'D', 'E', 'Sans avis']), LUNDI, DIMANCHE))

    def test_source_ancienne_toleree_si_deux_recentes(self):
        s = sujet()
        s['sources'].append({'titre': 'Décret', 'url': 'https://sgg.gouv.bj/doc/decret', 'date': '2025-10-29', 'media': 'SGG'})
        self.assertEqual(controler(s, LUNDI, DIMANCHE), [])

    def test_une_seule_source_recente(self):
        s = sujet()
        s['sources'][0]['date'] = '2026-08-30'
        self.assertTrue(any('site source distinct daté' in x for x in controler(s, LUNDI, DIMANCHE)))

    def test_deux_hotes_distincts(self):
        s = sujet()
        s['sources'][1]['url'] = 'https://www.sgg.gouv.bj/autre'
        self.assertTrue(any('site source distinct' in x for x in controler(s, LUNDI, DIMANCHE)))

    def test_http_injoignable(self):
        statuts = {'https://sgg.gouv.bj/cm/2026-09-16/': 200, 'https://srtb.bj/cantines': 404}
        self.assertTrue(any('injoignable' in x for x in controler(sujet(), LUNDI, DIMANCHE, statuts_http=statuts)))
        statuts['https://srtb.bj/cantines'] = 200
        self.assertEqual(controler(sujet(), LUNDI, DIMANCHE, statuts_http=statuts), [])

    def test_personne_dans_question(self):
        s = sujet(question='Faites-vous confiance à Romuald Wadagni pour les cantines ?')
        self.assertTrue(any('personne' in x for x in controler(s, LUNDI, DIMANCHE, ['Romuald WADAGNI'])))

    def test_contexte_trop_long(self):
        self.assertTrue(controler(sujet(contexte='x' * 601), LUNDI, DIMANCHE))

    def test_filtrer(self):
        retenus, rejets = filtrer([sujet(), sujet(id='mauvais', options=['A'])], LUNDI, DIMANCHE)
        self.assertEqual([s['id'] for s in retenus], ['cantines'])
        self.assertEqual(rejets[0]['id'], 'mauvais')

    def test_hote(self):
        self.assertEqual(hote('https://www.lanation.bj/x'), 'lanation.bj')


class Rapport(unittest.TestCase):
    def test_rendu(self):
        resultats = [
            {'pays': 'BJ', 'nom': 'Bénin', 'statut': 'publie', 'sujet': sujet(), 'avis': 'Neutre, sources concordantes.',
             'rejets': [{'id': 'budget', 'motifs': ['1 site source distinct (attendu au moins 2)']}]},
            {'pays': 'TG', 'nom': 'Togo', 'statut': 'aucun', 'raison': 'le relecteur n’a retenu aucun sujet', 'rejets': []},
            {'pays': 'CI', 'nom': "Côte d'Ivoire", 'statut': 'erreur', 'raison': 'API indisponible', 'rejets': []},
        ]
        md = rendre_rapport(LUNDI, resultats, 'https://github.com/x/y/actions/workflows/retirer-question.yml', dry_run=False)
        self.assertIn('Bénin', md)
        self.assertIn('Sans avis', md)
        self.assertIn('sgg.gouv.bj', md)
        self.assertIn('Togo', md)
        self.assertIn('API indisponible', md)
        self.assertIn('retirer-question', md)
        self.assertIn('2026-09-21', md)


if __name__ == '__main__':
    unittest.main()
