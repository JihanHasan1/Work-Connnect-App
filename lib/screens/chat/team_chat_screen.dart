import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/team_model.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class TeamChatScreen extends StatefulWidget {
  final TeamModel team;

  const TeamChatScreen({Key? key, required this.team}) : super(key: key);

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late TeamModel _currentTeam;

  @override
  void initState() {
    super.initState();
    _currentTeam = widget.team;
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.team.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _currentTeam = TeamModel.fromMap(snapshot.data()!, snapshot.id);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chatProvider = context.watch<ChatProvider>();

    final isMember = auth.isAdmin ||
        _currentTeam.leaderId == auth.currentUser?.uid ||
        _currentTeam.memberIds.contains(auth.currentUser?.uid);

    final canManageMembers =
        auth.isAdmin || _currentTeam.leaderId == auth.currentUser?.uid;

    debugPrint('🔍 Current User ID: ${auth.currentUser?.uid}');
    debugPrint('🔍 Team Leader ID: ${_currentTeam.leaderId}');
    debugPrint('🔍 Is Admin: ${auth.isAdmin}');
    debugPrint('🔍 Can Manage Members: $canManageMembers');

    if (!isMember) {
      return Scaffold(
        appBar: AppBar(title: Text(_currentTeam.name)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Access Restricted',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700])),
              const SizedBox(height: 8),
              Text('You are not a member of this team',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentTeam.name),
            Text('${_currentTeam.memberIds.length + 1} members',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _showViewMembersDialog(context),
            tooltip: 'View Members',
          ),
          if (canManageMembers)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                debugPrint('➕ Add Members button tapped');
                _showAddMembersDialog(context);
              },
              tooltip: 'Add Members',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_currentTeam.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF1E293B).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.campaign,
                      color: Color(0xFF1E293B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_currentTeam.description,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF1E293B)))),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatProvider.getTeamMessages(_currentTeam.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No messages yet',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('Start the conversation!',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[500])),
                      ],
                    ),
                  );
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == auth.currentUser?.uid;
                    bool showDateSeparator = false;
                    if (index == messages.length - 1) {
                      showDateSeparator = true;
                    } else {
                      final currentDate = DateTime(message.timestamp.year,
                          message.timestamp.month, message.timestamp.day);
                      final nextDate = DateTime(
                          messages[index + 1].timestamp.year,
                          messages[index + 1].timestamp.month,
                          messages[index + 1].timestamp.day);
                      showDateSeparator = currentDate != nextDate;
                    }
                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(date: message.timestamp),
                        _MessageBubble(
                            message: message, isMe: isMe, showSender: !isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _MessageInput(
              controller: _messageController,
              onSend: () => _sendMessage(auth, chatProvider)),
        ],
      ),
    );
  }

  Future<void> _sendMessage(
      AuthProvider auth, ChatProvider chatProvider) async {
    if (_messageController.text.trim().isEmpty) return;
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: auth.currentUser!.uid,
      senderName: auth.currentUser!.displayName ?? auth.currentUser!.username,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );
    await chatProvider.sendMessage(_currentTeam.id, message);
    _messageController.clear();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _showViewMembersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _ViewMembersSheet(
            team: _currentTeam, scrollController: scrollController),
      ),
    );
  }

  void _showAddMembersDialog(BuildContext context) {
    debugPrint('🎯 Opening Add Members Dialog');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _AddMembersSheet(
          team: _currentTeam,
          scrollController: scrollController,
          onMembersAdded: () => setState(() {}),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ViewMembersSheet extends StatefulWidget {
  final TeamModel team;
  final ScrollController scrollController;
  const _ViewMembersSheet({required this.team, required this.scrollController});
  @override
  State<_ViewMembersSheet> createState() => _ViewMembersSheetState();
}

class _ViewMembersSheetState extends State<_ViewMembersSheet> {
  List<UserModel> _members = [];
  UserModel? _leader;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final leaderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.team.leaderId)
          .get();
      if (leaderDoc.exists) {
        _leader = UserModel.fromMap(leaderDoc.data()!, leaderDoc.id);
      }
      final membersList = <UserModel>[];
      for (String memberId in widget.team.memberIds) {
        final memberDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();
        if (memberDoc.exists) {
          membersList.add(UserModel.fromMap(memberDoc.data()!, memberDoc.id));
        }
      }
      setState(() {
        _members = membersList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading members: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF1E293B)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(
                      'Team Members (${widget.team.memberIds.length + 1})',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: widget.scrollController,
                    children: [
                      if (_leader != null) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Team Leader',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B))),
                        ),
                        _MemberCard(user: _leader!, isLeader: true),
                        const SizedBox(height: 16),
                      ],
                      if (_members.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Members',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B))),
                        ),
                        ..._members.map((member) => _MemberCard(user: member)),
                      ],
                      if (_members.isEmpty && _leader != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text('No other members yet',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel user;
  final bool isLeader;
  const _MemberCard({required this.user, this.isLeader = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor:
                  isLeader ? Colors.amber : const Color(0xFF1E293B),
              child: Text(user.username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white)),
            ),
            if (isLeader)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.star, color: Colors.amber, size: 12),
                ),
              ),
          ],
        ),
        title: Text(user.displayName ?? user.username,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('@${user.username}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLeader
                        ? Colors.amber.withOpacity(0.2)
                        : user.role == 'team_leader'
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isLeader
                        ? 'TEAM LEADER'
                        : user.role.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isLeader
                          ? Colors.amber[800]
                          : user.role == 'team_leader'
                              ? Colors.blue
                              : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMembersSheet extends StatefulWidget {
  final TeamModel team;
  final ScrollController scrollController;
  final VoidCallback onMembersAdded;
  const _AddMembersSheet(
      {required this.team,
      required this.scrollController,
      required this.onMembersAdded});
  @override
  State<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends State<_AddMembersSheet> {
  final _searchController = TextEditingController();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      debugPrint('📥 Loading available users...');
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) =>
              user.uid != widget.team.leaderId &&
              !widget.team.memberIds.contains(user.uid))
          .toList();
      debugPrint('✅ Found ${users.length} available users to add');
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final username = user.username.toLowerCase();
        final displayName = (user.displayName ?? '').toLowerCase();
        final searchQuery = query.toLowerCase();
        return username.contains(searchQuery) ||
            displayName.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _addSelectedMembers() async {
    if (_selectedUserIds.isEmpty) return;
    try {
      debugPrint('➕ Adding ${_selectedUserIds.length} members...');
      final currentMembers = List<String>.from(widget.team.memberIds);
      currentMembers.addAll(_selectedUserIds);
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.team.id)
          .update({
        'memberIds': currentMembers,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Members added successfully');
      widget.onMembersAdded();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        '${_selectedUserIds.length} member(s) added successfully')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error adding members: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                  child: Text('Add Team Members',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              if (_selectedUserIds.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _addSelectedMembers,
                  icon: const Icon(Icons.add),
                  label: Text('Add (${_selectedUserIds.length})'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _filterUsers,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterUsers('');
                      })
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                _searchController.text.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.group_add,
                                size: 80,
                                color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                                _searchController.text.isNotEmpty
                                    ? 'No users found'
                                    : 'All users are already members',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: widget.scrollController,
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isSelected =
                              _selectedUserIds.contains(user.uid);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedUserIds.add(user.uid);
                                    debugPrint('✅ Selected: ${user.username}');
                                  } else {
                                    _selectedUserIds.remove(user.uid);
                                    debugPrint(
                                        '❌ Deselected: ${user.username}');
                                  }
                                });
                              },
                              secondary: CircleAvatar(
                                backgroundColor: const Color(0xFF1E293B),
                                child: Text(user.username[0].toUpperCase(),
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                              title: Text(user.displayName ?? user.username,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('@${user.username}'),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.role == 'team_leader'
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.role
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: user.role == 'team_leader'
                                            ? Colors.blue
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_formatDate(date),
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showSender;
  const _MessageBubble(
      {required this.message, required this.isMe, required this.showSender});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1E293B),
              child: Text(message.senderName[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && showSender)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(message.senderName,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                    ),
                  Text(message.content,
                      style: TextStyle(
                          fontSize: 15,
                          color: isMe ? Colors.white : const Color(0xFF1E293B),
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(DateFormat('h:mm a').format(message.timestamp),
                      style: TextStyle(
                          fontSize: 11,
                          color: isMe ? Colors.white70 : Colors.grey[500])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _MessageInput({required this.controller, required this.onSend});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_checkCanSend);
  }

  void _checkCanSend() {
    final canSend = widget.controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() {
        _canSend = canSend;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: widget.controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _canSend ? (_) => widget.onSend() : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: _canSend
                    ? const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF334155)])
                    : null,
                color: _canSend ? null : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _canSend ? widget.onSend : null,
                icon: Icon(Icons.send,
                    color: _canSend ? Colors.white : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkCanSend);
    super.dispose();
  }
}
