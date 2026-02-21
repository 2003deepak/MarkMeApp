import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:markmeapp/core/theme/app_theme.dart';
import 'package:markmeapp/state/auth_state.dart';
import 'package:markmeapp/state/clerk_state.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}


class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clerkStoreProvider.notifier).loadProfile();
    });
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await ref.read(authStoreProvider.notifier).setLogOut();
    }
  }

  void _onUpdatePassword() {
    context.push('/change-password');
  }

  void _openEditProfile() {
    context.push('/clerk/edit-profile');
  }

  SizedBox gap(double v) => SizedBox(height: v);

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(13), // 0.05
        blurRadius: 20,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              letterSpacing: 0.2,
            ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    final tileColor = isLogout ? const Color(0xFFFEF2F2) : Colors.white;
    final iconColor = isLogout
        ? const Color(0xFFDC2626)
        : const Color(0xFF4B5563);
    final labelColor = isLogout
        ? const Color(0xFFDC2626)
        : const Color(0xFF111827);
    final subtitleColor = isLogout
        ? const Color(0xFFDC2626)
        : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLogout
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: labelColor,
                              height: 1.4,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w400,
                                color: subtitleColor,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isLogout
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hPad = w < 380 ? 16.0 : 20.0;
    
    final clerkState = ref.watch(clerkStoreProvider);
    final profile = clerkState.profile;
    final isLoading = clerkState.isLoading;

    if (isLoading && profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final firstName = profile?.firstName ?? 'Clerk';
    final lastName = profile?.lastName ?? '';
    final email = profile?.email ?? 'clerk@markme.com';
    final program = profile?.program ?? 'N/A';
    final dept = profile?.department ?? 'N/A';
    final profilePic = profile?.profilePicture;

    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF8FAFC,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with profile info
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        image: profilePic != null && profilePic.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(profilePic),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profilePic != null && profilePic.isNotEmpty
                          ? null
                          : const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$firstName $lastName',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                  height: 1.3,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.school,
                                      size: 14,
                                      color: Color(0xFF4F46E5),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      program,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF4F46E5),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F9FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  dept,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF0369A1),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        onPressed: _openEditProfile,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: const Color(0xFF475569),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              gap(24),

              _sectionHeader('ATTENDANCE'),
              Container(
                decoration: _cardDecoration,
                child: Column(
                  children: [
                    _infoTile(
                      icon: Icons.bar_chart_rounded,
                      label: 'Attendance Summary',
                      subtitle: 'View your attendance statistics',
                      onTap: () => context.push('/clerk/attendance-history'),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFF1F5F9),
                    ),
                    _infoTile(
                      icon: Icons.warning_amber_rounded,
                      label: 'Defaulters List',
                      subtitle: 'View students with low attendance',
                      onTap: () => context.push('/clerk/defaulters'),
                    ),
                  ],
                ),
              ),

              gap(24),

              _sectionHeader('ACCOUNT'),
              Container(
                decoration: _cardDecoration,
                child: Column(
                  children: [
                    

                    _infoTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Update Password',
                      subtitle: 'Change your account password',
                      onTap: _onUpdatePassword,
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFF1F5F9),
                    ),
                    _infoTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      subtitle: 'Get assistance',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Open Help & Support')),
                        );
                      },
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFF1F5F9),
                    ),
                    _infoTile(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      subtitle: 'Sign out of your account',
                      isLogout: true,
                      onTap: _handleLogout,
                    ),
                  ],
                ),
              ),

              gap(20),

              // Additional info card similar to dashboard
              Container(
                decoration: _cardDecoration,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Member Since',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile?.createdAt != null 
                                    ? '${profile!.createdAt!.year}' 
                                    : '2025',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF111827),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Status',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF6B7280),
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Active',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF166534),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
