import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/facebook.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/identitytoolkit/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

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

const TWITTER_API_KEY = 'YEXSiWv5UeCHyy0c61O2LBC3B';
const TWITTER_API_SECRET_KEY = 'DOd9dCCRFgtnqMDQT7A68YuGZtvcO4WP1mEFS4mEJAUooM4yaE';

// https://developers.facebook.com/apps/247034373023561/fb-login/settings/
// Client OAuth settings:
// Web OAuth login + Client OAuth login
// Valid OAuth Redirect URIs
const FACEBOOK_CLIENT_ID = '247034373023561';

// *************************************************************************************************

final googleSignInArgs = GoogleSignInArgs(
  clientId: GOOGLE_CLIENT_ID,
  redirectUri: REDIRECT_URI,
  scope: 'https://www.googleapis.com/auth/plus.me',
);

final facebookSignInArgs = FacebookSignInArgs(
  clientId: FACEBOOK_CLIENT_ID,
  redirectUri: REDIRECT_URI,
);

Future<UserCredential?> onGoogleSignIn() async {
  final result = await DesktopWebviewAuth.signIn(googleSignInArgs);
  if (result == null) return null;
  final credential = GoogleAuthProvider.credential(
    idToken: result.idToken,
    accessToken: result.accessToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}

Future<UserCredential?> onFacebookSignIn() async {
  final result = await DesktopWebviewAuth.signIn(facebookSignInArgs);
  if (result == null) return null;
  final credential = FacebookAuthProvider.credential(result.accessToken!);
  return FirebaseAuth.instance.signInWithCredential(credential);
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
