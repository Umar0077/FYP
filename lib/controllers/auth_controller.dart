import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        'createdAt': FieldValue.serverTimestamp(),
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
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
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

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
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

