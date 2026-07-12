import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'package:fathom/features/auth/presentation/providers/auth_provider.dart';
import 'package:fathom/features/auth/presentation/widgets/guest_upgrade_dialog.dart';
import 'package:fathom/features/projects/presentation/providers/projects_provider.dart';
import 'package:fathom/features/projects/presentation/pages/projects_page.dart';
import 'package:fathom/features/settings/presentation/pages/settings_page.dart';
import 'package:fathom/features/settings/presentation/providers/settings_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_search.dart';
import 'package:fathom/core/constants/constants.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _renameController = TextEditingController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _checkLimitsAndSend(
    BuildContext context,
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = authProvider.user;
    if (user == null) return;

    // Check if new chat
    final isNewChat = chatProvider.selectedChatId == null;

    if (isNewChat) {
      if (user.isAnonymous) {
        // Guest limit: max 5 chats
        final currentChatsCount = chatProvider.chats.length;
        if (currentChatsCount >= AppConstants.guestChatLimit) {
          _showUpgradePromptDialog(context);
          return;
        }
      } else {
        // Registered user limit: max 50 new chats per day
        final lastReset = user.lastChatReset;
        final now = DateTime.now();
        if (now.difference(lastReset).inDays >= 1) {
          await authProvider.resetDailyChatCount();
        }

        if (user.dailyChatCount >= AppConstants.registeredDailyChatLimit) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily limit of 50 new chats reached! Come back tomorrow.')),
          );
          return;
        }
        await authProvider.incrementChatCount();
      }
    }

    // Default testing key fallback if compile time define is not configured
    const defaultApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyFakeKey_UseSettingsToReplace');
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    _messageController.clear();

    if (isNewChat) {
      await chatProvider.createNewChat(user.uid, text, defaultApiKey);
    } else {
      await chatProvider.sendMessage(text, defaultApiKey);
    }
    _scrollToBottom();
  }

  void _showUpgradePromptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guest Limit Reached'),
        content: const Text(
          'Guests are limited to a maximum of 5 chats. Register or log in to keep your chats permanently and enjoy unlimited daily conversations!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => const GuestUpgradeDialog(),
              );
            },
            child: const Text('Sign Up / Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final projectsProvider = Provider.of<ProjectsProvider>(context);
    final theme = Theme.of(context);

    final selectedChat = chatProvider.selectedChat;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedChat?.title ?? 'Fathom AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: ChatSearchDelegate());
            },
          ),
          if (selectedChat != null)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'rename') {
                  _renameController.text = selectedChat.title;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Rename Chat'),
                      content: TextField(controller: _renameController),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () {
                            chatProvider.renameChat(selectedChat.id, _renameController.text.trim());
                            Navigator.pop(context);
                          },
                          child: const Text('Rename'),
                        )
                      ],
                    ),
                  );
                } else if (val == 'delete') {
                  chatProvider.deleteChat(selectedChat.id);
                } else if (val == 'pin') {
                  chatProvider.togglePinChat(selectedChat);
                } else if (val == 'project') {
                  _showMoveToProjectDialog(context, chatProvider, projectsProvider, selectedChat.id);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'rename', child: const Text('Rename')),
                PopupMenuItem(value: 'pin', child: Text(selectedChat.isPinned ? 'Unpin' : 'Pin')),
                PopupMenuItem(value: 'project', child: const Text('Move to Project')),
                PopupMenuItem(value: 'delete', child: const Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
      drawer: _buildDrawer(context, authProvider, chatProvider, projectsProvider),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chatProvider.selectedChatId == null
                  ? _buildWelcomeScreen(theme)
                  : _buildMessageList(chatProvider, theme),
            ),
            if (chatProvider.isGenerating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Gemini is generating response...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            _buildInputBox(context, authProvider, chatProvider, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: theme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'How can I help you today?',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Start a conversation with Google Gemini AI', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatProvider chatProvider, ThemeData theme) {
    if (chatProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatProvider.messages.isEmpty) {
      return const Center(child: Text('Start conversation by typing a message below!'));
    }

    _scrollToBottom();

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: chatProvider.messages.length,
        itemBuilder: (context, index) {
          final message = chatProvider.messages[index];
          return ChatBubble(message: message);
        },
      ),
    );
  }

  Widget _buildInputBox(
    BuildContext context,
    AuthProvider authProvider,
    ChatProvider chatProvider,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Ask Fathom AI...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _checkLimitsAndSend(context, authProvider, chatProvider),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: theme.primaryColor),
            onPressed: () => _checkLimitsAndSend(context, authProvider, chatProvider),
          ),
        ],
      ),
    );
  }

  void _showMoveToProjectDialog(
    BuildContext context,
    ChatProvider chatProvider,
    ProjectsProvider projectsProvider,
    String chatId,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Move to Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('None (Remove from projects)'),
                  onTap: () {
                    chatProvider.moveChatToProject(chatId, null);
                    Navigator.pop(context);
                  },
                ),
                ...projectsProvider.projects.map((project) => ListTile(
                      title: Text(project.name),
                      onTap: () {
                        chatProvider.moveChatToProject(chatId, project.id);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    AuthProvider authProvider,
    ChatProvider chatProvider,
    ProjectsProvider projectsProvider,
  ) {
    final theme = Theme.of(context);
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          // Profile Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
            accountName: Text(user?.displayName ?? 'Guest User', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? 'Anonymous Guest Mode'),
          ),

          // Action links
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('New Chat'),
            onTap: () {
              chatProvider.selectChat(null);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Projects Folder'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings & Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          if (user?.isAnonymous ?? false)
            ListTile(
              leading: const Icon(Icons.upgrade),
              title: const Text('Upgrade Account'),
              tileColor: Colors.amber.withOpacity(0.2),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => const GuestUpgradeDialog(),
                );
              },
            ),

          const Divider(),

          // Chat History List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                final isSelected = chatProvider.selectedChatId == chat.id;
                return ListTile(
                  leading: Icon(chat.isPinned ? Icons.pin_drop : Icons.chat_bubble_outline),
                  title: Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: isSelected,
                  onTap: () {
                    chatProvider.selectChat(chat.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {
              authProvider.logout();
            },
          ),
        ],
      ),
    );
  }
}
