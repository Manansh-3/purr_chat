import 'dart:io';
import 'dart:math';

import 'package:chat_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chat_app/ui/screens/splash_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}


class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? profilePicUrl;
  bool isLoading = true;

  
  final random = Random();
  late String randomComment;

  @override
  void initState() {
    super.initState();
    randomComment = loadingComments[random.nextInt(loadingComments.length)];
    loadUserData();
  }



  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data()!;

    _usernameController.text = data['username'] ?? '';
    _bioController.text = data['bio'] ?? '';
    profilePicUrl = data['PfpUrl'] ?? '';

    setState(() => isLoading = false);
  }

  Future<void> _pickImageAndUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final ref = FirebaseStorage.instance.ref('PfpUrl/${user.uid}');
    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'PfpUrl': url});
    setState(() => profilePicUrl = url);
  }

  Future<void> _saveChanges() async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }


 


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return  Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             LottieSplashAnimation(),
             LottieLoader(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                randomComment,
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: complimentWhite,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, Color.fromARGB(255, 0, 0, 0), primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(profilePicUrl ?? ''),
                        backgroundColor: Colors.white,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickImageAndUpload,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(5),
                            child: const Icon(Icons.edit, size: 16),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  InfoBlock(
                    icon: Icons.person,
                    label: 'Username',
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your username',
                              hintStyle: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const Icon(Icons.edit, color: Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoBlock(
                    icon: Icons.email,
                    label: 'Email',
                    value: user.email ?? 'your@email.com',
                  ),
                  const SizedBox(height: 12),
                  InfoBlock(
                    icon: Icons.info_outline,
                    label: 'Bio',
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bioController,
                            maxLines: null,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Tell us about yourself...',
                              hintStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                        const Icon(Icons.edit, color: Colors.white70),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: complimentWhite,
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? child;

  const InfoBlock({
    super.key,
    required this.icon,
    required this.label,
    this.value = '',
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                child ??
                    Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
