import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: '27337715108-mlpbfjir7f6mr95j70tfdadmisqimpgg.apps.googleusercontent.com', // <-- Web client ID here
      scopes: ['email'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // User cancelled the sign-in
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  } catch (e) {
    print('Google sign-in error: $e');
    return null;
  }
}
}
