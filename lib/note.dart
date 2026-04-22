import 'dart:convert';

enum NoteColor {
  purple,
  teal,
  orange,
  pink,
  blue,
  green,
}

extension NoteColorExtension on NoteColor {
  String get hex {
    switch (this) {
      case NoteColor.purple:
        return '#7C3AED';
      case NoteColor.teal:
        return '#0D9488';
      case NoteColor.orange:
        return '#EA580C';
      case NoteColor.pink:
        return '#DB2777';
      case NoteColor.blue:
        return '#2563EB';
      case NoteColor.green:
        return '#16A34A';
    }
  }

  int get value {
    switch (this) {
      case NoteColor.purple:
        return 0xFF7C3AED;
      case NoteColor.teal:
        return 0xFF0D9488;
      case NoteColor.orange:
        return 0xFFEA580C;
      case NoteColor.pink:
        return 0xFFDB2777;
      case NoteColor.blue:
        return 0xFF2563EB;
      case NoteColor.green:
        return 0xFF16A34A;
    }
  }
}

class Note {
  final String id;
  String title;
  String content;
  String? richContent;
  DateTime createdAt;
  DateTime updatedAt;
  NoteColor color;
  bool isPinned;
  bool isFavorite;
  bool isArchived;
  List<String> tags;
  String? category;
  List<ChecklistItem> checklist;
  bool isChecklist;
  String? reminderTime;
  List<String> imageUrls;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.richContent,
    required this.createdAt,
    required this.updatedAt,
    this.color = NoteColor.purple,
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.tags = const [],
    this.category,
    this.checklist = const [],
    this.isChecklist = false,
    this.reminderTime,
    this.imageUrls = const [],
  });

  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? richContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoteColor? color,
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    List<String>? tags,
    String? category,
    List<ChecklistItem>? checklist,
    bool? isChecklist,
    String? reminderTime,
    List<String>? imageUrls,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      richContent: richContent ?? this.richContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      checklist: checklist ?? this.checklist,
      isChecklist: isChecklist ?? this.isChecklist,
      reminderTime: reminderTime ?? this.reminderTime,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'richContent': richContent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'color': color.index,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'tags': tags,
      'category': category,
      'checklist': checklist.map((e) => e.toJson()).toList(),
      'isChecklist': isChecklist,
      'reminderTime': reminderTime,
      'imageUrls': imageUrls,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      richContent: json['richContent'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      color: NoteColor.values[json['color'] ?? 0],
      isPinned: json['isPinned'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
      isArchived: json['isArchived'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'],
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map((e) => ChecklistItem.fromJson(e))
              .toList() ??
          [],
      isChecklist: json['isChecklist'] ?? false,
      reminderTime: json['reminderTime'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }

  String get preview {
    if (content.isEmpty) return 'No additional text';
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  int get charCount => content.length;
}

class ChecklistItem {
  String id;
  String text;
  bool isChecked;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isChecked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isChecked': isChecked,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        id: json['id'],
        text: json['text'],
        isChecked: json['isChecked'] ?? false,
      );
}
