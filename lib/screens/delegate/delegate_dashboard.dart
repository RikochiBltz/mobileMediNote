import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/theme_provider.dart';
import '../../theme/app_design.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/shimmer_box.dart';
import '../profile_screen.dart';
import '../chat_screen.dart';

class DelegateDashboard extends StatefulWidget {
  final User user;

  const DelegateDashboard({super.key, required this.user});

  @override
  State<DelegateDashboard> createState() => _DelegateDashboardState();
}

class _DelegateDashboardState extends State<DelegateDashboard> {
  static const _green = AppDesign.green;
  static const _greenLight = AppDesign.greenLight;
  int _currentIndex = 0;
  bool _isDarkMode = false;
  bool _isDashboardLoading = true;
  bool _isCalendarLoading = false;

  @override
  void initState() {
    super.initState();
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
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _isDashboardLoading = false);
    }
  }

  Future<void> _refreshCalendar() async {
    setState(() => _isCalendarLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isCalendarLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final cardColor = AppDesign.surface(isDark);
    final navInactiveColor = AppDesign.navInactive(isDark);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppDesign.pageGradient(isDark),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _buildCurrentPage(),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(
              color: AppDesign.subtleBorder(isDark),
            ),
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
          backgroundColor: cardColor,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: _green,
          unselectedItemColor: navInactiveColor,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.dashboard, index: 0),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.calendar_today, index: 1),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.person, index: 2),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(icon: Icons.chat, index: 3),
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
        return _buildCalendarPage();
      case 2:
        return _buildProfilePage();
      case 3:
        return _buildChatPage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildDashboardPage() {
    final cardColor = AppDesign.surface(_isDarkMode);
    final textColor = AppDesign.textPrimary(_isDarkMode);
    final secondaryTextColor = AppDesign.textSecondary(_isDarkMode);
    
    return SafeArea(
      child: RefreshIndicator(
        color: _green,
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _isDashboardLoading
                ? _buildDashboardSkeleton(cardColor)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
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
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
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
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Icon(Icons.emoji_people, color: Colors.white, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Ready for your route today?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  widget.user.name.split(' ').map((e) => e[0]).join().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                        children: [
                          _buildStatCard(
                            'Monthly Sales',
                            'Rs 12,500',
                            Icons.trending_up,
                            const Color(0xFF27AE60),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          _buildStatCard(
                            'Visits',
                            '24',
                            Icons.location_on,
                            const Color(0xFF2980B9),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          _buildStatCard(
                            'Orders',
                            '18',
                            Icons.shopping_cart,
                            const Color(0xFFE67E22),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                          _buildStatCard(
                            'Clients',
                            '45',
                            Icons.people,
                            const Color(0xFF9B59B6),
                            cardColor: cardColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Recent Activities', textColor),
                      const SizedBox(height: 12),
                      ...[
                        {
                          'action': 'New Order',
                          'details': 'Dr. Jean ordered 50 boxes',
                          'time': '2 hours ago',
                          'icon': Icons.shopping_bag,
                          'color': const Color(0xFF27AE60),
                        },
                        {
                          'action': 'Visit Completed',
                          'details': 'Central Pharmacy',
                          'time': '5 hours ago',
                          'icon': Icons.check_circle,
                          'color': Colors.green,
                        },
                        {
                          'action': 'Launch Promotion',
                          'details': 'Vitamins -20%',
                          'time': 'Yesterday',
                          'icon': Icons.local_offer,
                          'color': const Color(0xFF2980B9),
                        },
                      ].map((activity) {
                        return _buildActivityCard(activity, cardColor, textColor, secondaryTextColor);
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardSkeleton(Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkeletonBox(height: 140, radius: 20, color: cardColor),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: List.generate(
            4,
            (_) => _buildSkeletonBox(height: 150, radius: 16, color: cardColor),
          ),
        ),
        const SizedBox(height: 20),
        _buildSkeletonBox(height: 20, width: 180, radius: 8, color: cardColor),
        const SizedBox(height: 12),
        _buildSkeletonBox(height: 78, radius: 16, color: cardColor),
        const SizedBox(height: 10),
        _buildSkeletonBox(height: 78, radius: 16, color: cardColor),
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
      baseColor: _isDarkMode ? color.withOpacity(0.75) : Colors.white.withOpacity(0.9),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, Color cardColor, Color textColor, Color secondaryTextColor) {
    return PressableScale(
      onTap: () {},
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppDesign.cardBorder(_isDarkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: (activity['color'] as Color).withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (activity['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                activity['icon'] as IconData,
                color: activity['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity['action'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activity['details'] as String,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              activity['time'] as String,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildCalendarPage() {
    final cardColor = AppDesign.surface(_isDarkMode);
    final titleColor = AppDesign.textPrimary(_isDarkMode);
    final secondaryTextColor = AppDesign.textSecondary(_isDarkMode);

    return SafeArea(
      child: RefreshIndicator(
        color: _green,
        onRefresh: _refreshCalendar,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: _isCalendarLoading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSkeletonBox(height: 90, radius: 20, color: cardColor, width: 90),
                        const SizedBox(height: 20),
                        _buildSkeletonBox(height: 24, width: 180, radius: 8, color: cardColor),
                        const SizedBox(height: 10),
                        _buildSkeletonBox(height: 16, width: 240, radius: 8, color: cardColor),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            size: 56,
                            color: _green,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _green,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Calendar feature is under development',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 12,
                            color: titleColor.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return ProfileScreen(user: widget.user);
  }

  Widget _buildChatPage() {
    return ChatScreen(user: widget.user);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    {
      required Color cardColor,
      required Color textColor,
      required Color secondaryTextColor,
    }
  ) {
    return PressableScale(
      onTap: () {},
      child: Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppDesign.cardBorder(_isDarkMode),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(color: secondaryTextColor, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ));
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
}
