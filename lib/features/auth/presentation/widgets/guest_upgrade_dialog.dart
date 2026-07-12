import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../chat/presentation/providers/chat_provider.dart';

class GuestUpgradeDialog extends StatefulWidget {
  const GuestUpgradeDialog({super.key});

  @override
  State<GuestUpgradeDialog> createState() => _GuestUpgradeDialogState();
}

class _GuestUpgradeDialogState extends State<GuestUpgradeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return AlertDialog(
      title: const Text('Upgrade Guest Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Register your account to save your chats and access more features. Your guest chats will be migrated automatically!',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                labelText: 'Display Name',
                hintText: 'Enter your display name',
                validator: (val) => val == null || val.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email Address',
                hintText: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter your password',
                isPassword: true,
                validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
              ),
              if (authProvider.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  authProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: authProvider.isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    final guestUid = authProvider.user?.uid;
                    final success = await authProvider.upgradeGuest(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                      _nameController.text.trim(),
                    );
                    if (success && guestUid != null && authProvider.user != null) {
                      await chatProvider.migrateGuestChats(guestUid, authProvider.user!.uid);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account upgraded and chats migrated successfully!')),
                        );
                      }
                    }
                  }
                },
          child: const Text('Upgrade'),
        ),
      ],
    );
  }
}
