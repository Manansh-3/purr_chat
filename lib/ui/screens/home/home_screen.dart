import 'package:chat_app/core/constants/colors.dart';
import 'package:chat_app/ui/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/core/constants/strings.dart';
import 'package:chat_app/ui/screens/home/friend_search.dart';
import 'package:chat_app/ui/screens/home/chats/chat_screen.dart';
import 'package:chat_app/ui/screens/auth/signup/signup_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chat_app/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  Set<String> _notifiedChats = {};
  bool _hasPendingRequests = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndFetchFriends();
    checkPendingRequests();
  }

  void setupRealtimeMessageListeners() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userId = currentUser.uid;

    for (var friend in _friends) {
      final friendId = friend['uid'];
      final chatId = userId.compareTo(friendId) < 0
          ? '$userId$friendId'
          : '${friendId}_$userId';

      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          final senderId = data['senderId'];
          final isRead = data['isRead'];

          if (senderId != userId && !isRead) {
            if (!_notifiedChats.contains(chatId)) {
              RemoteMessage testMessage = RemoteMessage(
                notification: RemoteNotification(
                  title: "${friend['username']}",
                  body: data['text'] ?? 'You have a new message!',
                ),
                data: {'chatId': chatId},
              );
              NotificationService.showNotification(testMessage);
              _notifiedChats.add(chatId);
            }
          }
        }
      });
    }
  }

  void clearChatNotification(String chatId) {
    _notifiedChats.remove(chatId);
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

  Future<void> _checkAuthAndFetchFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      });
      return;
    }
    await fetchFriends(user.uid);
  }

  Future<void> checkPendingRequests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('friend_requests')
        .where('to', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (mounted) {
      setState(() {
        _hasPendingRequests = snapshot.docs.isNotEmpty;
      });
    }
  }

  Future<void> fetchFriends(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        if (mounted) {
          setState(() {
            _friends = [];
            _isLoading = false;
          });
        }
        return;
      }

      final friendIds = List<String>.from(userDoc.data()?['friends'] ?? []);
      if (friendIds.isEmpty) {
        if (mounted) {
          setState(() {
            _friends = [];
            _isLoading = false;
          });
        }
        return;
      }

      final friendDocs = await Future.wait(friendIds.map((id) {
        return FirebaseFirestore.instance.collection('users').doc(id).get();
      }));

      final friends = friendDocs.where((doc) => doc.exists).map((doc) {
        final data = doc.data()!;
        return {
          'uid': doc.id,
          'username': data['username'] ?? 'Unknown',
          'bio': data['bio'] ?? '',
          'photoUrl': data['PfpUrl'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
        setupRealtimeMessageListeners();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: primary,
              ),
              child: Text(
                'Purr_chat v1.0.0',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
           
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('user preferences'),
              onTap: ()  {
                Navigator.pushNamed(
                  context,
                  userPreferences
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                fetchFriends(uid);
                checkPendingRequests();
              }
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, pendingRequests);
                },
              ),
              if (_hasPendingRequests)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: Loader())
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
                    final currentUserId =
                        FirebaseAuth.instance.currentUser!.uid;
                    final chatId = currentUserId.compareTo(friend['uid']) < 0
                        ? '$currentUserId${friend['uid']}'
                        : '${friend['uid']}_$currentUserId';

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .collection('messages')
                          .where('isRead', isEqualTo: false)
                          .where('receiverId', isEqualTo: currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int unreadCount = snapshot.data?.docs.length ?? 0;

                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: friend['photoUrl'] != ''
                                    ? NetworkImage(friend['photoUrl'])
                                    : null,
                                child: friend['photoUrl'] == ''
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(friend['username']),
                          subtitle: Text(friend['bio']),
                          onTap: () {
                            clearChatNotification(chatId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  otherUserId: friend['uid'],
                                  otherUsername: friend['username'],
                                ),
                              ),
                            );
                          },
                        );
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
                color: _selectedIndex == 0 ? primary : Colors.grey,
              ),
              onPressed: () => _onItemTapped(0),
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: Icon(
                Icons.person,
                color: _selectedIndex == 2 ? primary : Colors.grey,
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
