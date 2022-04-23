import 'dart:async';

import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/facebook.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/identitytoolkit/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protobuf_for_dart/algorithm.dart';
import 'package:wikib_providers/wikib_providers.dart';

import 'firebase_options.dart';

part 'init_app.dart';
part 'to_auth_profile.dart';

// See example: github\flutter_desktop_webview_auth\example\lib\main.dart

// *************************************************************************************************

// install firebase cli, node.js version: https://firebase.google.com/docs/cli#install-cli-windows
// generate .dart config file: https://firebase.flutter.dev/docs/overview/flutterfire configure

// https://invertase.io/blog/announcing-flutterfire-desktop
//

// Common for google and facebook
const REDIRECT_URI = 'https://wikibulary-1589552057434.firebaseapp.com/__/auth/handler';

// firebase: https://console.firebase.google.com/project/wikibulary-1589552057434/overview
// Authentication / Sign-in method / google
// https://console.cloud.google.com/apis/dashboard?project=wikibulary-1589552057434&show=all
// OAuth 2.0 Client IDs / Web client (auto created by Google Service) / Client ID
const GOOGLE_CLIENT_ID = '254440128982-58tigb9m70855ahppvbuk7lbkb69nju6.apps.googleusercontent.com';
const GOOGLE_API_KEY = 'AIzaSyBB0wkt-YZ9UtXmLSKFZttA_Fjeo3FhVHM';

// https://developers.facebook.com/apps/247034373023561/fb-login/settings/
// Client OAuth settings:
// Web OAuth login + Client OAuth login
// Valid OAuth Redirect URIs
const FACEBOOK_CLIENT_ID = '247034373023561';

final googleSignInArgs = GoogleSignInArgs(
  clientId: GOOGLE_CLIENT_ID,
  redirectUri: REDIRECT_URI,
  scope: 'https://www.googleapis.com/auth/plus.me',
);

final facebookSignInArgs = FacebookSignInArgs(
  clientId: FACEBOOK_CLIENT_ID,
  redirectUri: REDIRECT_URI,
);

// *************************************************************************************************
typedef SignIn = Future Function();

class AuthSignIns {
  AuthSignIns(this.ref) : _auth = FirebaseAuth.instance;

  final Ref ref;
  final FirebaseAuth _auth;

  SignIn get googlePlatformSignIn {
    if (kIsWeb) return _webGoogleSignIn;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return _desktopGoogleSignIn;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  SignIn get facebookPlatformSignIn {
    if (kIsWeb) return _webFacebookSignIn;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return _desktopFacebookSignIn;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  Future _desktopGoogleSignIn() async {
    final result = await DesktopWebviewAuth.signIn(googleSignInArgs);
    if (result == null) return _userCredential(null);
    final credential = GoogleAuthProvider.credential(
      idToken: result.idToken,
      accessToken: result.accessToken,
    );
    return _userCredential(_auth.signInWithCredential(credential));
  }

  Future _desktopFacebookSignIn() async {
    final result = await DesktopWebviewAuth.signIn(facebookSignInArgs);
    if (result == null) return _userCredential(null);
    final credential = FacebookAuthProvider.credential(result.accessToken!);
    return _userCredential(_auth.signInWithCredential(credential));
  }

// https://github.com/firebase/flutterfire/blob/master/docs/auth/social.mdx
  Future _webGoogleSignIn() {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('https://www.googleapis.com/auth/plus.me https://www.googleapis.com/auth/userinfo.email');
    return _userCredential(_auth.signInWithPopup(googleProvider));
  }

  Future _webFacebookSignIn() {
    final facebookProvider = FacebookAuthProvider();
    facebookProvider.addScope('email');
    facebookProvider.setCustomParameters({'display': 'popup'});
    return _userCredential(_auth.signInWithPopup(facebookProvider));
  }

  void debugSignIn() {
    ref.read(authProfileProvider.notifier).state = AuthProfile()
      ..displayName = 'Debug Name'
      ..email = 'debug@name.xx';
  }

  Future signOut() {
    ref.read(authProfileProvider.notifier).state = null;
    return _auth.signOut();
  }

  Future<String?> getRecaptchaVerification() async {
    final client = clientViaApiKey(GOOGLE_API_KEY);
    final identityToolkit = IdentityToolkitApi(client);
    final res = identityToolkit.relyingparty;

    final recaptchaResponse = await res.getRecaptchaParam();

    final args = RecaptchaArgs(
      siteKey: recaptchaResponse.recaptchaSiteKey!,
      siteToken: recaptchaResponse.recaptchaStoken!,
    );

    final result = await DesktopWebviewAuth.recaptchaVerification(
      args,
      height: 600,
      width: 600,
    );
    return result?.verificationId;
  }

  Future _userCredential(Future<UserCredential?>? futureUser) async {
    final user = futureUser == null ? null : await futureUser;
    ref.read(authProfileProvider.notifier).state = convert2AuthoProfile(user?.user);
  }
}

final authSignInsProvider = Provider<AuthSignIns>((ref) => AuthSignIns(ref));
