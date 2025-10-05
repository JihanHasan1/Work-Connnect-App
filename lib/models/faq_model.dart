class FAQModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  FAQModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQModel.fromMap(Map<String, dynamic> map, String id) {
    return FAQModel(
      id: id,
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      category: map['category'] ?? 'General',
      viewCount: map['viewCount'] ?? 0,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'answer': answer,
      'category': category,
      'viewCount': viewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  FAQModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FAQModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
