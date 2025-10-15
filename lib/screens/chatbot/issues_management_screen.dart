// lib/screens/chatbot/issues_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../models/issue_model.dart';

class IssuesManagementScreen extends StatefulWidget {
  const IssuesManagementScreen({Key? key}) : super(key: key);

  @override
  State<IssuesManagementScreen> createState() => _IssuesManagementScreenState();
}

class _IssuesManagementScreenState extends State<IssuesManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final chatbotProvider = context.watch<ChatbotProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Issues'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  const SizedBox(width: 8),
                  StreamBuilder<int>(
                    stream: chatbotProvider.getPendingIssuesCount(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == 0) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Tab(text: 'All Issues'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search issues...',
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
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPendingIssues(),
                _buildAllIssues(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingIssues() {
    final chatbotProvider = context.watch<ChatbotProvider>();

    return StreamBuilder<List<IssueModel>>(
      stream: chatbotProvider.getPendingIssues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Pending Issues',
            subtitle: 'All chatbot questions have been answered! 🎉',
          );
        }

        final issues = snapshot.data!.where((issue) {
          if (_searchQuery.isEmpty) return true;
          return issue.question
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              issue.userName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (issues.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No Results',
            subtitle: 'No issues found for "$_searchQuery"',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            return _IssueCard(
              issue: issues[index],
              onTap: () => _showResolveDialog(issues[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildAllIssues() {
    final chatbotProvider = context.watch<ChatbotProvider>();

    return StreamBuilder<List<IssueModel>>(
      stream: chatbotProvider.getAllIssues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.question_answer,
            title: 'No Issues Yet',
            subtitle: 'Issues will appear here when team members ask questions',
          );
        }

        final issues = snapshot.data!.where((issue) {
          if (_searchQuery.isEmpty) return true;
          return issue.question
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              issue.userName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (issues.isEmpty) {
          return _buildEmptyState(
            icon: Icons.search_off,
            title: 'No Results',
            subtitle: 'No issues found for "$_searchQuery"',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: issues.length,
          itemBuilder: (context, index) {
            final issue = issues[index];
            return _IssueCard(
              issue: issue,
              onTap: issue.status == 'pending'
                  ? () => _showResolveDialog(issue)
                  : () => _showIssueDetails(issue),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(IssueModel issue) {
    final responseController = TextEditingController();
    bool saveToKnowledge = true;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Resolve Issue'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person,
                                size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text(
                              issue.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question
                  const Text(
                    'Question:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.question,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Response Input
                  TextFormField(
                    controller: responseController,
                    decoration: const InputDecoration(
                      labelText: 'Your Answer',
                      hintText: 'Provide a helpful answer...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please provide an answer';
                      }
                      if (value.length < 10) {
                        return 'Answer must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Save to Knowledge Checkbox
                  CheckboxListTile(
                    value: saveToKnowledge,
                    onChanged: (value) {
                      setState(() => saveToKnowledge = value ?? true);
                    },
                    title: const Text(
                      'Add to Chatbot Knowledge',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'The chatbot will use this answer for similar questions',
                      style: TextStyle(fontSize: 12),
                    ),
                    contentPadding: EdgeInsets.zero,
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
                    final auth = context.read<AuthProvider>();
                    final chatbotProvider = context.read<ChatbotProvider>();

                    await chatbotProvider.resolveIssue(
                      issue.id,
                      responseController.text.trim(),
                      auth.currentUser!.uid,
                      saveToKnowledge,
                      saveToKnowledge ? issue.question : null,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  saveToKnowledge
                                      ? 'Issue resolved and added to chatbot!'
                                      : 'Issue resolved!',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
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
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Resolve'),
            ),
          ],
        ),
      ),
    );
  }

  void _showIssueDetails(IssueModel issue) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              issue.status == 'resolved' ? Icons.check_circle : Icons.pending,
              color: issue.status == 'resolved' ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Issue Details')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('User', issue.userName),
              _buildDetailRow(
                'Asked',
                DateFormat('MMM dd, yyyy • h:mm a').format(issue.createdAt),
              ),
              const Divider(height: 24),
              const Text(
                'Question:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              Text(issue.question, style: const TextStyle(height: 1.5)),
              if (issue.teamLeaderResponse != null) ...[
                const Divider(height: 24),
                const Text(
                  'Answer:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFF10B981)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.teamLeaderResponse!,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                if (issue.resolvedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Resolved on ${DateFormat('MMM dd, yyyy • h:mm a').format(issue.resolvedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          if (issue.status == 'pending')
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showResolveDialog(issue);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Resolve'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class _IssueCard extends StatelessWidget {
  final IssueModel issue;
  final VoidCallback onTap;

  const _IssueCard({
    required this.issue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = issue.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(
                      issue.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
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
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPending ? Icons.pending : Icons.check_circle,
                          size: 14,
                          color: isPending ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPending ? 'Pending' : 'Resolved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPending ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Question
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  issue.question,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Answer (if resolved)
              if (!isPending && issue.teamLeaderResponse != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    border: Border.all(color: const Color(0xFF10B981)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue.teamLeaderResponse!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF065F46),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
