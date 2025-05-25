import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> sendFriendRequest(String fromUid, String toUid) async {
    final request = {
      'from': fromUid,
      'to': toUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('friend_requests').add(request);
  }

  static Future<void> acceptFriendRequest(String requestId, String fromUid, String toUid) async {
    final batch = _firestore.batch();

    final requestRef = _firestore.collection('friend_requests').doc(requestId);
    final fromUserRef = _firestore.collection('users').doc(fromUid);
    final toUserRef = _firestore.collection('users').doc(toUid);

    batch.update(requestRef, {'status': 'accepted'});
    batch.update(fromUserRef, {
      'friends': FieldValue.arrayUnion([toUid])
    });
    batch.update(toUserRef, {
      'friends': FieldValue.arrayUnion([fromUid])
    });

    await batch.commit();
  }

  static Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friend_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  // Check if a friend request already exists and return the status (e.g., 'pending', 'accepted', 'rejected')
static Future<String> getFriendRequestStatus(String fromUid, String toUid) async {
  final query = await _firestore
      .collection('friend_requests')
      .where('from', isEqualTo: fromUid)
      .where('to', isEqualTo: toUid)
      .orderBy('timestamp', descending: true)
      .limit(1)
      .get();

  if (query.docs.isEmpty) return 'none';

  return query.docs.first['status'];
}

// Check if two users are already friends
static Future<bool> areUsersFriends(String uid1, String uid2) async {
  final doc = await _firestore.collection('users').doc(uid1).get();
  final friends = List<String>.from(doc.data()?['friends'] ?? []);
  return friends.contains(uid2);
}


  static Future<List<Map<String, dynamic>>> getPendingRequests(String toUid) async {
    final query = await _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .get();

    return query.docs.map((doc) {
      return {
        'requestId': doc.id,
        ...doc.data(),
      };
    }).toList();
  }
}
