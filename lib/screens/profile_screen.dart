import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'invite_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('PROFIL')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user == null)
            _loggedOut(context)
          else ...[
            _avatarCard(user),
            const SizedBox(height: 24),
            _tile(
              context,
              icon: Icons.link,
              label: 'Rejoindre une invitation',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InviteScreen()),
              ),
            ),
            if (auth.canScan)
              _infoBanner(
                icon: Icons.qr_code_scanner,
                title: 'Compte scanner activé',
                subtitle:
                    'Tu peux valider les billets à l\'entrée via l\'onglet Scanner.',
              ),
            const SizedBox(height: 8),
            _tile(
              context,
              icon: Icons.logout,
              label: 'Se déconnecter',
              danger: true,
              onTap: () => _confirmLogout(context, auth),
            ),
          ],
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(Config.siteName.toUpperCase(),
                    style: AppTheme.heading(size: 20, color: AppColors.muted)),
                Text(Config.siteSlogan,
                    style: AppTheme.mono(size: 11, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarCard(user) {
    final color = user.isGirl ? AppColors.pink : AppColors.accent;
    final initials = ((user.firstName.isNotEmpty ? user.firstName[0] : '') +
            (user.lastName.isNotEmpty ? user.lastName[0] : ''))
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color),
              shape: BoxShape.circle,
            ),
            child: Text(initials,
                style: AppTheme.heading(size: 24, color: color)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName.toUpperCase(),
                    style: AppTheme.heading(size: 22)),
                const SizedBox(height: 2),
                Text(user.email,
                    style: const TextStyle(color: AppColors.sub, fontSize: 13)),
                if (user.social.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(user.social,
                      style: TextStyle(color: color, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool danger = false}) {
    final color = danger ? AppColors.danger : AppColors.text;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: ListTile(
        leading: Icon(icon, color: danger ? AppColors.danger : AppColors.accent),
        title: Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.sub),
        onTap: onTap,
      ),
    );
  }

  Widget _infoBanner(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.raised,
        border: Border.all(color: AppColors.accent2.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.heading(size: 15, color: AppColors.accent)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.sub, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loggedOut(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.person_outline, size: 48, color: AppColors.muted),
        const SizedBox(height: 16),
        Text('PAS CONNECTÉ', style: AppTheme.heading(size: 24)),
        const SizedBox(height: 8),
        const Text('Connecte-toi pour accéder à ton espace.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.sub)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Se connecter →'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Se déconnecter ?', style: AppTheme.heading(size: 22)),
        content: const Text('Tu devras te reconnecter pour réserver.',
            style: TextStyle(color: AppColors.sub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.sub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await auth.logout();
      if (context.mounted) showSnack(context, 'À bientôt dans le bon.');
    }
  }
}
