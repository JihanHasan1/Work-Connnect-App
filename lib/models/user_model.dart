class UserModel {
  final String uid;
  final String username;
  final String role; // 'admin', 'team_leader', 'team_member'
  final String? teamId;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.username,
    required this.role,
    this.teamId,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      role: map['role'] ?? 'team_member',
      teamId: map['teamId'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'role': role,
      'teamId': teamId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? role,
    String? teamId,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
