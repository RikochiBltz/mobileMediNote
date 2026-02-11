import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isStreaming = false;

  late final ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService.instance;
    _chatService.initialize(
      userName: widget.user.name,
      userRole: widget.user.role,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isStreaming) return;

    setState(() {
      _chatService.messages.add({
        'sender': 'user',
        'text': message,
        'type': 'message',
      });
      _messageController.clear();
      _isStreaming = true;
      // Add an empty bot message that will be filled word by word
      _chatService.messages.add({
        'sender': 'bot',
        'text': '',
        'type': 'message',
        'streaming': true,
      });
    });
    _scrollToBottom();

    // Light haptic to confirm send
    HapticFeedback.lightImpact();

    try {
      final botMessageIndex = _chatService.messages.length - 1;
      final responseStream = _chatService.chat.sendMessageStream(
        Content.text(message),
      );
      int wordCount = 0;

      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty && mounted) {
          // Animate word by word
          final words = text.split(RegExp(r'(?<=\s)'));
          for (final word in words) {
            if (!mounted) break;
            setState(() {
              _chatService.messages[botMessageIndex]['text'] += word;
            });
            _scrollToBottom();

            // Haptic feedback every few words like ChatGPT
            wordCount++;
            if (wordCount % 3 == 0) {
              HapticFeedback.selectionClick();
            }

            // Small delay between words for the typewriter effect
            await Future.delayed(const Duration(milliseconds: 25));
          }
        }
      }

      if (mounted) {
        // Final haptic to signal completion
        HapticFeedback.mediumImpact();
        setState(() {
          _chatService.messages[botMessageIndex]['streaming'] = false;
          _isStreaming = false;
          // Trim any trailing whitespace
          _chatService.messages[botMessageIndex]['text'] =
              (_chatService.messages[botMessageIndex]['text'] as String).trim();
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isStreaming = false;
          final lastMsg = _chatService.messages.last;
          if (lastMsg['streaming'] == true &&
              (lastMsg['text'] as String).isEmpty) {
            _chatService.messages.last['text'] =
                'Sorry, something went wrong. Please try again.';
            _chatService.messages.last['type'] = 'error';
          }
          _chatService.messages.last['streaming'] = false;
        });
        _scrollToBottom();
        debugPrint('Gemini API error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MediNote AI',
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
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _chatService.messages.length,
                itemBuilder: (context, index) {
                  final message = _chatService.messages[index];
                  final isBot = message['sender'] == 'bot';
                  final isCurrentlyStreaming = message['streaming'] == true;

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
                          child:
                              isCurrentlyStreaming &&
                                  (message['text'] as String).isEmpty
                              // Thinking indicator while waiting for first token
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Thinking...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: SelectableText(
                                        message['text'],
                                        style: TextStyle(
                                          color: isBot
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    // Blinking cursor while streaming
                                    if (isCurrentlyStreaming)
                                      const _BlinkingCursor(),
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
                    textInputAction: TextInputAction.send,
                    onSubmitted: _isStreaming ? null : _sendMessage,
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
                  backgroundColor: _isStreaming
                      ? Colors.grey
                      : const Color(0xFF27AE60),
                  onPressed: _isStreaming
                      ? null
                      : () => _sendMessage(_messageController.text),
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
    _scrollController.dispose();
    super.dispose();
  }
}

/// A blinking cursor widget shown at the end of streaming text
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: 2,
            height: 16,
            margin: const EdgeInsets.only(left: 2, bottom: 1),
            color: Colors.black54,
          ),
        );
      },
    );
  }
}
