class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // 'text', 'image', 'file', 'system'
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSender;
  final List<String>? mentionedUserIds;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = 'text',
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.editedAt,
    this.replyToId,
    this.replyToContent,
    this.replyToSender,
    this.mentionedUserIds,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] ?? 'text',
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      editedAt:
          map['editedAt'] != null ? DateTime.parse(map['editedAt']) : null,
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      replyToSender: map['replyToSender'],
      mentionedUserIds: map['mentionedUserIds'] != null
          ? List<String>.from(map['mentionedUserIds'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToSender': replyToSender,
      'mentionedUserIds': mentionedUserIds,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? content,
    String? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    DateTime? editedAt,
    String? replyToId,
    String? replyToContent,
    String? replyToSender,
    List<String>? mentionedUserIds,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSender: replyToSender ?? this.replyToSender,
      mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
    );
  }

  // Helper method to check if message is a system message
  bool get isSystemMessage => type == 'system';

  // Helper method to check if message has a file
  bool get hasFile => type == 'file' && fileUrl != null;

  // Helper method to check if message has an image
  bool get hasImage => type == 'image' && fileUrl != null;

  // Helper method to check if message is a reply
  bool get isReply => replyToId != null;

  // Helper method to check if user is mentioned
  bool isUserMentioned(String userId) {
    return mentionedUserIds?.contains(userId) ?? false;
  }

  // Format file size for display
  String get formattedFileSize {
    if (fileSize == null) return '';

    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = fileSize!.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  // Get file extension from file name
  String? get fileExtension {
    if (fileName == null) return null;
    final parts = fileName!.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return null;
  }

  // Check if file is an image based on extension
  bool get isImageFile {
    final ext = fileExtension;
    if (ext == null) return false;
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    return imageExtensions.contains(ext);
  }

  // Check if file is a document
  bool get isDocumentFile {
    final ext = fileExtension;
    if (ext == null) return false;
    const docExtensions = [
      'pdf',
      'doc',
      'docx',
      'txt',
      'xls',
      'xlsx',
      'ppt',
      'pptx'
    ];
    return docExtensions.contains(ext);
  }

  // Get appropriate icon for file type
  String getFileIcon() {
    if (isImageFile) return '🖼️';
    if (isDocumentFile) return '📄';

    final ext = fileExtension;
    if (ext == null) return '📎';

    switch (ext) {
      case 'zip':
      case 'rar':
      case '7z':
        return '🗜️';
      case 'mp3':
      case 'wav':
      case 'flac':
        return '🎵';
      case 'mp4':
      case 'avi':
      case 'mov':
        return '🎬';
      default:
        return '📎';
    }
  }
}
