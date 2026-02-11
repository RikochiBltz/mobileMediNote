import 'package:flutter/material.dart';
import '../../models/user_model.dart';

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
      'text':
          'Bonjour Admin! 👋 Bienvenue sur PharmaCare. Je suis votre assistant IA.',
    },
  ];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Centre de Gestion',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF27AE60),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Buttons
          Container(
            color: const Color(0xFF27AE60),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assistant,
                            color: _selectedTab == 0
                                ? const Color(0xFF27AE60)
                                : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Assistant IA',
                            style: TextStyle(
                              color: _selectedTab == 0
                                  ? const Color(0xFF27AE60)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.dashboard,
                            color: _selectedTab == 1
                                ? const Color(0xFF27AE60)
                                : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Analytics',
                            style: TextStyle(
                              color: _selectedTab == 1
                                  ? const Color(0xFF27AE60)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
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
    return Column(
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
                alignment: isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF27AE60) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Posez une question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: const Color(0xFF27AE60),
                onPressed: () => _sendMessage(_messageController.text),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KPIs Généraux',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildKPICard(
            'Chiffre d\'Affaires',
            '€128,450',
            '+15%',
            Icons.trending_up,
            const Color(0xFF27AE60),
          ),
          _buildKPICard(
            'Nombre de Délégués',
            '24',
            '+3',
            Icons.people,
            const Color(0xFF2980B9),
          ),
          _buildKPICard(
            'Commandes Totales',
            '542',
            '+8%',
            Icons.shopping_bag,
            const Color(0xFFE67E22),
          ),
          _buildKPICard(
            'Taux de Satisfaction',
            '94%',
            '+2%',
            Icons.star,
            const Color(0xFF9B59B6),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gestion',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildManagementCard(
                'Délégués',
                Icons.people,
                const Color(0xFF27AE60),
              ),
              _buildManagementCard(
                'Produits',
                Icons.medication,
                const Color(0xFF2980B9),
              ),
              _buildManagementCard(
                'Rapports',
                Icons.assessment,
                const Color(0xFFE67E22),
              ),
              _buildManagementCard(
                'Paramètres',
                Icons.settings,
                const Color(0xFF9B59B6),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Top Délégués',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDelegateCard('Dr. Jean Dupont', '€15,230', '98%'),
          _buildDelegateCard('Dr. Marie Legrand', '€12,800', '96%'),
          _buildDelegateCard('Dr. Paul Moreau', '€11,500', '92%'),
        ],
      ),
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDelegateCard(String name, String sales, String rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                sales,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '⭐ $rating',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
