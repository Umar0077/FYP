import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController {
    /// Updates user info fields in Firestore (e.g., name, email, bio, etc.)
    Future<void> updateUserInfo({String? name, String? email, String? bio}) async {
      final user = _auth.currentUser;
      if (user == null) throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
      final String uid = user.uid;
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (bio != null) data['bio'] = bio;
      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(data);
        // Optionally update FirebaseAuth profile
        if (name != null) await user.updateDisplayName(name);
      }
    }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads [file] as the user's avatar. Calls [onProgress] with values 0..1.
  /// Returns the public download URL on success.
  Future<String> uploadAvatar(File file, void Function(double) onProgress) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
    final String uid = user.uid;

    final Reference ref = _storage.ref().child('users/$uid/avatar.jpg');
    final UploadTask uploadTask = ref.putFile(file);

    uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        try {
          onProgress(progress);
        } catch (_) {}
      }
    });

    final TaskSnapshot snapshot = await uploadTask;
    final String url = await snapshot.ref.getDownloadURL();
    await _firestore.collection('users').doc(uid).update({'photoUrl': url});
    return url;
  }
}
