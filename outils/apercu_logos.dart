// Aperçu des marques proposées, à photographier sur le simulateur.
// Fichier de travail, non embarqué dans le jeu :
//   flutter build ios --simulator --debug -t outils/apercu_logos.dart
import 'dart:io';

import 'package:flutter/material.dart';

const nuit = Color(0xFF14131A);
const dossier = '/private/tmp/claude-501/-Users-jeanperraudeau-Palabre/b949f525-b723-40a6-a721-62008fa7b30a/scratchpad/marques';

void main() => runApp(const ApercuMarques());

class ApercuMarques extends StatelessWidget {
  const ApercuMarques({super.key});

  static const fichiers = <String, String>{
    '1': 'echarpe',
    '2': 'fauteuil',
    '3': 'main',
    '4': 'sceau',
    '5': 'palais',
    '6': 'arbre',
  };

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: nuit,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (final e in fichiers.entries)
                    Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(File('$dossier/${e.key}-${e.value}.jpg'), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          top: 6,
                          child: Text(e.key,
                              style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
