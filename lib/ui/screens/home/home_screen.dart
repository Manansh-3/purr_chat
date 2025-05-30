import 'dart:ui';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:chat_app/core/constants/colors.dart';
import 'package:chat_app/ui/screens/home/settings/updates.dart';
import 'package:chat_app/ui/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/core/constants/strings.dart';
import 'package:chat_app/ui/screens/home/friend_search.dart';
import 'package:chat_app/ui/screens/home/chats/chat_screen.dart';
import 'package:chat_app/ui/screens/auth/signup/signup_screen.dart';
import 'package:chat_app/ui/widgets/friend_options_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  bool _hasPendingRequests = false;

  @override
  void initState() {
    super.initState();  
    WidgetsBinding.instance.addObserver(this);
  checkForForceUpdate(context); // Still call it at build-time once
    _checkAuthAndFetchFriends();
    checkPendingRequests();
    loadPrimaryColor();
  }

  @override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

Future<void> checkForForceUpdate(BuildContext context) async {
  final configSnapshot = await FirebaseFirestore.instance
      .collection('app_config')
      .doc('version_control')
      .get();

  if (!configSnapshot.exists) return;

  final config = configSnapshot.data()!;
  final latestVersion = config['latest_version'];
  final forceUpdate = true; // You can also get this dynamically from Firestore
  final updateMessage = config['update_message'] ?? 'Please update the app.';

  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = packageInfo.version;

  if (_compareVersions(currentVersion, latestVersion) < 0 && forceUpdate) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => WillPopScope(
      onWillPop: () async => false, // disables back button
      child: AlertDialog(
        title: const Text("Update Required"),
        content: Text(updateMessage),
        actions: [
          TextButton(
            onPressed: () {
              // Close the app
              if (Platform.isAndroid) {
                SystemNavigator.pop(); // or exit(0);
              } else if (Platform.isIOS) {
                exit(0);
              } else {
                exit(0);
              }
            },
            child: const Text("Exit App"),
          ),
        ],
      ),
    ),
  );
}

}

int _compareVersions(String current, String latest) {
  final currentParts = current.split('.').map(int.parse).toList();
  final latestParts = latest.split('.').map(int.parse).toList();
  for (int i = 0; i < latestParts.length; i++) {
    if (currentParts.length <= i || currentParts[i] < latestParts[i]) return -1;
    if (currentParts[i] > latestParts[i]) return 1;
  }
  return 0;
}


   void _showFriendOptions(BuildContext context, Map<String, dynamic> friend) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FriendOptionsSheet(friend: friend)
    );
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
          'status': data['status'] ?? 'offline', // <-- Add this line
        };
      }).toList();

      if (mounted) {
        setState(() {
          _friends = friends;
          _isLoading = false;
        });
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
             DrawerHeader(
              decoration: BoxDecoration(
                color: primary,
              ),
              child: Text(
                'Purr_chat v2.0.0',
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
         ListTile(
  leading: const Icon(Icons.info_outline),
  title: const Text('About Updates'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdatesSection()),
    );
  },
),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
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
      : RefreshIndicator(
          onRefresh: () async {
            final uid = FirebaseAuth.instance.currentUser?.uid;
            if (uid != null) {
              setState(() {
                _isLoading = true;
              });
              await fetchFriends(uid);
              await checkPendingRequests();
              setState(() {
                _isLoading = false;
              });
            }
          },
  child: _friends.isEmpty
      ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 200),
            Center(
              child: Text(
                'You seem alone',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        )
      : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _friends.length,
          itemBuilder: (context, index) {
            final friend = _friends[index];
            final currentUserId = FirebaseAuth.instance.currentUser!.uid;
            final chatId = [currentUserId, friend['uid']]..sort();
            final consistentChatId = '${chatId[0]}_${chatId[1]}';
            final status = friend['status'];
            

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(consistentChatId)
                  .collection('messages')
                  .where('isRead', isEqualTo: false)
                  .where('receiverId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = snapshot.data?.docs.length ?? 0;

                return GestureDetector(
                  onTap: () {
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
                  onLongPress: () => _showFriendOptions(context, friend),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage: friend['photoUrl'] != ''
                                          ? NetworkImage(friend['photoUrl'])
                                          : null,
                                      child: friend['photoUrl'] == ''
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    if (status == 'online')
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(255, 0, 224, 0),
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend['username'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        friend['bio'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (unreadCount > 0)
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$unreadCount',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  )
else
  const Icon(Icons.arrow_forward_ios_rounded,
      size: 16, color: Colors.white70),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
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
