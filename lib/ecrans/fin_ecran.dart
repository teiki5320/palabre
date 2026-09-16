import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Écran de fin de mandat. Étoffé à la tâche 12.
class FinEcran extends ConsumerWidget {
  const FinEcran({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const Scaffold(body: Center(child: Text('Fin du mandat')));
}
