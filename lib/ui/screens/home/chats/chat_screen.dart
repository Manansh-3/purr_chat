import 'package:chat_app/core/constants/colors.dart';
import 'package:chat_app/ui/widgets/loader.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:shared_preferences/shared_preferences.dart';


class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUsername;

  const ChatScreen({
    required this.otherUserId,
    required this.otherUsername,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
late final String chatId;
final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
final AudioPlayer _audioPlayer = AudioPlayer();

final String messageRecieve = "sfx/mixkit-sweet-kitty-meow-93.wav";

bool chatSoundsEnabled = true; // Default value, will be loaded from preferences

void playNotificationSound() async {
  await _audioPlayer.play(AssetSource(messageRecieve));
}


  @override
  void initState() {
    super.initState();
    chatId = getChatId(currentUserId, widget.otherUserId);

    // Load chat sound preference asynchronously
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        chatSoundsEnabled = prefs.getBool('chatSoundsEnabled') ?? true;
      });
    });

    // Mark unread messages as read every few seconds (in real apps, use listeners or logic on snapshot)
    Future.delayed(Duration(milliseconds: 500), () => markMessagesAsRead());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String getChatId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  void markMessagesAsRead() async {
    final unreadMessages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    await messagesRef.add({
      'senderId': currentUserId,
      'receiverId': widget.otherUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    await chatRef.set({
      'participants': [currentUserId, widget.otherUserId],
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    
    
  
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messagesQuery = chatRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteFont),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.otherUsername, style: const TextStyle(color: whiteFont)),
        backgroundColor: primary,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Loader());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Say Hi 👋"));
                }

                final messages = snapshot.data!.docs;

                if (messages.isNotEmpty) {
                      final latest = messages.first;

                      final isIncoming = latest['receiverId'] == currentUserId;
                      final isUnread = latest['isRead'] == false;

  // Play sound only for incoming and unread messages
  if (isIncoming && isUnread && chatSoundsEnabled) {
    playNotificationSound();
  }
}


                // Read messages once loaded
                WidgetsBinding.instance.addPostFrameCallback((_) => markMessagesAsRead());

                return ListView.builder(
  reverse: true,
  controller: _scrollController,
  itemCount: messages.length,
  itemBuilder: (context, index) {
    final message = messages[index];
    final isMe = message['senderId'] == currentUserId;
    final text = message['text'] ?? '';
    final timestamp = message['timestamp'] as Timestamp?;
    final isRead = message['isRead'] ?? false;

    bool showSeen = false;

    // If this is the most recent message sent by me and it has been read
    if (isMe && index == 0 && isRead) {
      showSeen = true;
    }

    return ChatBubble(
      text: text,
      isMe: isMe,
      timestamp: formatTimestamp(timestamp),
      showSeen: showSeen,
    );
  },
);

              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              color: primary,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      autofocus: true,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: primary),
                      onPressed: sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String timestamp;
  final bool showSeen;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.showSeen,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(2), // WhatsApp tail effect
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(2), // WhatsApp tail effect
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe ? primary : Colors.grey.shade200,
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (showSeen)
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 4),
                child: Text(
                  "Seen",
                  style: TextStyle(fontSize: 12, color: primary, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


