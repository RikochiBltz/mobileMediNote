import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../profile_screen.dart';
import '../chat_screen.dart';

class EnterpriseDashboard extends StatefulWidget {
  final User user;

  const EnterpriseDashboard({super.key, required this.user});

  @override
  State<EnterpriseDashboard> createState() => _EnterpriseDashboardState();
}

class _EnterpriseDashboardState extends State<EnterpriseDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF27AE60),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Rapports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return _buildReportsPage();
      case 2:
        return _buildCalendarPage();
      case 3:
        return ProfileScreen(user: widget.user);
      case 4:
        return ChatScreen(user: widget.user);
      default:
        return _buildDashboardPage();
    }
  }

  // ================= DASHBOARD =================
  Widget _buildDashboardPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF27AE60),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ===== HEADER CARD (same Delegate style) =====
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hello ${widget.user.name.split(' ')[0]} ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text('👋'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Admin panel ready — manage delegates & reports.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF27AE60).withOpacity(0.2),
                      border: Border.all(
                        color: const Color(0xFF27AE60),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.user.name
                            .split(' ')
                            .where((e) => e.isNotEmpty)
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== KPI CARDS =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildKPICard(
                    'Sales',
                    '₹45,230',
                    Icons.trending_up,
                    const Color(0xFF27AE60),
                  ),
                  _buildKPICard(
                    'Products',
                    '328',
                    Icons.inventory_2,
                    const Color(0xFF2980B9),
                  ),
                  _buildKPICard(
                    'Delegates',
                    '24',
                    Icons.people,
                    const Color(0xFFE67E22),
                  ),
                  _buildKPICard(
                    'Orders',
                    '156',
                    Icons.shopping_cart,
                    const Color(0xFF9B59B6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= REPORTS =================
  Widget _buildReportsPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rapports',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF27AE60),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: const Center(child: Text('Reports coming soon')),
    );
  }

  // ================= CALENDAR =================
  Widget _buildCalendarPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF27AE60),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: const Center(child: Text('Calendar coming soon')),
    );
  }

  // ================= KPI CARD =================
  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
