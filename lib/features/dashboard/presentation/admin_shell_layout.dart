import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../fleet/data/partner_repository.dart';
import '../../../core/l10n/locale_provider.dart';

class AdminShellLayout extends ConsumerWidget {
  final Widget child;

  const AdminShellLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final partner = ref.watch(currentPartnerProvider);
    final lang = ref.watch(localeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    // Determine current selected index based on route location path
    int getSelectedIndex() {
      if (location == '/admin') return 0;
      if (location.startsWith('/admin/fleet')) return 1;
      if (location.startsWith('/admin/database')) return 2;
      if (location.startsWith('/admin/applications')) return 3;
      return 0;
    }

    final selectedIndex = getSelectedIndex();

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16162B),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Row(
            children: [
              Image.asset('assets/images/spacerent_logo.png', height: 28, errorBuilder: (c,e,s) => const SizedBox.shrink()),
              const SizedBox(width: 10),
              Text(
                tr('brand_name', ref),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: const Color(0xFF16162B),
          child: SafeArea(
            child: _buildSidebarContent(context, ref, selectedIndex, lang, partner, true),
          ),
        ),
        body: SafeArea(
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Row(
        children: [
          // Sidebar Design Layout
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: const Color(0xFF16162B),
              border: Border(
                right: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: _buildSidebarContent(context, ref, selectedIndex, lang, partner, false),
          ),

          // Main Screen view
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    String lang,
    dynamic partner,
    bool isDrawer,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Header with Logo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/spacerent_logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rocket_launch, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('brand_name', ref),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    Text(
                      partner != null
                          ? tr('partner_portal_label', ref)
                          : tr('admin_portal', ref),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF00CEC9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white12, height: 1),

        // Language Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            children: [
              _LanguageButton(
                label: 'EN',
                isActive: lang == 'en',
                onTap: () => ref.read(localeProvider.notifier).state = 'en',
              ),
              const SizedBox(width: 8),
              _LanguageButton(
                label: 'AL',
                isActive: lang == 'sq',
                onTap: () => ref.read(localeProvider.notifier).state = 'sq',
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Sidebar Navigation items
        _SidebarMenuItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard,
          title: tr('dashboard_home', ref),
          isActive: selectedIndex == 0,
          onTap: () {
            if (isDrawer) Navigator.of(context).pop();
            context.go('/admin');
          },
        ),
        const SizedBox(height: 8),
        _SidebarMenuItem(
          icon: Icons.directions_car_outlined,
          activeIcon: Icons.directions_car,
          title: tr('fleet_management_nav', ref),
          isActive: selectedIndex == 1,
          onTap: () {
            if (isDrawer) Navigator.of(context).pop();
            context.go('/admin/fleet');
          },
        ),
        if (partner == null) ...[
          const SizedBox(height: 8),
          _SidebarMenuItem(
            icon: Icons.storage_outlined,
            activeIcon: Icons.storage,
            title: 'Database Explorer',
            isActive: selectedIndex == 2,
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              context.go('/admin/database');
            },
          ),
          const SizedBox(height: 8),
          _SidebarMenuItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            title: tr('partner_onboarding', ref),
            isActive: selectedIndex == 3,
            onTap: () {
              if (isDrawer) Navigator.of(context).pop();
              context.go('/admin/applications');
            },
          ),
        ],

        const Spacer(),

        // Bottom User Profile Info card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                    child: Text(
                      partner != null ? 'P' : 'AD',
                      style: const TextStyle(color: Color(0xFF00CEC9), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partner != null ? partner.companyName : 'Admin',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          partner != null ? 'Partner User' : 'Pristina, Kosovo',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ref.read(isAdminProvider.notifier).state = false;
                    ref.read(currentPartnerProvider.notifier).state = null;
                    if (isDrawer) Navigator.of(context).pop();
                    context.go('/');
                  },
                  icon: const Icon(Icons.logout, size: 14),
                  label: Text(tr('logout', ref), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C5CE7) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF6C5CE7) : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6C5CE7).withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF6C5CE7).withOpacity(0.1) : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? const Color(0xFF00CEC9) : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white70,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
