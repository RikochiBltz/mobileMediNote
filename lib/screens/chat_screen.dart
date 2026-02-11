import 'package:flutter/material.dart';
import '../models/user_model.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [
    {
      'sender': 'bot',
      'text': 'Hello ${DateTime.now().hour < 12 ? "Ahmed" : "Ahmed"}!',
      'type': 'greeting',
    },
    {'sender': 'bot', 'text': 'How can I help you today?', 'type': 'question'},
  ];

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': message, 'type': 'message'});
      _messageController.clear();

      // Simulate bot response
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'sender': 'bot',
              'text':
                  'Hey, can you give me information about current vitamin promotions?',
              'type': 'promotion_question',
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _chatMessages.add({
                    'sender': 'bot',
                    'text':
                        'Of course! Here are the current vitamin promotions:\n\n• Vitamin C 20% until April 30\n• Vitamin D offer: Buy 2, get the 3rd free until May 2',
                    'type': 'promotion_response',
                  });
                });
              }
            });
          });
        }
      });
    });
  }

  void _handlePromotionAction(bool send) {
    setState(() {
      if (send) {
        _chatMessages.add({
          'sender': 'bot',
          'text': 'Thank you! Details have been sent by email.',
          'type': 'confirmation',
        });
      } else {
        _chatMessages.add({
          'sender': 'bot',
          'text': 'Understood, you can ask for them later.',
          'type': 'message',
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Chatbot',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF27AE60),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Chat Interface
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[index];
                  final isBot = message['sender'] == 'bot';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: isBot
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.end,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isBot
                                ? Colors.grey[100]
                                : const Color(0xFF27AE60),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color: isBot ? Colors.black : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Promotion buttons après le message de promotion
                        if (message['type'] == 'promotion_response')
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _handlePromotionAction(true),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Yes, send email'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF27AE60),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () =>
                                      _handlePromotionAction(false),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF27AE60),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'No, later',
                                    style: TextStyle(color: Color(0xFF27AE60)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Input area
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Write a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  backgroundColor: const Color(0xFF27AE60),
                  onPressed: () => _sendMessage(_messageController.text),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
