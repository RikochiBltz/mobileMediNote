import 'package:google_generative_ai/google_generative_ai.dart';

/// Singleton service that holds the Gemini chat session and messages
/// so they persist across navigation while the app is open.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  static const String _geminiApiKey = 'AIzaSyB7JYJTseDer2kWAxQhDigWVEHke_D_k9Y';

  GenerativeModel? _model;
  ChatSession? _chat;
  final List<Map<String, dynamic>> messages = [];
  bool _initialized = false;

  bool get isInitialized => _initialized;

  void initialize({required String userName, required String userRole}) {
    if (_initialized) return;

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(
        'You are MediNote AI, a helpful medical and pharmaceutical assistant chatbot. '
        'You help pharmaceutical delegates, enterprise staff, and admins with questions '
        'about medications, promotions, medical visits, and general pharmaceutical topics. '
        'Keep your answers concise and professional. '
        'The current user is $userName ($userRole).',
      ),
    );
    _chat = _model!.startChat();

    messages.addAll([
      {'sender': 'bot', 'text': 'Hello $userName! 👋', 'type': 'greeting'},
      {
        'sender': 'bot',
        'text': "I'm MediNote AI. How can I help you today?",
        'type': 'message',
      },
    ]);

    _initialized = true;
  }

  ChatSession get chat => _chat!;

  /// Call this on logout to reset the chat history.
  void reset() {
    messages.clear();
    _model = null;
    _chat = null;
    _initialized = false;
  }
}
