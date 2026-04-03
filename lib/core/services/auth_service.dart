import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Helper method to create or update base user data in Firestore.
  /// Pass [googleAccount] to also persist the Google display name on first sign-in.
  Future<void> _updateUserFirestore(
    User user, {
    GoogleSignInAccount? googleAccount,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);

    // Base fields always written (merge keeps existing data intact)
    final Map<String, dynamic> data = {
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(), // only set on first create
    };

    // For Google sign-in: persist name from Google profile IF the Firestore
    // document doesn't already have a name set by the user.
    if (googleAccount != null) {
      final snap = await docRef.get();
      final existing = snap.data();
      final hasName = existing != null &&
          ((existing['name'] ?? existing['Name'] ?? '').toString().isNotEmpty);

      if (!hasName && googleAccount.displayName != null && googleAccount.displayName!.isNotEmpty) {
        data['name'] = googleAccount.displayName;
      }
      // Google doesn't provide a phone number, so we leave 'phone' untouched.
    }

    await docRef.set(data, SetOptions(merge: true));
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
    final UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
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
    // 1. Trigger Google Sign-In flow (signOut forces account-picker)
    await _googleSignIn.signOut().catchError((_) {});

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
    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);

    // 4. Create/update Firestore doc — pass googleUser so name is saved
    if (userCredential.user != null) {
      await _updateUserFirestore(
        userCredential.user!,
        googleAccount: googleUser,
      );
    }
    return userCredential;
  }

  /// Sign out from all providers
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
