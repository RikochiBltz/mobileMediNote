import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';
import '../services/theme_provider.dart';
import '../theme/app_design.dart';

class ChatScreen extends StatefulWidget {
  final User user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isStreaming = false;
  bool _showScrollToBottom = false;
  bool _isDarkMode = false;

  static const String _geminiApiKey = 'AIzaSyAW93eq4Z2dCBSj2JOMnTrr5krQ2rTq1FY';
  static const _green = AppDesign.green;
  static const _greenLight = AppDesign.greenLight;
  static const _greenDark = Color(0xFF1E8449);
  static const _accentBlue = Color(0xFF3498DB);
  static const _warning = Color(0xFFE74C3C);

  // Dark mode colors
  static const _darkBg = Color(0xFF121212);
  static const _darkSurface = Color(0xFF1E1E1E);
  static const _darkCard = Color(0xFF2D2D2D);

  late final GenerativeModel _model;
  late final ChatSession _chat;

  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;

  // Quick action suggestions
  final List<String> _quickActions = [
    'Drug interactions',
    'Prescribing info',
    'Visit schedule',
    'Sales data',
  ];

  @override
  void initState() {
    super.initState();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bubbleAnimation = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOutBack,
    );

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(
        'You are MediNote AI, a helpful medical and pharmaceutical assistant chatbot. '
        'You help pharmaceutical delegates, enterprise staff, and admins with questions '
        'about medications, promotions, medical visits, and general pharmaceutical topics. '
        'Keep your answers concise and professional. '
        'The current user is ${widget.user.name} (${widget.user.role}).',
      ),
    );
    _chat = _model.startChat();

    _chatMessages.addAll([
      {
        'sender': 'bot',
        'text': 'Hello ${widget.user.name}! How can I assist you today?',
        'type': 'greeting',
        'time': DateTime.now(),
      },
      {
        'sender': 'bot',
        'text': "I'm MediNote AI. How can I help you today?",
        'type': 'message',
        'time': DateTime.now(),
      },
    ]);

    // Scroll listener for scroll-to-bottom button
    _scrollController.addListener(() {
      FocusScope.of(context).unfocus();
      if (_scrollController.offset >
          _scrollController.position.maxScrollExtent - 200) {
        setState(() {
          _showScrollToBottom = false;
        });
      } else if (_scrollController.offset > 50) {
        setState(() {
          _showScrollToBottom = true;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _bubbleController.forward();
      
      // Sync with global theme
      final themeProvider = ThemeInheritedWidget.of(context);
      if (themeProvider != null) {
        setState(() {
          _isDarkMode = themeProvider.isDarkMode;
        });
        themeProvider.addListener(() {
          if (mounted) {
            setState(() {
              _isDarkMode = themeProvider.isDarkMode;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _bubbleController.dispose();
    super.dispose();
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

  void _scrollToBottomAnimated() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _isStreaming) return;

    setState(() {
      _chatMessages.add({
        'sender': 'user',
        'text': message,
        'type': 'message',
        'time': DateTime.now(),
      });
      _messageController.clear();
      _isStreaming = true;
      _showScrollToBottom = false;
      _chatMessages.add({
        'sender': 'bot',
        'text': '',
        'type': 'message',
        'time': DateTime.now(),
        'streaming': true,
      });
    });
    _scrollToBottom();

    HapticFeedback.lightImpact();

    try {
      final botMessageIndex = _chatMessages.length - 1;
      final responseStream = _chat.sendMessageStream(Content.text(message));
      int wordCount = 0;

      await for (final chunk in responseStream) {
        final text = chunk.text;
        if (text != null && text.isNotEmpty && mounted) {
          final words = text.split(RegExp(r'(?<=\s)'));
          for (final word in words) {
            if (!mounted) break;
            setState(() {
              _chatMessages[botMessageIndex]['text'] += word;
            });
            _scrollToBottom();

            wordCount++;
            if (wordCount % 3 == 0) {
              HapticFeedback.selectionClick();
            }

            await Future.delayed(const Duration(milliseconds: 25));
          }
        }
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _chatMessages[botMessageIndex]['streaming'] = false;
          _isStreaming = false;
          _chatMessages[botMessageIndex]['text'] =
              (_chatMessages[botMessageIndex]['text'] as String).trim();
        });
        _bubbleController.reset();
        _bubbleController.forward();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isStreaming = false;
          final lastMsg = _chatMessages.last;
          if (lastMsg['streaming'] == true &&
              (lastMsg['text'] as String).isEmpty) {
            _chatMessages.last['text'] =
                'Sorry, something went wrong. Please try again.';
            _chatMessages.last['type'] = 'error';
          }
          _chatMessages.last['streaming'] = false;
        });
        _bubbleController.reset();
        _bubbleController.forward();
        _scrollToBottom();
        debugPrint('Gemini API error: $e');
      }
    }
  }

  void _sendQuickAction(String action) {
    final message = action.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    _sendMessage(message);
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    // Also update the global theme
    final themeProvider = ThemeInheritedWidget.of(context);
    if (themeProvider != null) {
      themeProvider.toggleTheme();
    }
    
    HapticFeedback.lightImpact();
  }

  void _startNewChat() {
    setState(() {
      _chatMessages
        ..clear()
        ..addAll([
          {
            'sender': 'bot',
            'text': 'New conversation started. Ask me anything about your workflow.',
            'type': 'greeting',
            'time': DateTime.now(),
          },
        ]);
      _showScrollToBottom = false;
    });
    HapticFeedback.lightImpact();
  }

  bool _shouldShowDateSeparator(int index) {
    if (index == 0) return true;
    final currentMessage = _chatMessages[index];
    final previousMessage = _chatMessages[index - 1];
    final currentTime = currentMessage['time'] as DateTime;
    final previousTime = previousMessage['time'] as DateTime;
    return currentTime.day != previousTime.day ||
        currentTime.month != previousTime.month ||
        currentTime.year != previousTime.year;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Today';
    } else if (date.day == now.day - 1 &&
        date.month == now.month &&
        date.year == now.year) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? _darkBg : Colors.white;
    final chatBgGradient = _isDarkMode
        ? [
            _darkBg.withOpacity(0.5),
            _darkBg,
          ]
        : [
            _green.withOpacity(0.02),
            Colors.white,
          ];
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildHeader(),
            
            // Chat Messages
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: chatBgGradient,
                      ),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 8,
                      ),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        // Show date separator
                        if (_shouldShowDateSeparator(index)) {
                          return Column(
                            key: ValueKey('date_$index'),
                            children: [
                              _buildDateSeparator(_chatMessages[index]['time']),
                              _buildMessage(index),
                            ],
                          );
                        }
                        return _buildMessage(index);
                      },
                    ),
                  ),
                  
                  // Scroll to bottom button
                  if (_showScrollToBottom)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildScrollToBottomButton(),
                      ),
                    ),
                ],
              ),
            ),
            
            // Quick Actions (show only when no messages or at top)
            if (_chatMessages.length <= 2 && !_isStreaming)
              _buildQuickActions(),
            
            // Input Area
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 12),
              
              // Avatar with glow effect
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, _greenLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: _green,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Title and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MediNote AI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              _buildHeaderActionButton(Icons.auto_awesome, 'New chat', _startNewChat),
              const SizedBox(width: 8),
              _buildDarkModeToggle(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle() {
    return Tooltip(
      message: _isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: _toggleDarkMode,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
              size: 22,
              key: ValueKey(_isDarkMode),
            ),
          ),
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white, size: 22),
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final separatorBg = _isDarkMode ? _darkCard.withOpacity(0.8) : _green.withOpacity(0.1);
    final separatorText = _isDarkMode ? _greenLight : _green;
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: separatorBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatDate(date),
        style: TextStyle(
          fontSize: 12,
          color: separatorText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessage(int index) {
    final message = _chatMessages[index];
    final isBot = message['sender'] == 'bot';
    final isCurrentlyStreaming = message['streaming'] == true;
    final hasError = message['type'] == 'error';
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment:
            isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Message bubble with enhanced styling
          GestureDetector(
            onLongPress: () => _showMessageOptions(context, message),
            child: _buildMessageBubble(
              message: message['text'],
              isBot: isBot,
              isStreaming: isCurrentlyStreaming && (message['text'] as String).isEmpty,
              hasError: hasError,
            ),
          ),
          
          // Timestamp and status
          if (!isCurrentlyStreaming && (message['text'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isBot)
                    Icon(
                      message['read'] == true ? Icons.done_all : Icons.done,
                      size: 14,
                      color: _green,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(message['time'] ?? DateTime.now()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          // Quick reply suggestions for bot messages
          if (isBot &&
              !isCurrentlyStreaming &&
              (message['text'] as String).isNotEmpty &&
              !hasError &&
              index == _chatMessages.length - 1)
            _buildQuickReplies(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isBot,
    required bool isStreaming,
    required bool hasError,
  }) {
    final botBubbleColor = _isDarkMode ? _darkCard : const Color(0xFFF8F9FA);
    final botTextColor = _isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    final timestampColor = _isDarkMode ? Colors.grey[500] : Colors.grey[400];
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      margin: EdgeInsets.only(
        left: isBot ? 0 : 40,
        right: isBot ? 40 : 0,
      ),
      decoration: BoxDecoration(
        gradient: isBot || hasError
            ? null
            : LinearGradient(
                colors: hasError ? [_warning, Color(0xFFE74C3C)] : [_green, _greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isBot ? botBubbleColor : (hasError ? _warning : null),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isBot ? 4 : 20),
          topRight: Radius.circular(isBot ? 20 : 4),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(20),
        ),
        boxShadow: _isDarkMode
            ? null
            : [
                BoxShadow(
                  color: (isBot ? Colors.grey : (hasError ? _warning : _green))
                      .withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
        border: isBot
            ? Border.all(
                color: _isDarkMode ? Colors.grey[800]! : Colors.grey.withOpacity(0.1),
                width: 1,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      child: isStreaming && message.isEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: hasError ? Colors.white : _green,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thinking...',
                  style: TextStyle(
                    color: isBot 
                        ? (_isDarkMode ? Colors.grey[400] : Colors.grey[600])
                        : Colors.white,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : SelectableText(
              message,
              style: TextStyle(
                color: isBot
                    ? botTextColor
                    : (hasError ? Colors.white : Colors.white),
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplyBg = _isDarkMode ? _darkCard.withOpacity(0.8) : _green.withOpacity(0.1);
    final quickReplyText = _isDarkMode ? _greenLight : _green;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(left: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickReplyChip('Tell me more', quickReplyBg, quickReplyText),
            const SizedBox(width: 8),
            _buildQuickReplyChip('Examples', quickReplyBg, quickReplyText),
            const SizedBox(width: 8),
            _buildQuickReplyChip('Thanks!', quickReplyBg, quickReplyText),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(String text, Color bgColor, Color textColor) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _sendMessage(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(
      BuildContext context, Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildBottomSheetOption(
              Icons.content_copy,
              'Copy text',
              () {
                Navigator.pop(context);
                Clipboard.setData(
                    ClipboardData(text: message['text'] as String));
              },
            ),
            _buildBottomSheetOption(
              Icons.share,
              'Share',
              () {
                Navigator.pop(context);
                // Share functionality
              },
            ),
            if (message['sender'] != 'bot')
              _buildBottomSheetOption(
                Icons.delete,
                'Delete',
                () {
                  Navigator.pop(context);
                  setState(() {
                    _chatMessages.remove(message);
                  });
                },
                isDestructive: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(
      IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? _warning.withOpacity(0.1)
              : _green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive ? _warning : _green,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? _warning : const Color(0xFF2C3E50),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: Colors.grey[100],
    );
  }

  Widget _buildScrollToBottomButton() {
    return Material(
      color: _green,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: _green.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _scrollToBottomAnimated,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              Text(
                'New messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final quickActionBg = _isDarkMode ? _darkCard : Colors.white;
    final quickActionText = _isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    final quickActionShadow = _isDarkMode ? Colors.transparent : _green.withOpacity(0.1);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickActions
                  .map((action) => _buildQuickActionChip(action, quickActionBg, quickActionText, quickActionShadow))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String action, Color bgColor, Color textColor, Color shadowColor) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        elevation: _isDarkMode ? 0 : 2,
        shadowColor: shadowColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _sendQuickAction(action),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final inputBgColor = _isDarkMode ? _darkSurface : Colors.white;
    final textFieldBg = _isDarkMode ? _darkCard : const Color(0xFFF5F7FA);
    final textFieldBorder = _isDarkMode ? Colors.grey[800]! : Colors.grey.withOpacity(0.1);
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    
    return Container(
      decoration: BoxDecoration(
        color: inputBgColor,
        boxShadow: _isDarkMode
            ? null
            : [
                BoxShadow(
                  color: _green.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: _isDarkMode
            ? Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            _buildInputButton(
              Icons.add_circle_outline,
              'Add attachment',
              () {},
              size: 22,
            ),
            const SizedBox(width: 8),
            
            // Text field with enhanced styling
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: textFieldBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: textFieldBorder,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: textColor),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _isStreaming ? null : _sendMessage,
                  decoration: InputDecoration(
                    hintText: 'Ask about medications...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.mic_none,
                        color: Colors.grey[400],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Send button with animation
            AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isStreaming ? 1.0 : _bubbleAnimation.value,
                  child: child,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isStreaming
                        ? [Colors.grey[400]!, Colors.grey[400]!]
                        : [_green, _greenLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _isStreaming
                      ? null
                      : [
                          BoxShadow(
                            color: _green.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: IconButton(
                  onPressed: _isStreaming
                      ? null
                      : () => _sendMessage(_messageController.text),
                  icon: _isStreaming
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputButton(
      IconData icon, String tooltip, VoidCallback onTap,
      {double size = 24}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.grey[600], size: size),
          padding: const EdgeInsets.all(10),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day && time.month == now.month) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Enhanced Typing indicator widget
class _TypingIndicator extends StatefulWidget {
  final bool isBot;

  const _TypingIndicator({required this.isBot});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final opacity = (_animation.value - delay).clamp(0, 1);
            final scale = (opacity - 0.5).abs() * 2;
            return Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: (widget.isBot ? Colors.grey : Colors.white)
                        .withOpacity(opacity.toDouble()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isBot ? Colors.grey : Colors.white)
                            .withOpacity(opacity.toDouble() * 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

