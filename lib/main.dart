import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'app/providers.dart';
import 'features/auth/auth_repository.dart';
import 'features/packing/packing_repository.dart';
import 'features/trips/data/firestore_travel_repository.dart';
import 'features/trips/data/demo_travel_repository.dart';
import 'features/trips/domain/travel_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await bootstrap();
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'เริ่มแอปไม่สำเร็จ\nตรวจการตั้งค่า Firebase และอินเทอร์เน็ต\n$e',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> bootstrap({String? modeOverride}) async {
  final mode =
      modeOverride ??
      const String.fromEnvironment('APP_MODE', defaultValue: 'live');
  if (!['live', 'emulator', 'demo'].contains(mode)) {
    throw StateError('APP_MODE ไม่ถูกต้อง');
  }
  if (kReleaseMode && mode != 'live') {
    throw StateError('Release ต้องใช้ Firebase จริง');
  }
  final prefs = await SharedPreferences.getInstance();
  final packing = PackingRepository(prefs);
  late AuthRepository auth;
  late TravelRepository travel;
  if (mode == 'demo') {
    auth = DemoAuthRepository();
    travel = DemoTravelRepository(packing);
  } else {
    if (Firebase.apps.isEmpty) {
      if (mode == 'emulator') {
        await Firebase.initializeApp(
          name: 'emulator',
          options: const FirebaseOptions(
            apiKey: 'demo-key',
            appId: '1:123456789:android:demo',
            messagingSenderId: '123456789',
            projectId: 'demo-trippocket',
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
    }
    final firebaseApp = mode == 'emulator'
        ? Firebase.app('emulator')
        : Firebase.app();
    final firebaseAuth = FirebaseAuth.instanceFor(app: firebaseApp);
    final db = FirebaseFirestore.instanceFor(app: firebaseApp);
    if (mode == 'emulator') {
      const host = String.fromEnvironment(
        'EMULATOR_HOST',
        defaultValue: '10.0.2.2',
      );
      await firebaseAuth.useAuthEmulator(host, 9099);
      db.useFirestoreEmulator(host, 8080);
      db.settings = const Settings(persistenceEnabled: false);
    }
    auth = FirebaseAuthRepository(firebaseAuth);
    travel = FirestoreTravelRepository(db, packing);
  }
  runApp(
    ProviderScope(
      overrides: [
        modeProvider.overrideWithValue(mode),
        authRepositoryProvider.overrideWithValue(auth),
        travelRepositoryProvider.overrideWithValue(travel),
        packingRepositoryProvider.overrideWithValue(packing),
      ],
      child: const TripPocketApp(),
    ),
  );
}
