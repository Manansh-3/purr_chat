import 'dart:ui';
import 'package:chat_app/ui/widgets/loader.dart';
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
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      final users = snapshot.docs.where((doc) => doc.id != currentUserId).toList();
      setState(() {
        allUsers = users;
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      // You can also show a snackbar or error dialog here if you want.
    }
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
            leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
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
            leading: CircleAvatar(
              backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                  ? NetworkImage(profilePic)
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
            ),
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
          onPressed = null;
        } else if (status == 'pending') {
          icon = Icons.hourglass_top;
          tooltip = 'Request pending';
          onPressed = null;
        } else {
          icon = Icons.person_add;
          tooltip = 'Add Friend';
          onPressed = () async {
            await FriendService.sendFriendRequest(currentUserId, userId);
            setState(() {}); // Refresh UI after sending request
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
    return Stack(
      children: [
        // The blurred background:
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            color: Colors.black.withOpacity(0), // transparent but captures taps
          ),
        ),

        // Centered dialog
        Center(
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 16,
            backgroundColor: Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width * 1,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                minHeight: 300,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Add Friend',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by username',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User list or loading indicator
                  Expanded(
                    child: isLoading
                        ? const Center(child: Loader(backgroundColor: Colors.white,))
                        : filteredUsers.isEmpty
                            ? const Center(child: Text('No users found'))
                            : ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) =>
                                    _buildUserTile(filteredUsers[index]),
                              ),
                  ),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
