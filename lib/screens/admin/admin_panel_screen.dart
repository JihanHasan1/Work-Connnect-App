import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../chatbot/issues_management_screen.dart';
import 'chatbot_training_screen.dart';
import '../../models/issue_model.dart';
import 'package:intl/intl.dart';
import 'chatbot_training_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Changed from 4 to 5
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Users'),
                Tab(text: 'Teams'),
                Tab(text: 'Train Bot'), // New tab
                Tab(text: 'ChatBot'),
                Tab(text: 'Issues'),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _UsersTab(),
            _TeamsTab(),
            _TrainBotTab(), // New tab content
            _ChatbotTab(),
            _IssuesTab(),
          ],
        ),
      ),
    );
  }
}

// New Training Tab
class _TrainBotTab extends StatelessWidget {
  const _TrainBotTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ChatBot Training',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Teach the bot to answer employee questions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF059669).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Train your chatbot by adding question-answer pairs. The bot learns to understand and respond to employee queries automatically.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF059669).withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    size: 60,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ready to Train Your Bot?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click the button below to start training',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChatbotTrainingScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school),
                  label: const Text('Open Training Interface'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF10B981)),
                            SizedBox(width: 12),
                            Text('Quick Tips'),
                          ],
                        ),
                        content: const SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '✨ Best Practices:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text('• Use clear, natural questions'),
                              Text('• Provide complete, helpful answers'),
                              Text('• Test your bot regularly'),
                              Text('• Update knowledge as needed'),
                              Text('• Monitor pending issues for gaps'),
                              SizedBox(height: 16),
                              Text(
                                '🎯 The bot uses smart matching to understand similar questions automatically!',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it!'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('View Training Guide'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Enhanced Users Tab with Search and Sort
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _sortAndFilterUsers(
      List<QueryDocumentSnapshot> docs) {
    var users = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {'id': doc.id, ...data};
    }).toList();

    if (_searchQuery.isNotEmpty) {
      users = users.where((user) {
        final displayName =
            (user['displayName'] ?? '').toString().toLowerCase();
        final username = (user['username'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return displayName.contains(query) || username.contains(query);
      }).toList();
    }

    users.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          final aName = a['displayName'] ?? a['username'] ?? '';
          final bName = b['displayName'] ?? b['username'] ?? '';
          return aName.toString().compareTo(bName.toString());
        case 'username':
          return (a['username'] ?? '')
              .toString()
              .compareTo((b['username'] ?? '').toString());
        case 'role':
          return (a['role'] ?? '')
              .toString()
              .compareTo((b['role'] ?? '').toString());
        case 'created':
          final aDate = a['createdAt'] ?? '';
          final bDate = b['createdAt'] ?? '';
          return bDate.toString().compareTo(aDate.toString());
        default:
          return 0;
      }
    });

    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Manage Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name or username...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Sort by:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                        label: 'Name',
                        isSelected: _sortBy == 'name',
                        onTap: () => setState(() => _sortBy = 'name'),
                      ),
                      _SortChip(
                        label: 'Username',
                        isSelected: _sortBy == 'username',
                        onTap: () => setState(() => _sortBy = 'username'),
                      ),
                      _SortChip(
                        label: 'Role',
                        isSelected: _sortBy == 'role',
                        onTap: () => setState(() => _sortBy = 'role'),
                      ),
                      _SortChip(
                        label: 'Date',
                        isSelected: _sortBy == 'created',
                        onTap: () => setState(() => _sortBy = 'created'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No users yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddUserDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First User'),
                      ),
                    ],
                  ),
                );
              }

              final users = _sortAndFilterUsers(snapshot.data!.docs);

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No users found',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _UserCard(userId: user['id'], userData: user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static void _showAddUserDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final displayNameController = TextEditingController();
    String selectedRole = 'team_member';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username (case-sensitive)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password (case-sensitive)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'team_member', child: Text('Team Member')),
                    DropdownMenuItem(
                        value: 'team_leader', child: Text('Team Leader')),
                  ],
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('users').add({
                    'username': usernameController.text,
                    'password': passwordController.text,
                    'displayName': displayNameController.text,
                    'role': selectedRole,
                    'createdAt': DateTime.now().toIso8601String(),
                    'isActive': true,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B)),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF1E293B),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const _UserCard({required this.userId, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E293B),
          child: Text(
            (userData['displayName']?[0] ?? userData['username']?[0] ?? 'U')
                .toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          userData['displayName'] ?? userData['username'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '@${userData['username'] ?? 'unknown'}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: userData['role'] == 'team_leader'
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                userData['role']
                        ?.toString()
                        .replaceAll('_', ' ')
                        .toUpperCase() ??
                    'UNKNOWN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: userData['role'] == 'team_leader'
                      ? Colors.blue
                      : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, userId),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showDeleteConfirmation(
      BuildContext context, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
      }
    }
  }
}

// Enhanced Teams Tab with Search and Sort
class _TeamsTab extends StatefulWidget {
  const _TeamsTab();

  @override
  State<_TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<_TeamsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _sortAndFilterTeams(
      List<QueryDocumentSnapshot> docs) {
    var teams = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {'id': doc.id, ...data};
    }).toList();

    if (_searchQuery.isNotEmpty) {
      teams = teams.where((team) {
        final name = (team['name'] ?? '').toString().toLowerCase();
        final desc = (team['description'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    }

    teams.sort((a, b) {
      switch (_sortBy) {
        case 'name':
          return (a['name'] ?? '')
              .toString()
              .compareTo((b['name'] ?? '').toString());
        case 'members':
          final aCount = (a['memberIds'] as List?)?.length ?? 0;
          final bCount = (b['memberIds'] as List?)?.length ?? 0;
          return bCount.compareTo(aCount);
        case 'created':
          final aDate = a['createdAt'] ?? '';
          final bDate = b['createdAt'] ?? '';
          return bDate.toString().compareTo(aDate.toString());
        default:
          return 0;
      }
    });

    return teams;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text('Manage Teams',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTeamDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Team'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search teams...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('teams').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No teams created yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddTeamDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Team'),
                      ),
                    ],
                  ),
                );
              }

              final teams = _sortAndFilterTeams(snapshot.data!.docs);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return _TeamCard(teamId: team['id'], teamData: team);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static void _showAddTeamDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final auth = context.read<AuthProvider>();
                await FirebaseFirestore.instance.collection('teams').add({
                  'name': nameController.text,
                  'description': descController.text,
                  'leaderId': auth.currentUser?.uid ?? '',
                  'memberIds': [],
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Team created successfully'),
                        backgroundColor: Colors.green),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B)),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String teamId;
  final Map<String, dynamic> teamData;

  const _TeamCard({required this.teamId, required this.teamData});

  @override
  Widget build(BuildContext context) {
    final memberCount = (teamData['memberIds'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(teamData['name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(teamData['description'] ?? ''),
            const SizedBox(height: 4),
            Text('$memberCount members',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(context, teamId),
        ),
      ),
    );
  }

  static Future<void> _showDeleteConfirmation(
      BuildContext context, String teamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: const Text('Are you sure you want to delete this team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseFirestore.instance.collection('teams').doc(teamId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team deleted')),
        );
      }
    }
  }
}

// ChatBot Tab
class _ChatbotTab extends StatelessWidget {
  const _ChatbotTab();

  @override
  Widget build(BuildContext context) {
    final botProvider = context.watch<ChatbotProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'ChatBot Knowledge',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddResponseDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Knowledge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: botProvider.botKnowledge.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined,
                          size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No knowledge trained yet',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddResponseDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Knowledge'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: botProvider.botKnowledge.length,
                  itemBuilder: (context, index) {
                    final entry =
                        botProvider.botKnowledge.entries.elementAt(index);
                    final questionId = entry.key;
                    final data = entry.value;
                    return _BotResponseCard(
                      questionId: questionId,
                      question: data['question'] ?? '',
                      answer: data['answer'] ?? '',
                      keywords: List<String>.from(data['keywords'] ?? []),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static void _showAddResponseDialog(BuildContext context) {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final keywordsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Bot Knowledge'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question',
                    border: OutlineInputBorder(),
                    hintText: 'What users might ask',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final provider = context.read<ChatbotProvider>();
                      final keywords = provider.extractKeywords(value);
                      keywordsController.text = keywords.join(', ');
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: answerController,
                  decoration: const InputDecoration(
                    labelText: 'Bot Response',
                    border: OutlineInputBorder(),
                    hintText: 'What the bot should answer',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an answer';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: keywordsController,
                  decoration: InputDecoration(
                    labelText: 'Keywords (comma separated)',
                    border: const OutlineInputBorder(),
                    hintText: 'leave, policy, vacation',
                    helperText: 'Important words for matching',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome),
                      onPressed: () {
                        if (questionController.text.isNotEmpty) {
                          final provider = context.read<ChatbotProvider>();
                          final keywords =
                              provider.extractKeywords(questionController.text);
                          keywordsController.text = keywords.join(', ');
                        }
                      },
                    ),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter at least one keyword';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final keywords = keywordsController.text
                      .split(',')
                      .map((k) => k.trim())
                      .where((k) => k.isNotEmpty)
                      .toList();

                  await context.read<ChatbotProvider>().addBotResponse(
                        questionController.text.trim(),
                        answerController.text.trim(),
                        keywords,
                      );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Knowledge added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _BotResponseCard extends StatelessWidget {
  final String questionId;
  final String question;
  final String answer;
  final List<String> keywords;

  const _BotResponseCard({
    required this.questionId,
    required this.question,
    required this.answer,
    required this.keywords,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.question_answer, color: Color(0xFF10B981)),
        ),
        title:
            Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: keywords.take(3).map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.label, size: 10, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      keyword,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bot Response:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Text(answer,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                const SizedBox(height: 12),
                const Text('Keywords:',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: keywords.map((keyword) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.label,
                              size: 12, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          Text(
                            keyword,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Knowledge'),
                            content: const Text(
                                'Are you sure you want to delete this knowledge entry?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          await context
                              .read<ChatbotProvider>()
                              .removeBotResponse(questionId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Knowledge deleted')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Remove'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IssuesTab extends StatelessWidget {
  const _IssuesTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Chatbot Issues',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Consumer<ChatbotProvider>(
                builder: (context, provider, child) {
                  return StreamBuilder<int>(
                    stream: provider.getPendingIssuesCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count == 0) return const SizedBox.shrink();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$count Pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IssuesManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Manage Issues'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Consumer<ChatbotProvider>(
            builder: (context, provider, child) {
              return StreamBuilder<List<IssueModel>>(
                stream: provider.getPendingIssues(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No pending issues',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All chatbot questions have been answered!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final issues = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: issues.length,
                    itemBuilder: (context, index) {
                      final issue = issues[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF10B981),
                            child: Text(
                              issue.userName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            issue.question,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Asked by ${issue.userName}'),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy • h:mm a')
                                    .format(issue.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IssuesManagementScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
