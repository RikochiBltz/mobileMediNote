import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/theme_provider.dart';

class EnterpriseDashboard extends StatefulWidget {
  final User user;

  const EnterpriseDashboard({super.key, required this.user});

  @override
  State<EnterpriseDashboard> createState() => _EnterpriseDashboardState();
}

class _EnterpriseDashboardState extends State<EnterpriseDashboard> {
  int _selectedTab = 0;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [
    {
      'sender': 'bot',
      'text': 'Bonjour Admin! 👋 Bienvenue sur PharmaCare. Je suis votre assistant IA.',
    },
  ];
  bool _isDarkMode = false;

  static const _green = Color(0xFF27AE60);
  static const _greenLight = Color(0xFF52BE80);
  static const _greenDark = Color(0xFF1E8449);

  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({'sender': 'user', 'text': message});
      _messageController.clear();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'sender': 'bot',
              'text': 'Je comprends. Analysons vos données d\'entreprise...',
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    final secondaryTextColor = _isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final tabBackgroundColor = _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    
    return Scaffold(
      body: Column(
        children: [
          // Custom Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_green, _greenLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.4),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_pharmacy,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Centre de Gestion',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'PharmaCare Enterprise',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout, color: Colors.white, size: 22),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tab Buttons
          Container(
            decoration: BoxDecoration(
              color: tabBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? _green.withOpacity(0.1) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0 ? _green : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? _green : (_isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.assistant,
                              color: _selectedTab == 0 ? Colors.white : (_isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Assistant IA',
                            style: TextStyle(
                              color: _selectedTab == 0 ? _green : (_isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                              fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? _green.withOpacity(0.1) : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1 ? _green : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? _green : (_isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.dashboard,
                              color: _selectedTab == 1 ? Colors.white : (_isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Analytics',
                            style: TextStyle(
                              color: _selectedTab == 1 ? _green : (_isDarkMode ? Colors.grey[300] : Colors.grey[600]),
                              fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _selectedTab == 0 ? _buildChatTab() : _buildAnalyticsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isDarkMode
              ? [
                  const Color(0xFF121212),
                  const Color(0xFF1E1E1E),
                ]
              : [
                  Colors.grey[50]!,
                  Colors.white,
                ],
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[_chatMessages.length - 1 - index];
                final isUser = msg['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(
                              colors: [_green, _greenLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUser ? null : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isUser ? 20 : 4),
                        topRight: Radius.circular(isUser ? 4 : 20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isUser ? _green : Colors.grey).withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : (_isDarkMode ? Colors.white : const Color(0xFF2C3E50)),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input area
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _green.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF2C3E50)),
                      decoration: InputDecoration(
                        hintText: 'Posez une question...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_green, _greenLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => _sendMessage(_messageController.text),
                    icon: const Icon(Icons.send, color: Colors.white),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final cardColor = _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF2C3E50);
    final secondaryTextColor = _isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('KPIs Généraux', textColor),
            const SizedBox(height: 16),
            _buildKPICard(
              'Chiffre d\'Affaires',
              '€128,450',
              '+15%',
              Icons.trending_up,
              const Color(0xFF27AE60),
              cardColor,
              textColor,
              secondaryTextColor!,
            ),
            _buildKPICard(
              'Nombre de Délégués',
              '24',
              '+3',
              Icons.people,
              const Color(0xFF2980B9),
              cardColor,
              textColor,
              secondaryTextColor!,
            ),
            _buildKPICard(
              'Commandes Totales',
              '542',
              '+8%',
              Icons.shopping_bag,
              const Color(0xFFE67E22),
              cardColor,
              textColor,
              secondaryTextColor!,
            ),
            _buildKPICard(
              'Taux de Satisfaction',
              '94%',
              '+2%',
              Icons.star,
              const Color(0xFF9B59B6),
              cardColor,
              textColor,
              secondaryTextColor!,
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Gestion', textColor),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildManagementCard(
                  'Délégués',
                  Icons.people,
                  const Color(0xFF27AE60),
                  cardColor,
                ),
                _buildManagementCard(
                  'Produits',
                  Icons.medication,
                  const Color(0xFF2980B9),
                  cardColor,
                ),
                _buildManagementCard(
                  'Rapports',
                  Icons.assessment,
                  const Color(0xFFE67E22),
                  cardColor,
                ),
                _buildManagementCard(
                  'Paramètres',
                  Icons.settings,
                  const Color(0xFF9B59B6),
                  cardColor,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('Top Délégués', textColor),
            const SizedBox(height: 16),
            _buildDelegateCard('Dr. Jean Dupont', '€15,230', '98%', cardColor, textColor, secondaryTextColor!),
            _buildDelegateCard('Dr. Marie Legrand', '€12,800', '96%', cardColor, textColor, secondaryTextColor!),
            _buildDelegateCard('Dr. Paul Moreau', '€11,500', '92%', cardColor, textColor, secondaryTextColor!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                change,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(String title, IconData icon, Color color, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(_isDarkMode ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDelegateCard(String name, String sales, String rating, Color cardColor, Color textColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(_isDarkMode ? 0.15 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_green, _greenLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      name.split(' ').map((e) => e[0]).take(2).join().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sales,
                      style: TextStyle(fontSize: 13, color: secondaryTextColor),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
