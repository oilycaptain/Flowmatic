import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future<void> initializeFirebase() async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
    return;
  }

  final projectId = const String.fromEnvironment('FIREBASE_PROJECT_ID');
  final appId = const String.fromEnvironment('FIREBASE_APP_ID');
  final messagingSenderId = const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  final apiKey = const String.fromEnvironment('FIREBASE_API_KEY');
  final authDomain = const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  final storageBucket = const String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  if ([projectId, appId, messagingSenderId, apiKey].any((v) => v.isEmpty)) {
    throw StateError(
      'Missing Firebase web config. Pass --dart-define values for FIREBASE_PROJECT_ID, FIREBASE_APP_ID, '
      'FIREBASE_MESSAGING_SENDER_ID, FIREBASE_API_KEY (plus auth/storage if needed).',
    );
  }

  await Firebase.initializeApp(
    options: FirebaseOptions(
      projectId: projectId,
      appId: appId,
      messagingSenderId: messagingSenderId,
      apiKey: apiKey,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket.isEmpty ? null : storageBucket,
    ),
  );
}
