import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/ui/widgets/loader.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;

  const PublicProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _PublicProfileScreenState createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with TickerProviderStateMixin {
  late String currentUserId;
  bool hasSentRequest = false;
  bool isUserFriend = false;
  bool isLoading = true;
  Map<String, dynamic>? userData;

  late AnimationController _controller;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;

  late Animation<Offset> _aboutSlideAnimation;
  late Animation<double> _aboutFadeAnimation;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _aboutSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _aboutFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    fetchUserDataAndFriendship();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> fetchUserDataAndFriendship() async {
    try {
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final currentSnap = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();

      final currentFriends = List<String>.from(currentSnap.data()?['friends'] ?? []);
      final sentRequests = List<String>.from(currentSnap.data()?['sentRequests'] ?? []);

      setState(() {
        userData = userSnap.data();
        isUserFriend = currentFriends.contains(widget.userId);
        hasSentRequest = sentRequests.contains(widget.userId);
        isLoading = false;
      });

      _controller.forward(); // Start animation
    } catch (e) {
      print("Error fetching user/friends: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> removeFriend() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
      'friends': FieldValue.arrayRemove([widget.userId])
    });

    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'friends': FieldValue.arrayRemove([currentUserId])
    });

    setState(() => isUserFriend = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading || userData == null) {
      return const Scaffold(body: Center(child: Loader()));
    }

    final username = userData!['username'] ?? 'No Name';
    final bio = userData!['bio'] ?? 'No bio provided';
    final photoUrl = userData!['PfpUrl'] ?? '';
    final status = (userData!['status'] ?? 'offline').toString().toLowerCase();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("User Profile")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SlideTransition(
              position: _headerSlideAnimation,
              child: FadeTransition(
                opacity: _headerFadeAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        backgroundColor: Colors.white,
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        username,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status == 'online' ? '🟢 Online' : '⚫ Offline',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SlideTransition(
              position: _aboutSlideAnimation,
              child: FadeTransition(
                opacity: _aboutFadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bio", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Text(bio, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [Text("under work")],
                // children: [
                //   ElevatedButton.icon(
                //     onPressed: () => Navigator.pop(context),
                //     icon: const Icon(Icons.chat),
                //     label: const Text("Message"),
                //     style: ElevatedButton.styleFrom(
                //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                //     ),
                //   ),
                //   OutlinedButton.icon(
                //     onPressed: removeFriend,
                //     icon: Icon(isUserFriend ? Icons.person_remove : Icons.person_add_alt_1),
                //     label: Text(isUserFriend ? "Remove Friend" : "Add Friend"),
                //     style: OutlinedButton.styleFrom(
                //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                //     ),
                //   ),
                // ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
