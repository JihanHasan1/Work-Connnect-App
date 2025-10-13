class TeamModel {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? lastMessage;
  final String? lastMessageBy;
  final DateTime? lastMessageAt;
  final String? imageUrl;
  final bool isActive;
  final Map<String, dynamic>? settings;
  final List<String>? pinnedMessageIds;
  final String? announcement;

  TeamModel({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.memberIds,
    required this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.lastMessageBy,
    this.lastMessageAt,
    this.imageUrl,
    this.isActive = true,
    this.settings,
    this.pinnedMessageIds,
    this.announcement,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      leaderId: map['leaderId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      lastMessage: map['lastMessage'],
      lastMessageBy: map['lastMessageBy'],
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.parse(map['lastMessageAt'])
          : null,
      imageUrl: map['imageUrl'],
      isActive: map['isActive'] ?? true,
      settings: map['settings'] != null
          ? Map<String, dynamic>.from(map['settings'])
          : null,
      pinnedMessageIds: map['pinnedMessageIds'] != null
          ? List<String>.from(map['pinnedMessageIds'])
          : null,
      announcement: map['announcement'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt':
          updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageBy': lastMessageBy,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'isActive': isActive,
      'settings': settings,
      'pinnedMessageIds': pinnedMessageIds,
      'announcement': announcement,
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? description,
    String? leaderId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    String? lastMessageBy,
    DateTime? lastMessageAt,
    String? imageUrl,
    bool? isActive,
    Map<String, dynamic>? settings,
    List<String>? pinnedMessageIds,
    String? announcement,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      leaderId: leaderId ?? this.leaderId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageBy: lastMessageBy ?? this.lastMessageBy,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      settings: settings ?? this.settings,
      pinnedMessageIds: pinnedMessageIds ?? this.pinnedMessageIds,
      announcement: announcement ?? this.announcement,
    );
  }

  // Helper methods
  int get totalMembers => memberIds.length + 1; // +1 for leader

  bool isUserMember(String userId) {
    return leaderId == userId || memberIds.contains(userId);
  }

  bool isUserLeader(String userId) {
    return leaderId == userId;
  }

  bool get hasAnnouncement => announcement != null && announcement!.isNotEmpty;

  bool get hasPinnedMessages =>
      pinnedMessageIds != null && pinnedMessageIds!.isNotEmpty;

  // Get setting value with default
  T? getSetting<T>(String key, {T? defaultValue}) {
    if (settings == null) return defaultValue;
    return settings![key] as T? ?? defaultValue;
  }

  // Check if notifications are enabled (default: true)
  bool get notificationsEnabled =>
      getSetting<bool>('notificationsEnabled', defaultValue: true) ?? true;

  // Check if members can add others (default: false)
  bool get membersCanAddOthers =>
      getSetting<bool>('membersCanAddOthers', defaultValue: false) ?? false;

  // Check if only admins can post (default: false)
  bool get onlyAdminsCanPost =>
      getSetting<bool>('onlyAdminsCanPost', defaultValue: false) ?? false;

  // Get team color (for UI customization)
  String get teamColor =>
      getSetting<String>('teamColor', defaultValue: '#6366F1') ?? '#6366F1';

  // Format last activity
  String getLastActivityText() {
    if (lastMessageAt == null) {
      return 'No messages yet';
    }

    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    String timeAgo;
    if (difference.inMinutes < 1) {
      timeAgo = 'just now';
    } else if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays}d ago';
    } else {
      timeAgo = '${(difference.inDays / 7).floor()}w ago';
    }

    if (lastMessageBy != null && lastMessage != null) {
      return '$lastMessageBy: $lastMessage • $timeAgo';
    }

    return 'Last activity $timeAgo';
  }

  // Get initials for team avatar
  String get initials {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  // Helper to get min value (since dart:math might not be imported)
  int min(int a, int b) => a < b ? a : b;
}
