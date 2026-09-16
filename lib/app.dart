import 'package:flutter/material.dart';

/// Coquille de l'application. La navigation sera ajoutée avec les écrans.
class AppPresident extends StatelessWidget {
  const AppPresident({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Président pour 100 jours',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFE9B44C), brightness: Brightness.dark),
      home: const Scaffold(body: Center(child: Text('Président'))),
    );
  }
}
