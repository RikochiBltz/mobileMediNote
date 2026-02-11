import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../profile_screen.dart';
import '../chat_screen.dart';

class AdminDashboard extends StatefulWidget {
  final User admin;

  const AdminDashboard({super.key, required this.admin});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _green = Color(0xFF27AE60);
  int _currentIndex = 0;

  // Fake DB (remplacer plus tard par API)
  final List<User> _users = [
    User(
      id: 'u1',
      name: 'Ahmed Ben Ali',
      email: 'ahmed@company.com',
      company: 'Pharma Company',
      region: 'Tunis',
      role: 'delegate',
      userRole: UserRole.delegate,
    ),
    User(
      id: 'u2',
      name: 'Sarra Trabelsi',
      email: 'sarra@company.com',
      company: 'Pharma Company',
      role: 'enterprise',
      userRole: UserRole.enterprise,
    ),
    User(
      id: 'u3',
      name: 'Youssef Khemiri',
      email: 'youssef@company.com',
      company: 'Pharma Company',
      role: 'delegate',
      userRole: UserRole.delegate,
      isBlocked: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
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
        return _buildUsersPage();
      case 2:
        return ProfileScreen(user: widget.admin);
      case 3:
        return ChatScreen(user: widget.admin);
      default:
        return _buildDashboardPage();
    }
  }

  // =================== DASHBOARD ===================
  Widget _buildDashboardPage() {
    final total = _users.length;
    final blocked = _users.where((u) => u.isBlocked).length;
    final delegates = _users
        .where((u) => u.userRole == UserRole.delegate)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: _green),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header (same style)
            Container(
              padding: const EdgeInsets.all(16),
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
                              'Hello ${widget.admin.name.split(' ')[0]} ',
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
                          'Manage users, roles and access.',
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
                      color: _green.withOpacity(0.2),
                      border: Border.all(color: _green, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.admin.name
                            .split(' ')
                            .where((e) => e.isNotEmpty)
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _kpi('Total Users', '$total', Icons.people, _green),
                _kpi(
                  'Delegates',
                  '$delegates',
                  Icons.badge,
                  const Color(0xFF2980B9),
                ),
                _kpi(
                  'Blocked',
                  '$blocked',
                  Icons.block,
                  const Color(0xFFE67E22),
                ),
                _kpi(
                  'Roles',
                  '3',
                  Icons.admin_panel_settings,
                  const Color(0xFF9B59B6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =================== USERS ===================
  Widget _buildUsersPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(fontWeight: FontWeight.bold, color: _green),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Add user',
            icon: const Icon(Icons.person_add, color: _green),
            onPressed: _openAddUserDialog,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final u = _users[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _green.withOpacity(0.12),
                  child: Text(
                    u.name
                        .split(' ')
                        .where((e) => e.isNotEmpty)
                        .map((e) => e[0])
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: _green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        u.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _chip(
                            u.role.toUpperCase(),
                            _green.withOpacity(0.12),
                            _green,
                          ),
                          if (u.isBlocked)
                            _chip(
                              'BLOCKED',
                              Colors.red.withOpacity(0.12),
                              Colors.red,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (value) => _handleUserAction(value, u),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'role',
                      child: Text('Change role'),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(u.isBlocked ? 'Unblock' : 'Block'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleUserAction(String action, User user) {
    if (action == 'block') {
      setState(() => user.isBlocked = !user.isBlocked);
      return;
    }
    if (action == 'delete') {
      setState(() => _users.removeWhere((u) => u.id == user.id));
      return;
    }
    if (action == 'role') {
      _openRoleDialog(user);
      return;
    }
  }

  // ✅ Change role without "assignment_to_final"
  void _openRoleDialog(User user) {
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change role'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            items: const [
              DropdownMenuItem(value: 'delegate', child: Text('Delegate')),
              DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
            ],
            onChanged: (v) => selectedRole = v ?? selectedRole,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _green),
              onPressed: () {
                final newEnum = _roleToEnum(selectedRole);

                setState(() {
                  final idx = _users.indexWhere((u) => u.id == user.id);
                  if (idx != -1) {
                    _users[idx] = User(
                      id: user.id,
                      email: user.email,
                      name: user.name,
                      company: user.company,
                      phone: user.phone,
                      region: user.region,
                      isBlocked: user.isBlocked,
                      role: selectedRole,
                      userRole: newEnum,
                    );
                  }
                });

                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _openAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'delegate';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add new user'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: role,
                items: const [
                  DropdownMenuItem(value: 'delegate', child: Text('Delegate')),
                  DropdownMenuItem(
                    value: 'enterprise',
                    child: Text('Enterprise'),
                  ),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => role = v ?? role,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _green),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty ||
                    emailCtrl.text.trim().isEmpty)
                  return;

                setState(() {
                  _users.add(
                    User(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      company: widget.admin.company,
                      role: role,
                      userRole: _roleToEnum(role),
                    ),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  UserRole _roleToEnum(String role) {
    switch (role) {
      case 'enterprise':
        return UserRole.enterprise;
      case 'admin':
        return UserRole.admin;
      case 'delegate':
      default:
        return UserRole.delegate;
    }
  }

  // =================== UI Helpers ===================
  Widget _kpi(String title, String value, IconData icon, Color color) {
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

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
