import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/user_model.dart';
import '../services/chat_service.dart';
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
  bool _isStreaming = false;
  bool _showScrollToBottom = false;
  bool _isDarkMode = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _voiceOutputEnabled = false;
  bool _isSpeaking = false;
  bool _inclusiveMode = false;

  static const _green = AppDesign.green;
  static const _greenLight = AppDesign.greenLight;
  static const _warning = Color(0xFFE74C3C);

  // Dark mode colors
  static const _darkBg = Color(0xFF121212);
  static const _darkSurface = Color(0xFF1E1E1E);
  static const _darkCard = Color(0xFF2D2D2D);

  late final ChatService _chatService;
  late final stt.SpeechToText _speech;
  late final FlutterTts _tts;

  late AnimationController _bubbleController;
  late Animation<double> _bubbleAnimation;
  List<Map<String, dynamic>> get _chatMessages => _chatService.messages;

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

    _chatService = ChatService.instance;
    _chatService.initialize(
      userName: widget.user.name,
      userRole: widget.user.role,
    );
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initVoice();

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
    _speech.stop();
    _tts.stop();
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

  Future<void> _initVoice() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _isListening = status == 'listening');
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _isListening = false);
        },
      );
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      await _initVoice();
    }
    if (!_speechAvailable) {
      _showVoiceSnack('Speech input is not available on this device.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isListening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _messageController.text = result.recognizedWords;
          _messageController.selection = TextSelection.collapsed(
            offset: _messageController.text.length,
          );
        });
      },
    );
  }

  Future<void> _toggleVoiceOutput() async {
    setState(() => _voiceOutputEnabled = !_voiceOutputEnabled);
    if (_voiceOutputEnabled) {
      final lastAnswer = _lastBotAnswer();
      if (lastAnswer != null) {
        await _speak(lastAnswer);
      }
    } else {
      await _tts.stop();
      setState(() => _isSpeaking = false);
    }
  }

  Future<void> _speak(String text) async {
    final clean = _plainSpeechText(text);
    if (clean.isEmpty) return;
    await _tts.stop();
    if (mounted) setState(() => _isSpeaking = true);
    await _tts.speak(clean);
  }

  void _toggleInclusiveMode() {
    setState(() => _inclusiveMode = !_inclusiveMode);
    HapticFeedback.lightImpact();
  }

  String? _lastBotAnswer() {
    for (final message in _chatMessages.reversed) {
      if (message['sender'] == 'bot' &&
          message['type'] != 'error' &&
          (message['text'] as String? ?? '').trim().isNotEmpty) {
        return message['text'] as String;
      }
    }
    return null;
  }

  String _plainSpeechText(String value) {
    return _normalizeMarkdown(value)
        .replaceAll(RegExp(r'[`*_>#\-\[\]\(\)]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _inclusivePrompt(String message) {
    if (!_inclusiveMode) return message;
    return 'Answer in plain, accessible language for an inclusive workplace. '
        'Avoid unnecessary jargon, define medical or CRM terms briefly, and keep the answer actionable. '
        'User question: $message';
  }

  void _showVoiceSnack(String text) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: _warning));
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
      final answer = await _chatService.sendMessage(_inclusivePrompt(message));
      int wordCount = 0;

      final words = answer.split(RegExp(r'(?<=\s)'));
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
        if (_voiceOutputEnabled) {
          await _speak(_chatMessages[botMessageIndex]['text'] as String);
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isStreaming = false;
          final lastMsg = _chatMessages.last;
          if (lastMsg['streaming'] == true &&
              (lastMsg['text'] as String).isEmpty) {
            _chatMessages.last['text'] = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
            _chatMessages.last['type'] = 'error';
          }
          _chatMessages.last['streaming'] = false;
        });
        _bubbleController.reset();
        _bubbleController.forward();
        _scrollToBottom();
        debugPrint('FastAPI chat error: $e');
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
            'text':
                'New conversation started. Ask me anything about your workflow.',
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
    final currentTime = (currentMessage['time'] as DateTime?) ?? DateTime.now();
    final previousTime =
        (previousMessage['time'] as DateTime?) ?? DateTime.now();
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
        ? [_darkBg.withOpacity(0.5), _darkBg]
        : [_green.withOpacity(0.02), Colors.white];

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
                              _buildDateSeparator(
                                (_chatMessages[index]['time'] as DateTime?) ??
                                    DateTime.now(),
                              ),
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
                      child: Center(child: _buildScrollToBottomButton()),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 430;
              final avatarSize = isCompact ? 38.0 : 44.0;
              final gap = isCompact ? 8.0 : 12.0;
              final actionGap = isCompact ? 6.0 : 8.0;

              return Row(
                children: [
                  _buildBackButton(isCompact),
                  SizedBox(width: gap),

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
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(avatarSize / 2),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: _green,
                        size: isCompact ? 22 : 26,
                      ),
                    ),
                  ),
                  SizedBox(width: gap),

                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MediNote AI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                            Flexible(
                              child: Text(
                                'Online',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: actionGap),

                  _buildHeaderActionButton(
                    _inclusiveMode
                        ? Icons.accessibility_new
                        : Icons.accessibility_new_outlined,
                    'Inclusive mode',
                    _toggleInclusiveMode,
                    compact: isCompact,
                  ),
                  SizedBox(width: actionGap),
                  _buildHeaderActionButton(
                    _voiceOutputEnabled
                        ? Icons.volume_up
                        : Icons.volume_up_outlined,
                    _isSpeaking ? 'Stop voice' : 'Read answers',
                    _toggleVoiceOutput,
                    compact: isCompact,
                  ),
                  SizedBox(width: actionGap),
                  if (isCompact)
                    _buildHeaderMenuButton(isCompact)
                  else ...[
                    _buildHeaderActionButton(
                      Icons.auto_awesome,
                      'New chat',
                      _startNewChat,
                    ),
                    SizedBox(width: actionGap),
                    _buildDarkModeToggle(),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool compact) {
    final size = compact ? 42.0 : 44.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(width: size, height: size),
      ),
    );
  }

  Widget _buildDarkModeToggle({bool compact = false}) {
    final size = compact ? 42.0 : 44.0;

    return Tooltip(
      message: _isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
      child: Container(
        width: size,
        height: size,
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
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size, height: size),
        ),
      ),
    );
  }

  Widget _buildHeaderActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    bool compact = false,
  }) {
    final size = compact ? 42.0 : 44.0;

    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white, size: 22),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size, height: size),
        ),
      ),
    );
  }

  Widget _buildHeaderMenuButton(bool compact) {
    final size = compact ? 42.0 : 44.0;

    return Tooltip(
      message: 'More actions',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: PopupMenuButton<String>(
          tooltip: 'More actions',
          icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
          padding: EdgeInsets.zero,
          color: _isDarkMode ? _darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (value) {
            if (value == 'new_chat') {
              _startNewChat();
            } else if (value == 'theme') {
              _toggleDarkMode();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'new_chat',
              child: _buildHeaderMenuItem(Icons.auto_awesome, 'New chat'),
            ),
            PopupMenuItem(
              value: 'theme',
              child: _buildHeaderMenuItem(
                _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                _isDarkMode ? 'Light mode' : 'Dark mode',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMenuItem(IconData icon, String label) {
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF2C3E50);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: _green),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final separatorBg = _isDarkMode
        ? _darkCard.withOpacity(0.8)
        : _green.withOpacity(0.1);
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
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: isBot
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          // Message bubble with enhanced styling
          GestureDetector(
            onLongPress: () => _showMessageOptions(context, message),
            child: Row(
              mainAxisAlignment: isBot
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBot) ...[
                  _buildBotAvatar(hasError),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: _buildMessageBubble(
                    message: message['text'] as String? ?? '',
                    isBot: isBot,
                    isStreaming: isCurrentlyStreaming,
                    hasError: hasError,
                  ),
                ),
              ],
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
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      margin: EdgeInsets.only(left: isBot ? 0 : 40, right: isBot ? 40 : 0),
      decoration: BoxDecoration(
        gradient: isBot || hasError
            ? null
            : LinearGradient(
                colors: hasError
                    ? [_warning, Color(0xFFE74C3C)]
                    : [_green, _greenLight],
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
                color: _isDarkMode
                    ? Colors.grey[800]!
                    : Colors.grey.withOpacity(0.1),
                width: 1,
              )
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topLeft,
        child: isStreaming && message.isEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TypingIndicator(color: _green),
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBot && !hasError)
                    _buildMarkdownMessage(message, botTextColor)
                  else
                    SelectableText(
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
                  if (isBot && isStreaming && !hasError) ...[
                    const SizedBox(height: 8),
                    _StreamingCursor(color: _green),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildBotAvatar(bool hasError) {
    final color = hasError ? _warning : _green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(_isDarkMode ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Icon(
        hasError ? Icons.error_outline : Icons.auto_awesome,
        size: 17,
        color: color,
      ),
    );
  }

  Widget _buildMarkdownMessage(String message, Color textColor) {
    return MarkdownBody(
      data: _normalizeMarkdown(message),
      selectable: true,
      softLineBreak: true,
      styleSheet: _markdownStyleSheet(textColor),
    );
  }

  MarkdownStyleSheet _markdownStyleSheet(Color textColor) {
    final muted = _isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final codeBg = _isDarkMode
        ? Colors.white.withOpacity(0.08)
        : _green.withOpacity(0.08);

    return MarkdownStyleSheet(
      p: TextStyle(
        color: textColor,
        fontSize: 15,
        height: 1.48,
        fontWeight: FontWeight.w400,
      ),
      pPadding: const EdgeInsets.only(bottom: 4),
      strong: TextStyle(
        color: _isDarkMode ? _greenLight : _green,
        fontWeight: FontWeight.w800,
      ),
      em: TextStyle(color: muted, fontStyle: FontStyle.italic),
      h1: TextStyle(
        color: textColor,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w800,
      ),
      h2: TextStyle(
        color: textColor,
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w800,
      ),
      h3: TextStyle(
        color: _isDarkMode ? _greenLight : _green,
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w800,
      ),
      listBullet: TextStyle(
        color: _isDarkMode ? _greenLight : _green,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w800,
      ),
      listIndent: 18,
      blockSpacing: 8,
      code: TextStyle(
        color: _isDarkMode ? const Color(0xFFE8F5E9) : const Color(0xFF145A32),
        backgroundColor: codeBg,
        fontFamily: 'monospace',
        fontSize: 13,
        height: 1.45,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_isDarkMode ? Colors.white : _green).withOpacity(0.08),
        ),
      ),
      blockquote: TextStyle(
        color: muted,
        fontSize: 14,
        height: 1.45,
        fontStyle: FontStyle.italic,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      blockquoteDecoration: BoxDecoration(
        color: _green.withOpacity(_isDarkMode ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: _green, width: 3)),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(
              0.08,
            ),
          ),
        ),
      ),
    );
  }

  String _normalizeMarkdown(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'^\s*\*\s+', multiLine: true), '- ')
        .replaceAll(RegExp(r'^\s*\u2022\s+', multiLine: true), '- ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Widget _buildQuickReplies() {
    final quickReplyBg = _isDarkMode
        ? _darkCard.withOpacity(0.8)
        : _green.withOpacity(0.1);
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

  void _showMessageOptions(BuildContext context, Map<String, dynamic> message) {
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
            _buildBottomSheetOption(Icons.content_copy, 'Copy text', () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: message['text'] as String));
            }),
            _buildBottomSheetOption(Icons.share, 'Share', () {
              Navigator.pop(context);
              // Share functionality
            }),
            if (message['sender'] != 'bot')
              _buildBottomSheetOption(Icons.delete, 'Delete', () {
                Navigator.pop(context);
                setState(() {
                  _chatMessages.remove(message);
                });
              }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDestructive
              ? _warning.withOpacity(0.1)
              : _green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDestructive ? _warning : _green, size: 22),
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
    final quickActionText = _isDarkMode
        ? Colors.white
        : const Color(0xFF2C3E50);
    final quickActionShadow = _isDarkMode
        ? Colors.transparent
        : _green.withOpacity(0.1);

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
                  .map(
                    (action) => _buildQuickActionChip(
                      action,
                      quickActionBg,
                      quickActionText,
                      quickActionShadow,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    String action,
    Color bgColor,
    Color textColor,
    Color shadowColor,
  ) {
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
    final textFieldBorder = _isDarkMode
        ? Colors.grey[800]!
        : Colors.grey.withOpacity(0.1);
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
                  border: Border.all(color: textFieldBorder, width: 1),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: textColor),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _isStreaming ? null : _sendMessage,
                  decoration: InputDecoration(
                    hintText: 'Ask about medications...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    suffixIcon: IconButton(
                      onPressed: _isStreaming ? null : _toggleListening,
                      tooltip: _isListening
                          ? 'Stop voice input'
                          : 'Voice input',
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? _warning : Colors.grey[400],
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
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    double size = 24,
  }) {
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
  final Color color;

  const _TypingIndicator({required this.color});

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
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
                    color: widget.color.withOpacity(opacity.toDouble()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(
                          opacity.toDouble() * 0.5,
                        ),
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

class _StreamingCursor extends StatefulWidget {
  final Color color;

  const _StreamingCursor({required this.color});

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    )..repeat(reverse: true);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 26,
        height: 3,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
