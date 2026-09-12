import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;

import 'app/app.dart';
import 'core/ads/ads.dart';
import 'core/notifications/push_service.dart';
import 'core/prefs/prefs_provider.dart';
import 'core/profile/profile.dart';
import 'core/supabase/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  // Tout ce qui précède runApp doit rester local et rapide : premier rendu
  // sous la seconde sur un appareil à 2 Go.
  final prefs = await SharedPreferences.getInstance();
  await AuthBootstrap.initialize();

  final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
  runApp(UncontrolledProviderScope(container: container, child: const PalabreApp()));

  // Réseau après le premier rendu.
  unawaited(_afterFirstFrame(container));
}

Future<void> _afterFirstFrame(ProviderContainer container) async {
  await AuthBootstrap.ensureSession();
  await container.read(profileProvider.notifier).sync();
  await PushService.initialize(container);
  await AdsService.initialize();
}
