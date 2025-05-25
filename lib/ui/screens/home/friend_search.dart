import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/services/friends_requests.dart';

class AddFriendDialog extends StatefulWidget {
  const AddFriendDialog({super.key});

  @override
  State<AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<AddFriendDialog> {
  final TextEditingController _searchController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  List<DocumentSnapshot> allUsers = [];
  List<DocumentSnapshot> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final users = snapshot.docs.where((doc) => doc.id != currentUserId).toList();
    setState(() {
      allUsers = users;
      filteredUsers = users;
      isLoading = false;
    });
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = allUsers.where((user) {
        final username = (user['username'] ?? '').toLowerCase();
        return username.contains(query);
      }).toList();
    });
  }

  Future<List<dynamic>> _getUserRelationshipStatus(String otherUid) {
    return Future.wait([
      FriendService.getFriendRequestStatus(currentUserId, otherUid),
      FriendService.areUsersFriends(currentUserId, otherUid),
    ]);
  }

  Widget _buildUserTile(DocumentSnapshot user) {
    final userId = user.id;
    final username = user['username'] ?? 'Unknown';
    final profilePic = user['PfpUrl'];

    return FutureBuilder<List<dynamic>>(
      future: _getUserRelationshipStatus(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text(username),
            trailing: const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.hasError) {
          return ListTile(
            title: Text(username),
            trailing: const Icon(Icons.error, color: Colors.red),
          );
        }

        final status = snapshot.data![0] as String;
        final isFriend = snapshot.data![1] as bool;

        IconData icon;
        VoidCallback? onPressed;
        String tooltip;

        if (isFriend) {
          icon = Icons.check;
          tooltip = 'Already friends';
        } else if (status == 'pending') {
          icon = Icons.hourglass_top;
          tooltip = 'Request pending';
        } else {
          icon = Icons.person_add;
          tooltip = 'Add Friend';
          onPressed = () async {
            await FriendService.sendFriendRequest(currentUserId, userId);
            setState(() {}); // Refresh the tile
          };
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                ? NetworkImage(profilePic)
                : const AssetImage('assets/default_profile.png') as ImageProvider,
          ),
          title: Text(username),
          trailing: IconButton(
            icon: Icon(icon),
            tooltip: tooltip,
            onPressed: onPressed,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Friend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search by username',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          isLoading
              ? const CircularProgressIndicator()
              : SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) =>
                              _buildUserTile(filteredUsers[index]),
                        ),
                ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
