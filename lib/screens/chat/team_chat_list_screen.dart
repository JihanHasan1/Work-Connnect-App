import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/team_model.dart';
import 'team_chat_screen.dart';

class TeamChatListScreen extends StatelessWidget {
  const TeamChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search teams...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TeamModel>>(
              stream: chatProvider.getTeams(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading teams',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No teams available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auth.isAdmin
                              ? 'Create your first team to get started'
                              : 'No teams assigned to you yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (auth.isAdmin) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateTeamDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Team'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final teams = snapshot.data!;

                // Filter teams based on user role
                final userTeams = auth.isAdmin
                    ? teams
                    : teams.where((team) {
                        return team.memberIds.contains(auth.currentUser?.uid) ||
                            team.leaderId == auth.currentUser?.uid;
                      }).toList();

                if (userTeams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No teams assigned',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contact your administrator to join a team',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: userTeams.length,
                  itemBuilder: (context, index) {
                    final team = userTeams[index];
                    return _TeamCard(team: team);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateTeamDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  static void _showCreateTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Team'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter team name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              descController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final auth = context.read<AuthProvider>();
                  final chatProvider = context.read<ChatProvider>();

                  final team = TeamModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    description: descController.text.trim(),
                    leaderId: auth.currentUser!.uid,
                    memberIds: [],
                    createdAt: DateTime.now(),
                  );

                  await chatProvider.createTeam(team);

                  nameController.dispose();
                  descController.dispose();

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Team created successfully'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    ).then((_) {
      // Dispose controllers if dialog is dismissed
      nameController.dispose();
      descController.dispose();
    });
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeamChatScreen(team: team),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${team.memberIds.length} member${team.memberIds.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
