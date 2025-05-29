import 'package:flutter/material.dart';
import 'package:chat_app/ui/widgets/confirm_dialog.dart';
import 'package:chat_app/ui/widgets/top_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/ui/screens/home/home_screen.dart';


class FriendOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> friend;

  const FriendOptionsSheet({
    super.key,
    required this.friend,
  });

  Future<void> removeFriendMutually(String friendUid) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) throw Exception("No user is logged in");

  final firestore = FirebaseFirestore.instance;

  final currentUserDoc = firestore.collection('users').doc(currentUser.uid);
  final friendUserDoc = firestore.collection('users').doc(friendUid);

  try {
    await Future.wait([
      currentUserDoc.update({
        'friends': FieldValue.arrayRemove([friendUid])
      }),
      friendUserDoc.update({
        'friends': FieldValue.arrayRemove([currentUser.uid])
      }),
    ]);
    print('Both users removed each other successfully');
  } catch (e) {
    print('Error in mutual friend removal: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            Text(
              friend['username'] ?? 'Friend Options',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            _buildListTile(
              context,
              icon: Icons.person_outline,
              label: 'View Profile',
              onTap: () => Navigator.of(context).pop(),
            ),
            _buildListTile(
              context,
              icon: Icons.person_remove_outlined,
              label: 'Remove Friend',
              isDestructive: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Remove Friend?',
                    message: 'Are you sure you want to remove this friend?',
                    confirmText: 'Remove',
                    cancelText: 'Cancel',
                    onConfirm: () {
                      removeFriendMutually(friend['uid']);
                      Navigator.of(context).pop(); // Close the bottom sheet
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(); // Close the dialog if still open
                      }
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                      TopNotification.show(context, 'Friend removed');
                    },
                  ),
                );
              },
            ),
            _buildListTile(
              context,
              icon: Icons.block_outlined,
              label: 'Block',
              isDestructive: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Block User?',
                    message: 'Blocking will prevent interactions.',
                    confirmText: 'Block',
                    cancelText: 'Cancel',
                    onConfirm: () {
                      Navigator.of(context).pop();
                      TopNotification.show(context, 'User blocked');
                    },
                  ),
                );
              },
            ),
            _buildListTile(
              context,
              icon: Icons.report_gmailerrorred_outlined,
              label: 'Report',
              isDestructive: true,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => ConfirmDialog(
                    title: 'Report User?',
                    message: 'Our team will review the report.',
                    confirmText: 'Report',
                    cancelText: 'Cancel',
                    onConfirm: () {
                      Navigator.of(context).pop();
                      TopNotification.show(context, 'User reported');
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildListTile(
              context,
              icon: Icons.close,
              label: 'Cancel',
              isCancel: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isCancel = false,
  }) {
    final textColor = isDestructive
        ? Colors.redAccent
        : isCancel
            ? Colors.black54
            : Colors.black87;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: textColor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isCancel ? FontWeight.bold : FontWeight.w500,
          color: textColor,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.grey[100],
      splashColor: Colors.grey[100],
    );
  }
}
