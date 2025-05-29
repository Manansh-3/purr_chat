import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IncomingRequestsPage extends StatelessWidget {
  const IncomingRequestsPage({super.key});

  Future<void> respondToRequest(String requestId, String action) async {
    await FirebaseFirestore.instance
        .collection('friend_requests')
        .doc(requestId)
        .update({'status': action});

    if (action == 'accepted') {
      final doc = await FirebaseFirestore.instance.collection('friend_requests').doc(requestId).get();
      final fromUid = doc['from'];
      final toUid = doc['to'];

      // Add each other as friends
      await FirebaseFirestore.instance.collection('users').doc(fromUid).update({
        'friends': FieldValue.arrayUnion([toUid])
      });
      await FirebaseFirestore.instance.collection('users').doc(toUid).update({
        'friends': FieldValue.arrayUnion([fromUid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Friend Requests"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('friend_requests')
            .where('to', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No incoming friend requests."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final fromUid = request['from'];
              final requestId = request.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading user..."));
                  }

                  final userData = userSnapshot.data!;
                  final username = userData['username'] ?? 'Unknown';
                  final photoUrl = userData['PfpUrl'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : const AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                    title: Text(username),
                    subtitle: const Text('sent you a friend request'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Accept',
                          onPressed: () => respondToRequest(requestId, 'accepted'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Reject',
                          onPressed: () => respondToRequest(requestId, 'rejected'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
