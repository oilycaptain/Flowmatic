import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/section_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const SectionHeader(title: 'Account', caption: 'Your FlowMatic login details'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const AppLogo(size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName?.isNotEmpty == true ? user!.displayName! : 'FlowMatic User',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(user?.email ?? '—', style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SectionHeader(title: 'Settings', caption: 'Basic actions'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Log out of FlowMatic'),
                    onTap: () async {
                      await AuthService.signOut();
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('About FlowMatic', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Secure IoT smart irrigation monitoring'),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'FlowMatic',
                        applicationVersion: '1.0.0',
                        applicationIcon: const AppLogo(size: 40),
                        children: const [
                          SizedBox(height: 8),
                          Text('FlowMatic is a capstone prototype for secure, cloud-connected irrigation monitoring.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
