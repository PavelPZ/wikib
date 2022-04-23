import 'package:auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wikib_providers/wikb_providers.dart';

// flutter pub run build_runner watch --delete-conflicting-outputs
part 'main.g.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebaseInit();
  runApp(ProviderScope(
    overrides: [
      authSignInsProvider.overrideWithProvider(Provider<AuthSignIns>((ref) => AuthSignIns(ref))),
    ],
    child: const MyApp(),
  ));
}

@cwidget
Widget myApp(WidgetRef ref) {
  final authSignIns = ref.watch(authSignInsProvider);
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
                onPressed: authSignIns.googlePlatformSignIn,
              ),
              SizedBox(height: 20),
              SignInButton(
                Buttons.FacebookNew,
                onPressed: authSignIns.facebookPlatformSignIn,
              ),
              SizedBox(height: 20),
              SignInButton(
                Buttons.Email,
                text: 'Debug sign in',
                onPressed: authSignIns.debugSignIn,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: authSignIns.signOut, child: Text('logout')),
              SizedBox(height: 20),
              ElevatedButton(onPressed: authSignIns.getRecaptchaVerification, child: Text('recaptcha')),
              SizedBox(height: 50),
              Consumer(builder: (_, ref, __) => Text(ref.watch(emailProvider))),
            ],
          ),
        ),
      ),
    ),
  );
}

final emailProvider = Provider<String>((ref) {
  final user = ref.watch(authProfileProvider);
  if (user == null) return '-- empty --';
  return '${user.displayName} (${user.email})';
});
