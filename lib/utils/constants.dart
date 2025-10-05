// utils/constants.dart
class AppConstants {
  // App Info
  static const String appName = 'Work-Connect';
  static const String appVersion = '1.0.0';

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleTeamLeader = 'team_leader';
  static const String roleTeamMember = 'team_member';

  // Collections
  static const String usersCollection = 'users';
  static const String teamsCollection = 'teams';
  static const String faqsCollection = 'faqs';
  static const String chatbotCollection = 'chatbot';
  static const String issuesCollection = 'issues';
  static const String messagesCollection = 'messages';

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';

  // Issue Status
  static const String issueStatusPending = 'pending';
  static const String issueStatusAnswered = 'answered';
  static const String issueStatusResolved = 'resolved';

  // Colors
  static const int primaryColor = 0xFF6366F1;
  static const int secondaryColor = 0xFF8B5CF6;
  static const int accentColor = 0xFF10B981;
  static const int errorColor = 0xFFEF4444;
}
