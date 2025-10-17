import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chatbot_provider.dart';
import '../../models/issue_model.dart';
import '../../services/notification_service.dart';
import '../chatbot/issues_management_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ChatbotProvider>().loadBotKnowledge();
      _addMessage(
        'Hello! 👋 I\'m your Chatbot Assistant. How can I help you today?',
        isBot: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Bot Header
          _buildHeader(),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),

          // Input
          _MessageInput(
            controller: _messageController,
            onSend: _handleSendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final auth = context.watch<AuthProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ChatBot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Get Your Answers Instantly!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Issues button for team leaders/admins
          if (auth.isTeamLeader)
            Consumer<ChatbotProvider>(
              builder: (context, provider, child) {
                return StreamBuilder<int>(
                  stream: provider.getPendingIssuesCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;

                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const IssuesManagementScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.assignment_outlined,
                            color: Color(0xFF1E293B),
                          ),
                          tooltip: 'Pending Issues',
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(200),
                const SizedBox(width: 4),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(
          opacity: (value * 2) % 1.0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _addMessage(String content, {required bool isBot}) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isBot: isBot,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _addMessage(userMessage, isBot: false);
    _messageController.clear();

    // Show typing indicator
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _isTyping = false);

    final botProvider = context.read<ChatbotProvider>();
    final response = botProvider.getBotResponse(userMessage);

    if (response != null) {
      _addMessage(response, isBot: true);

      // Add helpful follow-up
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isTyping = true);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _isTyping = false);

      _addMessage(
        'Was this helpful? Feel free to ask more questions! 😊',
        isBot: true,
      );
    } else {
      // No match found - Forward to admin/team leaders
      _addMessage(
        'Sorry, I don\'t know the answer to this yet. 😔',
        isBot: true,
      );

      // Create issue - Forward to admin and team leaders
      final auth = context.read<AuthProvider>();
      final issue = IssueModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: auth.currentUser!.uid,
        userName: auth.currentUser!.displayName ?? auth.currentUser!.username,
        question: userMessage,
        botResponse: null,
        status: 'pending',
        teamLeaderResponse: null,
        teamLeaderId: null,
        createdAt: DateTime.now(),
        resolvedAt: null,
      );

      try {
        await botProvider.createIssue(issue);
        debugPrint('✅ Issue created and forwarded to admins/team leaders');

        // Send notifications to admin and team leaders
        await _sendIssueNotifications(issue);

        await Future.delayed(const Duration(milliseconds: 400));
        setState(() => _isTyping = true);
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() => _isTyping = false);

        _addMessage(
          'But ✅ Your question has been forwarded to our team leaders.\n\n'
          'They will review it and add the answer to my knowledge base. '
          'You can ask me again later! 🎯',
          isBot: true,
        );
      } catch (e) {
        debugPrint('❌ Error creating issue: $e');
        _addMessage(
          '❌ Sorry, I couldn\'t forward your question. Please try again or contact support directly.',
          isBot: true,
        );
      }
    }
  }

  Future<void> _sendIssueNotifications(IssueModel issue) async {
    try {
      // Get all admins and team leaders from Firestore
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: ['admin', 'team_leader']).get();

      final recipientIds = usersSnapshot.docs.map((doc) => doc.id).toList();

      if (recipientIds.isEmpty) {
        debugPrint('⚠️ No admins or team leaders found to notify');
        return;
      }

      // Get FCM tokens for recipients
      List<String> tokens = [];
      for (String userId in recipientIds) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data();
          String? token = data?['fcmToken'];
          if (token != null && token.isNotEmpty) {
            tokens.add(token);
          }
        }
      }

      debugPrint(
          '✅ Found ${recipientIds.length} admins/team leaders, ${tokens.length} with FCM tokens');

      // Note: In production, you would call your backend API here to send FCM notifications
      // For now, we'll just log the notification details
      debugPrint('📤 Would send notification:');
      debugPrint('   Title: New Question from ${issue.userName}');
      debugPrint('   Body: ${issue.question}');
      debugPrint('   Recipients: ${recipientIds.length}');
    } catch (e) {
      debugPrint('⚠️ Error sending notifications: $e');
      // Don't throw - notification failure shouldn't break the flow
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String content;
  final bool isBot;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isBot,
    required this.timestamp,
  });
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isBot ? Colors.white : const Color(0xFF1E293B),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isBot ? 4 : 16),
                  bottomRight: Radius.circular(message.isBot ? 16 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isBot
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: message.isBot ? Colors.grey[500] : Colors.white70,
                    ),
                  ),
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

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

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
      setState(() => _canSend = canSend);
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
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _canSend ? (_) => widget.onSend() : null,
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: _canSend
                    ? const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)])
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
