import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
      if (name != null) await user.updateDisplayName(name);
    }
  }

  /// Uploads [file] as the user's avatar. Calls [onProgress] with values 0..1.
  /// Returns the public download URL on success.
  Future<String> uploadAvatar(File file, void Function(double) onProgress) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user', message: 'Not signed in');
    final String uid = user.uid;

    // Use a timestamped filename to avoid stale image caching.
    final String fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String storagePath = 'users/$uid/$fileName';
    final String projectId = Firebase.app().options.projectId;

    final List<FirebaseStorage> storageCandidates = <FirebaseStorage>[
      _storage,
      FirebaseStorage.instanceFor(bucket: 'gs://$projectId.appspot.com'),
      FirebaseStorage.instanceFor(bucket: 'gs://$projectId.firebasestorage.app'),
    ];

    FirebaseException? lastStorageError;
    Object? lastError;
    String? url;
    String? usedBucket;

    for (final FirebaseStorage storage in storageCandidates) {
      StreamSubscription<TaskSnapshot>? sub;
      try {
        final Reference ref = storage.ref().child(storagePath);
        final UploadTask uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Consume errors on the stream so failed uploads do not surface as unhandled exceptions.
        sub = uploadTask.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
            try {
              onProgress(progress);
            } catch (_) {}
          }
        }, onError: (_) {});

        final TaskSnapshot snapshot = await uploadTask;
        url = await snapshot.ref.getDownloadURL();
        usedBucket = storage.bucket;
        break;
      } on FirebaseException catch (e) {
        lastStorageError = e;
        // These usually indicate bucket mismatch; try next candidate bucket.
        if (e.code == 'object-not-found' || e.code == 'bucket-not-found' || e.code == 'unknown') {
          continue;
        }
        rethrow;
      } catch (e) {
        lastError = e;
      } finally {
        await sub?.cancel();
      }
    }

    if (url == null) {
      if (lastStorageError != null) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message:
              'Avatar upload failed for all configured buckets. Check Firebase Storage bucket settings for project "$projectId" and ensure Storage is enabled. Last error: ${lastStorageError.code}',
        );
      }
      throw Exception('Avatar upload failed. ${lastError ?? ''}'.trim());
    }

    await _firestore.collection('users').doc(uid).set({
      'photoUrl': url,
      'photoURL': url,
      'avatarStoragePath': storagePath,
      if (usedBucket != null) 'avatarBucket': usedBucket,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updatePhotoURL(url);
    await user.reload();
    return url;
  }
}
