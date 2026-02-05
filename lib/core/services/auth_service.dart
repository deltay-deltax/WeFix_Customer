import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Helper method to create or update user data in Firestore
  Future<void> _updateUserFirestore(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);

    await docRef.set(
      {
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt':
            FieldValue.serverTimestamp(), // This is only set on creation
      },
      SetOptions(merge: true),
    ); // merge:true ensures we don't overwrite existing data
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    // 1. Create user in Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Create user document in Firestore
    if (userCredential.user != null) {
      await _updateUserFirestore(userCredential.user!);
    }
    return userCredential;
  }

  /// Sign in or Sign up with Google
  Future<UserCredential> signInWithGoogle() async {
    // 1. Trigger Google Sign-In flow
    // The signOut call here is sometimes used to force account selection
    await _googleSignIn.signOut().catchError(
          (_) {},
        ); // Ignore errors if already signed out

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In aborted by user.');
    }

    // 2. Get auth tokens
    final GoogleSignInAuthentication? googleAuth =
        await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // 3. Sign in to Firebase Auth
    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );

    // 4. Create/update user document in Firestore
    if (userCredential.user != null) {
      await _updateUserFirestore(userCredential.user!);
    }
    return userCredential;
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
