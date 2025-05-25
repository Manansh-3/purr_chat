import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/core/constants/strings.dart';
import 'package:chat_app/ui/screens/home/friend_search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        break;
      case 1:
        showDialog(context: context, builder: (_) => const AddFriendDialog());
        break;
      case 2:
        Navigator.pushNamed(context, profile);
        break;
    }
  }

  Future<void> fetchFriends() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _friends = [];
        _isLoading = false;
      });
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final friendIds = List<String>.from(userDoc.data()?['friends'] ?? []);

    if (friendIds.isEmpty) {
      setState(() {
        _friends = [];
        _isLoading = false;
      });
      return;
    }

    final friendDocs = await Future.wait(friendIds.map((id) =>
        FirebaseFirestore.instance.collection('users').doc(id).get()));

    final friends = friendDocs
        .where((doc) => doc.exists)
        .map((doc) => {
              'uid': doc.id,
              'username': doc['username'] ?? 'Unknown',
              'bio': doc['bio'] ?? '',
              'photoUrl': doc['PfpUrl'] ?? '',
            })
        .toList();

    setState(() {
      _friends = friends;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              fetchFriends();
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, pendingRequests),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(
                  child: Text(
                    'You seem alone',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend['photoUrl'] != ''
                            ? NetworkImage(friend['photoUrl'])
                            : null,
                        child: friend['photoUrl'] == '' ? const Icon(Icons.person) : null,
                      ),
                      title: Text(friend['username']),
                      subtitle: Text(friend['bio']),
                      onTap: () {
                        // Navigate to DM screen or similar
                      },
                    );
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _onItemTapped(0),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(
                Icons.person,
                color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
              ),
              onPressed: () => _onItemTapped(2),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onItemTapped(1),
        tooltip: 'Add Friend',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
