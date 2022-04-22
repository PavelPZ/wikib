import 'package:auth/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseInit();
  runApp(ProviderScope(child: const MyApp()));
}

@cwidget
Widget myApp(BuildContext context, WidgetRef ref) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              SignInButton(
                Buttons.Google,
                onPressed: onGoogleSignIn,
              ),
              SizedBox(height: 20),
              SignInButton(
                Buttons.Facebook,
                onPressed: onFacebookSignIn,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: FirebaseAuth.instance.signOut, child: Text('logout')),
              SizedBox(height: 20),
              ElevatedButton(onPressed: getRecaptchaVerification, child: Text('recaptcha')),
              SizedBox(height: 50),
              Consumer(
                builder: (_, ref, __) => ref.watch(authUserProvider).when(
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                      data: (user) => Text(user?.email ?? '-- empty --'),
                    ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
