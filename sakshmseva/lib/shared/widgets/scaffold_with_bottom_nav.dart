import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/app_router.dart';
import '../../theme/app_colors.dart';

/// Shell scaffold that wraps all main screens with a persistent bottom nav bar.
class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _NavTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', route: AppRoutes.home),
    _NavTab(icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Schemes', route: AppRoutes.schemes),
    _NavTab(icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy, label: 'Ask Sakshm', route: AppRoutes.chatbot),
    _NavTab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', route: AppRoutes.profile),
  ];

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.schemes)) return 1;
    if (location.startsWith(AppRoutes.chatbot)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => context.go(_tabs[index].route),
          items: _tabs
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  activeIcon: Icon(tab.activeIcon, color: AppColors.primaryGreen),
                  label: tab.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}
