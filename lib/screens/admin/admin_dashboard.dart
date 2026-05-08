import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_scoring_service.dart';
import '../../services/engagement_service.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_design.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/shimmer_box.dart';
import '../profile_screen.dart';
import '../chat_screen.dart';
import '../report_analysis_screen.dart';

class AdminDashboard extends StatefulWidget {
  final User admin;

  const AdminDashboard({super.key, required this.admin});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const _green = AppDesign.green;
  int _currentIndex = 0;
  bool _isDarkMode = false;
  bool _isDashboardLoading = true;
  bool _isUsersLoading = false;
  bool _isScoresLoading = true;
  String? _scoresError;
  final _scoringService = AdminScoringService();
  List<UserScoreCard> _scoreCards = [];

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
  void initState() {
    super.initState();
    EngagementService.instance.logFeature('dashboard');
    _loadScores();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _isDashboardLoading = false);
      }
    });
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

  Future<void> _refreshDashboard() async {
    setState(() => _isDashboardLoading = true);
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 900)),
      _loadScores(showLoader: false),
    ]);
    if (mounted) {
      setState(() => _isDashboardLoading = false);
    }
  }

  Future<void> _loadScores({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isScoresLoading = true;
        _scoresError = null;
      });
    }

    try {
      final scores = await _scoringService.fetchScores();
      if (!mounted) return;
      setState(() {
        _scoreCards = scores;
        _scoresError = null;
        _isScoresLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scoresError = e.toString().replaceFirst('Exception: ', '');
        _isScoresLoading = false;
      });
    }
  }

  Future<void> _refreshUsers() async {
    setState(() => _isUsersLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isUsersLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final cardColor = AppDesign.surface(isDark);
    final navInactiveColor = AppDesign.navInactive(isDark);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _buildCurrentPage(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(color: AppDesign.subtleBorder(isDark)),
          ),
          boxShadow: [
            BoxShadow(
              color: _green.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            EngagementService.instance.logFeature(_featureForIndex(index));
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: _green,
          unselectedItemColor: navInactiveColor,
          backgroundColor: cardColor,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.dashboard, index: 0),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.people, index: 1),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.fact_check, index: 2),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.person, index: 3),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.chat, index: 4),
              label: 'Chatbot',
            ),
          ],
        ),
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
        return ReportAnalysisScreen(user: widget.admin);
      case 3:
        return ProfileScreen(user: widget.admin);
      case 4:
        return ChatScreen(user: widget.admin);
      default:
        return _buildDashboardPage();
    }
  }

  String _featureForIndex(int index) {
    switch (index) {
      case 1:
        return 'users';
      case 2:
        return 'report_analysis';
      case 3:
        return 'profile';
      case 4:
        return 'chat';
      case 0:
      default:
        return 'dashboard';
    }
  }

  // =================== DASHBOARD ===================
  Widget _buildDashboardPage() {
    final scaffoldBackgroundColor = _isDarkMode
        ? AppDesign.darkBackground
        : Colors.white;
    final cardColor = AppDesign.surface(_isDarkMode);
    final textColor = AppDesign.textPrimary(_isDarkMode);
    final secondaryTextColor = AppDesign.textSecondary(_isDarkMode);

    final total = _users.length;
    final blocked = _users.where((u) => u.isBlocked).length;
    final delegates = _users
        .where((u) => u.userRole == UserRole.delegate)
        .length;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : _green,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 1,
      ),
      body: Container(
        color: scaffoldBackgroundColor,
        child: RefreshIndicator(
          color: _green,
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: _isDashboardLoading
                ? _buildDashboardSkeleton(cardColor)
                : Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppDesign.cardBorder(_isDarkMode),
                          ),
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
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.emoji_people,
                                        size: 18,
                                        color: AppDesign.green,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Manage users, roles and access.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: secondaryTextColor,
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
                                  style: TextStyle(
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
                          _kpi(
                            'Total Users',
                            '$total',
                            Icons.people,
                            _green,
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          _kpi(
                            'Delegates',
                            '$delegates',
                            Icons.badge,
                            const Color(0xFF2980B9),
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          _kpi(
                            'Blocked',
                            '$blocked',
                            Icons.block,
                            const Color(0xFFE67E22),
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                          _kpi(
                            'Roles',
                            '3',
                            Icons.admin_panel_settings,
                            const Color(0xFF9B59B6),
                            cardColor: cardColor,
                            textColor: textColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildScoresSection(
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoresSection({
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppDesign.cardBorder(_isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: _green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'User Scores',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh scores',
                onPressed: _isScoresLoading ? null : () => _loadScores(),
                icon: _isScoresLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, color: _green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_scoresError != null)
            Text(
              _scoresError!,
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (_isScoresLoading)
            Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _buildSkeletonBox(
                    height: 96,
                    radius: 12,
                    color: cardColor,
                  ),
                ),
              ),
            )
          else if (_scoreCards.isEmpty)
            Text(
              'Scores appear after users open features and ask chatbot questions.',
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
            )
          else
            Column(
              children: _scoreCards
                  .take(6)
                  .map(
                    (score) => _scoreCardTile(
                      score,
                      cardColor: cardColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _scoreCardTile(
    UserScoreCard score, {
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final scoreColor = score.overallScore >= 7
        ? _green
        : score.overallScore >= 4
            ? const Color(0xFFE67E22)
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode ? AppDesign.darkNavItem : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.cardBorder(_isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (score.overallScore.clamp(0, 10)) / 10,
                      strokeWidth: 6,
                      backgroundColor: scoreColor.withOpacity(0.12),
                      color: scoreColor,
                    ),
                    Text(
                      score.overallScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.fullName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      score.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip(score.role, _green.withOpacity(0.12), _green),
                        _chip(
                          '${score.totalChatQuestions} Q',
                          const Color(0xFF2980B9).withOpacity(0.12),
                          const Color(0xFF2980B9),
                        ),
                        _chip(
                          '${score.activeDays30} days',
                          const Color(0xFF9B59B6).withOpacity(0.12),
                          const Color(0xFF9B59B6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _scoreBar('Relevance', score.relevanceScore, scoreColor),
          _scoreBar('Frequency', score.frequencyScore, _green),
          _scoreBar('Coverage', score.coverageScore, const Color(0xFF2980B9)),
          if (score.rationale.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              score.rationale,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppDesign.textSecondary(_isDarkMode),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  color: AppDesign.textPrimary(_isDarkMode),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (value.clamp(0, 10)) / 10,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSkeleton(Color cardColor) {
    return Column(
      children: [
        _buildSkeletonBox(height: 110, radius: 14, color: cardColor),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: List.generate(
            4,
            (_) => _buildSkeletonBox(height: 140, radius: 12, color: cardColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonBox({
    required double height,
    required double radius,
    required Color color,
    double? width,
  }) {
    return ShimmerBox(
      width: width,
      height: height,
      radius: radius,
      baseColor: _isDarkMode
          ? color.withOpacity(0.75)
          : Colors.white.withOpacity(0.9),
    );
  }

  // =================== USERS ===================
  Widget _buildUsersPage() {
    final scaffoldBackgroundColor = _isDarkMode
        ? AppDesign.darkBackground
        : Colors.white;
    final cardColor = AppDesign.surface(_isDarkMode);
    final textColor = AppDesign.textPrimary(_isDarkMode);
    final secondaryTextColor = AppDesign.textSecondary(_isDarkMode);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : _green,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Add user',
            icon: Icon(
              Icons.person_add,
              color: _isDarkMode ? Colors.white : _green,
            ),
            onPressed: _openAddUserDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _green,
        onRefresh: _refreshUsers,
        child: _isUsersLoading
            ? ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) =>
                    _buildSkeletonBox(height: 88, radius: 12, color: cardColor),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final u = _users[i];
                  return PressableScale(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppDesign.cardBorder(_isDarkMode),
                        ),
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
                              style: TextStyle(
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  u.email,
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                  ),
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
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
  Widget _kpi(
    String title,
    String value,
    IconData icon,
    Color color, {
    required Color cardColor,
    required Color textColor,
  }) {
    return PressableScale(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.cardBorder(_isDarkMode)),
          boxShadow: [
            BoxShadow(
              color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(
                _isDarkMode ? 0.3 : 0.05,
              ),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: AppDesign.textSecondary(_isDarkMode),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon({required IconData icon, required int index}) {
    final isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected
            ? _green.withOpacity(0.12)
            : (_isDarkMode ? AppDesign.darkNavItem : Colors.grey[100]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 22,
        color: isSelected ? _green : AppDesign.navInactive(_isDarkMode),
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
