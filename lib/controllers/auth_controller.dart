import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// GetX Controller for Firebase Auth state management
class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Reactive state
  final Rx<User?> _firebaseUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Map<String, dynamic>> userData = Rxn<Map<String, dynamic>>();

  User? get user => _firebaseUser.value;
  bool get isLoggedIn => _firebaseUser.value != null;
  String get userId => _firebaseUser.value?.uid ?? '';
  String get userName {
    if (userData.value != null && userData.value!['name'] != null) {
      return userData.value!['name'] as String;
    }
    return _firebaseUser.value?.displayName ?? 'User';
  }

  @override
  void onInit() {
    super.onInit();
    // Bind to auth state changes
    _firebaseUser.bindStream(_auth.authStateChanges());
    
    // Listen to user changes
    ever(_firebaseUser, _onUserChanged);
  }

  void _onUserChanged(User? user) {
    if (user != null) {
      _fetchUserData(user.uid);
    } else {
      userData.value = null;
    }
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        userData.value = doc.data();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<Map<String, dynamic>?> _findUserByEmail(String email) async {
    final String trimmed = email.trim();
    final String lowered = trimmed.toLowerCase();

    QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty && lowered != trimmed) {
      snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: lowered)
          .limit(1)
          .get();
    }

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.data();
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? dobText,
    DateTime? dobIso,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final User? newUser = cred.user;
      if (newUser == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User creation returned null',
        );
      }

      final String uid = newUser.uid;
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email.trim(),
        'phone': phone ?? '',
        'dob': dobText ?? '',
        'cameraConsentAccepted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'signInMethod': 'email',
      };
      
      if (dobIso != null) {
        userData['dob_iso'] = Timestamp.fromDate(dobIso);
      }

      try {
        await _firestore.collection('users').doc(uid).set(userData);
      } on FirebaseException catch (_) {
        try {
          await newUser.delete();
        } catch (_) {}
        rethrow;
      }

      if (name.isNotEmpty) {
        await newUser.updateDisplayName(name);
        await newUser.reload();
      }

      // Require email ownership verification for email/password users.
      try {
        if (!newUser.emailVerified) {
          await newUser.sendEmailVerification();
        }
      } catch (e) {
        // Non-blocking: login flow also retries sending verification.
        print('Error sending verification email during registration: $e');
      }

      await _auth.signOut();

      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An error occurred. Please try again.';
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({required String email, required String password}) async {
    final String normalizedEmail = email.trim();

    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      User? signedInUser = _auth.currentUser;
      if (signedInUser != null) {
        await signedInUser.reload();
        signedInUser = _auth.currentUser;
      }

      if (signedInUser != null && _usesPasswordProvider(signedInUser) && !signedInUser.emailVerified) {
        try {
          await signedInUser.sendEmailVerification();
        } catch (e) {
          print('Error resending verification email during login: $e');
        }

        await _auth.signOut();
        isLoading.value = false;
        errorMessage.value =
            'Please verify your email first. A verification email has been sent to ${email.trim()}.';
        return false;
      }
      
      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      if (e.code == 'user-not-found') {
        errorMessage.value = 'invalid email and password';
      } else if (e.code == 'invalid-email') {
        errorMessage.value = 'enter a correct email please';
      } else if (e.code == 'wrong-password') {
        errorMessage.value = 'enter correct password please';
      } else if (e.code == 'invalid-credential') {
        final Map<String, dynamic>? userDoc = await _findUserByEmail(normalizedEmail);
        if (userDoc == null) {
          errorMessage.value = 'invalid email and password';
        } else {
          errorMessage.value = 'enter correct password please';
        }
      } else {
        errorMessage.value = _getErrorMessage(e.code);
      }
      return false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An error occurred. Please try again.';
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await signOutGoogle(); // Sign out from Google if signed in
      await _auth.signOut();
      isLoading.value = false;
      Get.offAllNamed('/welcome');
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error logging out';
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      
      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'An error occurred. Please try again.';
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Clear any stale Google session before launching a new sign-in intent.
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        isLoading.value = false;
        return false;
      }

      // Obtain the auth details from the Google Sign-In
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user document exists, create if not
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // Create user document for new Google Sign-In users
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': '',
            'dob': '',
            'photoURL': user.photoURL ?? '',
            'cameraConsentAccepted': false,
            'createdAt': FieldValue.serverTimestamp(),
            'signInMethod': 'google',
          });
        }
      }

      isLoading.value = false;
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      errorMessage.value = _getErrorMessage(e.code);
      return false;
    } on PlatformException catch (e) {
      isLoading.value = false;
      final String details = '${e.message ?? e.details ?? ''}';
      if (e.code == 'sign_in_failed' && details.contains('ApiException: 10')) {
        errorMessage.value = 'Google Sign-In OAuth is misconfigured for this Android build (ApiException 10). In Firebase, ensure SHA-1/SHA-256 are registered and no other project is using the same package + SHA fingerprint combination, then download a fresh google-services.json and rebuild.';
      } else {
        errorMessage.value = 'Google Sign-In failed. Please try again.';
      }
      print('Google Sign-In platform error: $e');
      return false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Google Sign-In failed. Please try again.';
      print('Google Sign-In error: $e');
      return false;
    }
  }

  /// Sign out from Google (if signed in with Google)
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  /// Returns true when the current user must accept camera consent before accessing the app.
  Future<bool> requiresCameraConsent() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    final DocumentReference<Map<String, dynamic>> userRef =
        _firestore.collection('users').doc(currentUser.uid);

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await userRef.get();

      if (!doc.exists) {
        await userRef.set({
          'name': currentUser.displayName ?? '',
          'email': currentUser.email ?? '',
          'photoURL': currentUser.photoURL ?? '',
          'cameraConsentAccepted': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      }

      final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
      final bool accepted = data['cameraConsentAccepted'] == true;

      if (!accepted && !data.containsKey('cameraConsentAccepted')) {
        await userRef.set({
          'cameraConsentAccepted': false,
        }, SetOptions(merge: true));
      }

      return !accepted;
    } catch (e) {
      // Fail-safe: require consent if state cannot be read.
      print('Error checking camera consent: $e');
      return true;
    }
  }

  /// Returns whether the currently signed-in user can continue app session.
  /// For password users, email verification is mandatory.
  Future<bool> canAccessWithCurrentSession() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    await currentUser.reload();
    currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    if (_usesPasswordProvider(currentUser) && !currentUser.emailVerified) {
      await _auth.signOut();
      return false;
    }

    return true;
  }

  bool _usesPasswordProvider(User user) {
    return user.providerData.any((info) => info.providerId == 'password');
  }

  /// Marks camera consent as accepted for the current user.
  Future<void> acceptCameraConsent() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
    }

    await _firestore.collection('users').doc(currentUser.uid).set({
      'cameraConsentAccepted': true,
      'cameraConsentAcceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _fetchUserData(currentUser.uid);
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'invalid email and password';
      case 'wrong-password':
        return 'enter correct password please';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'enter a correct email please';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Operation not allowed.';
      default:
        return 'Authentication error. Please try again.';
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}

