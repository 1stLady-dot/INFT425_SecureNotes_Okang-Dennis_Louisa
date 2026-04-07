
class Note {
  final String id;
  String title;
  String content;
  DateTime lastEdited;
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.lastEdited,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'lastEdited': lastEdited.toIso8601String(),
    'isPinned': isPinned,
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    lastEdited: DateTime.parse(json['lastEdited']),
    isPinned: json['isPinned'] ?? false,
  );

  Note copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? lastEdited,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      lastEdited: lastEdited ?? this.lastEdited,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}