import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);

    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'username': user.displayName ?? '',
        'bio': 'meowlow!, i am ${user.displayName}',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'online',
        'lastActive': FieldValue.serverTimestamp(),
        'PfpUrl': user.photoURL ?? '',
      })
      .then((_) {
        print('account created successfully');
      }).catchError((error) {
        print('Failed to create user account: $error');
      });
    }
  }
}
