import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'firebase_options.dart';

const debugMode = true;

Future firebaseInit() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (debugMode) {
    debugController = StreamController<User?>.broadcast();
    FirebaseAuth.instance.authStateChanges().listen((event) => debugController.add(event));
  }
}

final authUserProvider = StreamProvider<User?>((_) => debugMode ? debugController.stream : FirebaseAuth.instance.authStateChanges());

late StreamController<User?> debugController;
