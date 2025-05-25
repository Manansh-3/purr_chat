import 'package:chat_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String chatId;

  @override
  void initState() {
    super.initState();
    chatId = getChatId(currentUserId, widget.otherUserId);
  }

  String getChatId(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  void sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    await messagesRef.add({
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'participants': [currentUserId, widget.otherUserId],
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('h:mm a').format(date); // e.g. 3:45 PM
  }

  @override
  Widget build(BuildContext context) {
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    final messagesQuery =
        chatRef.collection('messages').orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteFont),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.otherUsername, style: TextStyle(color: whiteFont)),
        backgroundColor: primary,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesQuery.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message['senderId'] == currentUserId;
                    final text = message['text'];
                    final timestamp = message['timestamp'] as Timestamp?;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? primary : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe
                                  ? const Radius.circular(16)
                                  : const Radius.circular(0),
                              bottomRight: isMe
                                  ? const Radius.circular(0)
                                  : const Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(1, 2),
                              ),
                            ],
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
                                formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe
                                      ? Colors.white70
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: primary,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
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
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
