import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/config/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(const FlowMaticApp());
}
