import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:fathom/features/auth/presentation/providers/auth_provider.dart';
import 'package:fathom/core/theme/app_theme.dart';
import 'package:fathom/shared/widgets/custom_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    if (authProvider.user != null && _nameController.text.isEmpty) {
      _nameController.text = authProvider.user!.displayName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profile Section
          if (authProvider.user != null) ...[
            const Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Save Display Name',
              onPressed: () async {
                final success = await authProvider.updateDisplayName(_nameController.text.trim());
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Display name updated successfully!')),
                  );
                }
              },
            ),
            const Divider(height: 32),
          ],

          // Theme Settings
          const Text('Theme Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: settingsProvider.settings.themeMode,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'system', child: Text('System Default')),
              DropdownMenuItem(value: 'light', child: Text('Light Mode')),
              DropdownMenuItem(value: 'dark', child: Text('Dark Mode')),
            ],
            onChanged: (val) {
              if (val != null && authProvider.user != null) {
                settingsProvider.updateThemeModeWithUser(authProvider.user!.uid, val);
              }
            },
          ),
          const Divider(height: 32),

          // Custom Accent Colors
          const Text('Accent Color', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: AppTheme.accentColors.length,
            itemBuilder: (context, index) {
              final color = AppTheme.accentColors[index];
              final isSelected = settingsProvider.accentColor.value == color.value;
              return GestureDetector(
                onTap: () {
                  if (authProvider.user != null) {
                    settingsProvider.updateAccentColorWithUser(authProvider.user!.uid, color);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    boxShadow: isSelected
                        ? [const BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)]
                        : null,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 32),

          // Change Password Section
          if (authProvider.user != null && !authProvider.user!.isAnonymous) ...[
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Update Password',
              onPressed: () async {
                final success = await authProvider.changePassword(
                  _currentPasswordController.text,
                  _newPasswordController.text,
                );
                if (success && context.mounted) {
                  _currentPasswordController.clear();
                  _newPasswordController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!')),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${authProvider.errorMessage ?? "Failed to update"}')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
