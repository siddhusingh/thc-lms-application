import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/thc_logo.dart';
import '../features/auth/presentation/auth_provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  int _indexForLocation(String location) {
    if (location.startsWith('/courses')) return 1;
    if (location.startsWith('/assessments')) return 2;
    if (location.startsWith('/certificates')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    return PopScope(
      canPop: location == '/dashboard' || Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && location != '/dashboard') {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const ThcLogo(size: 42),
          leadingWidth: 72,
          leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                tooltip: 'Open navigation menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        drawer: _AppDrawer(currentLocation: location),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indexForLocation(location),
          onDestinationSelected: (index) {
            final target = switch (index) {
              0 => '/dashboard',
              1 => '/courses',
              2 => '/assessments',
              3 => '/certificates',
              4 => '/profile',
              _ => '/dashboard',
            };
            if (location == target) return;
            context.push(target);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Courses',
            ),
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded),
              label: 'Tests',
            ),
            NavigationDestination(
              icon: Icon(Icons.workspace_premium_outlined),
              selectedIcon: Icon(Icons.workspace_premium_rounded),
              label: 'Certs',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.currentLocation});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = context.watch<AuthProvider>();

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.14,
                    ),
                    backgroundImage:
                        authProvider.user?.avatarUrl?.isNotEmpty == true
                        ? NetworkImage(authProvider.user!.avatarUrl!)
                        : null,
                    child: authProvider.user?.avatarUrl?.isNotEmpty == true
                        ? null
                        : Text(
                            (authProvider.user?.name.isNotEmpty == true
                                    ? authProvider.user!.name[0]
                                    : 'S')
                                .toUpperCase(),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                  ),
                  if (authProvider.user?.name.isNotEmpty == true) ...[
                    const SizedBox(height: 14),
                    Text(
                      authProvider.user!.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (authProvider.user?.email.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      authProvider.user!.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    label: 'Home',
                    route: '/dashboard',
                    currentLocation: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_outlined,
                    selectedIcon: Icons.menu_book_rounded,
                    label: 'Courses',
                    route: '/courses',
                    currentLocation: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.quiz_outlined,
                    selectedIcon: Icons.quiz_rounded,
                    label: 'Tests',
                    route: '/assessments',
                    currentLocation: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.workspace_premium_outlined,
                    selectedIcon: Icons.workspace_premium_rounded,
                    label: 'Certificates',
                    route: '/certificates',
                    currentLocation: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Profile',
                    route: '/profile',
                    currentLocation: currentLocation,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: colorScheme.error),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    required this.currentLocation,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected =
        currentLocation == route ||
        (route != '/dashboard' && currentLocation.startsWith(route));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        leading: Icon(selected ? selectedIcon : icon),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        selected: selected,
        selectedColor: colorScheme.primary,
        selectedTileColor: colorScheme.primary.withValues(alpha: 0.10),
        iconColor: colorScheme.onSurface.withValues(alpha: 0.72),
        textColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.of(context).pop();
          if (!selected) context.push(route);
        },
      ),
    );
  }
}
