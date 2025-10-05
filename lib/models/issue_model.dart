class IssueModel {
  final String id;
  final String userId;
  final String userName;
  final String question;
  final String? botResponse;
  final String status; // 'pending', 'answered', 'resolved'
  final String? teamLeaderResponse;
  final String? teamLeaderId;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  IssueModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.question,
    this.botResponse,
    this.status = 'pending',
    this.teamLeaderResponse,
    this.teamLeaderId,
    required this.createdAt,
    this.resolvedAt,
  });

  factory IssueModel.fromMap(Map<String, dynamic> map, String id) {
    return IssueModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      question: map['question'] ?? '',
      botResponse: map['botResponse'],
      status: map['status'] ?? 'pending',
      teamLeaderResponse: map['teamLeaderResponse'],
      teamLeaderId: map['teamLeaderId'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      resolvedAt:
          map['resolvedAt'] != null ? DateTime.parse(map['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'question': question,
      'botResponse': botResponse,
      'status': status,
      'teamLeaderResponse': teamLeaderResponse,
      'teamLeaderId': teamLeaderId,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  IssueModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? question,
    String? botResponse,
    String? status,
    String? teamLeaderResponse,
    String? teamLeaderId,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return IssueModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      question: question ?? this.question,
      botResponse: botResponse ?? this.botResponse,
      status: status ?? this.status,
      teamLeaderResponse: teamLeaderResponse ?? this.teamLeaderResponse,
      teamLeaderId: teamLeaderId ?? this.teamLeaderId,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
