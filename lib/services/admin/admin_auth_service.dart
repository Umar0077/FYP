import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminAuthService {
  AdminAuthService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static final RxBool _isAdminLoggedIn = false.obs;
  static final RxMap<String, dynamic> _currentAdmin = <String, dynamic>{}.obs;

  static bool get isAdminLoggedIn => _isAdminLoggedIn.value;

  static Map<String, dynamic> get currentAdminData =>
      Map<String, dynamic>.from(_currentAdmin);

  static String get currentAdminIdentifier {
    return (_currentAdmin['id'] ?? _currentAdmin['email'] ?? '').toString();
  }

  Future<bool> isCurrentUserAdmin() async {
    if (isAdminLoggedIn) return true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isAdminLoggedIn.value = false;
      _currentAdmin.clear();
      return false;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final role = (userDoc.data()?['role'] ?? '').toString().toLowerCase();
      if (role == 'admin') {
        _isAdminLoggedIn.value = true;
        _currentAdmin.assignAll(<String, dynamic>{
          'id': user.uid,
          'email': (user.email ?? '').trim().toLowerCase(),
          ...?userDoc.data(),
        });
        return true;
      }
    } catch (_) {
      // Fall back to admin collection check below.
    }

    final normalizedEmail = (user.email ?? '').trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      _isAdminLoggedIn.value = false;
      _currentAdmin.clear();
      return false;
    }

    final adminSnapshot = await _firestore
        .collection('admin')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (adminSnapshot.docs.isEmpty) {
      _isAdminLoggedIn.value = false;
      _currentAdmin.clear();
      return false;
    }

    final adminDoc = adminSnapshot.docs.first;
    _isAdminLoggedIn.value = true;
    _currentAdmin.assignAll(<String, dynamic>{
      'id': adminDoc.id,
      'email': normalizedEmail,
      ...adminDoc.data(),
    });
    return true;
  }

  Future<Map<String, dynamic>> signInAdmin({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    UserCredential credential;
    try {
      credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );
    } on FirebaseAuthException {
      throw Exception('invalid-admin-credentials');
    }

    final user = credential.user;
    if (user == null) {
      throw Exception('invalid-admin-credentials');
    }

    final snapshot = await _firestore
        .collection('admin')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await FirebaseAuth.instance.signOut();
      throw Exception('admin-not-registered');
    }

    final doc = snapshot.docs.first;
    final data = doc.data();
    final storedPassword = (data['password'] ?? '').toString();
    final storedEmail = (data['email'] ?? '').toString().trim().toLowerCase();

    final isMatch = storedEmail == normalizedEmail &&
        storedPassword == normalizedPassword;

    if (!isMatch) {
      await FirebaseAuth.instance.signOut();
      throw Exception('invalid-admin-credentials');
    }

    await _firestore.collection('users').doc(user.uid).set(<String, dynamic>{
      'email': normalizedEmail,
      'role': 'admin',
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final adminPayload = <String, dynamic>{
      'id': user.uid,
      'email': storedEmail,
      ...data,
    };

    _isAdminLoggedIn.value = true;
    _currentAdmin.assignAll(adminPayload);

    log(
      'Admin signed in. uid=${user.uid} email=$storedEmail',
      name: 'AdminAuthService',
    );

    return adminPayload;
  }

  Future<void> signOutAdmin() async {
    _isAdminLoggedIn.value = false;
    _currentAdmin.clear();
    log('Admin session cleared', name: 'AdminAuthService');
  }

  Future<void> restoreAdminSessionByEmail(String email) async {
    if (isAdminLoggedIn) return;
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;

    final snapshot = await _firestore
        .collection('admin')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final doc = snapshot.docs.first;
    _isAdminLoggedIn.value = true;
    _currentAdmin.assignAll(<String, dynamic>{
      'id': doc.id,
      ...doc.data(),
    });
  }
}
