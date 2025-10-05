class TeamModel {
  final String id;
  final String name;
  final String description;
  final String leaderId;
  final List<String> memberIds;
  final DateTime createdAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    required this.memberIds,
    required this.createdAt,
  });

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      leaderId: map['leaderId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    String? description,
    String? leaderId,
    List<String>? memberIds,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      leaderId: leaderId ?? this.leaderId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
