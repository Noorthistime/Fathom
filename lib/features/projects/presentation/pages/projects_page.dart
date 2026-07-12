import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/projects_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../chat/presentation/providers/chat_provider.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _nameController = TextEditingController();

  void _showCreateProjectDialog(BuildContext context, String userId) {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Project Folder'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  Provider.of<ProjectsProvider>(context, listen: false).createProject(
                    userId,
                    _nameController.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final projectsProvider = Provider.of<ProjectsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            onPressed: () {
              if (authProvider.user != null) {
                _showCreateProjectDialog(context, authProvider.user!.uid);
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: projectsProvider.projects.length,
        itemBuilder: (context, index) {
          final project = projectsProvider.projects[index];
          // Get chats belongs to this project
          final projectChats = chatProvider.chats.where((c) => c.projectId == project.id).toList();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ExpansionTile(
              leading: Icon(
                project.isPinned ? Icons.folder_special : Icons.folder,
                color: theme.primaryColor,
              ),
              title: Text(project.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(project.isPinned ? Icons.pin_drop : Icons.pin_drop_outlined, size: 20),
                    onPressed: () => projectsProvider.togglePinProject(project),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'rename') {
                        _nameController.text = project.name;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Rename Project'),
                            content: TextField(controller: _nameController),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () {
                                  projectsProvider.renameProject(project.id, _nameController.text.trim());
                                  Navigator.pop(context);
                                },
                                child: const Text('Rename'),
                              )
                            ],
                          ),
                        );
                      } else if (val == 'delete') {
                        // Deleting project moves chats back to unassigned
                        for (var c in projectChats) {
                          chatProvider.moveChatToProject(c.id, null);
                        }
                        projectsProvider.deleteProject(project.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'rename', child: Text('Rename')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              children: [
                if (projectChats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Drag or assign chats here to organize them!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  )
                else
                  ...projectChats.map((chat) => ListTile(
                        title: Text(chat.title, style: const TextStyle(fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.outbox, size: 18),
                          onPressed: () {
                            chatProvider.moveChatToProject(chat.id, null);
                          },
                        ),
                        onTap: () {
                          chatProvider.selectChat(chat.id);
                          Navigator.pop(context); // Go back to Home/Chat screen
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}
