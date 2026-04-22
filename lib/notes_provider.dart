import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'note.dart';

enum SortOption { updatedAt, createdAt, title, color }

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedTag;
  SortOption _sortOption = SortOption.updatedAt;
  bool _sortAscending = false;

  List<Note> get allNotes => _notes.where((n) => !n.isArchived).toList();

  List<Note> get archivedNotes => _notes.where((n) => n.isArchived).toList();

  List<Note> get favoriteNotes =>
      _notes.where((n) => n.isFavorite && !n.isArchived).toList();

  List<String> get allTags {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  List<String> get allCategories {
    final cats = <String>{};
    for (final note in _notes) {
      if (note.category != null && note.category!.isNotEmpty) {
        cats.add(note.category!);
      }
    }
    return cats.toList()..sort();
  }

  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedTag => _selectedTag;
  SortOption get sortOption => _sortOption;
  bool get sortAscending => _sortAscending;

  List<Note> get filteredNotes {
    var notes = allNotes;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      notes = notes.where((n) {
        return n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q) ||
            n.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    if (_selectedCategory != null) {
      notes = notes.where((n) => n.category == _selectedCategory).toList();
    }

    if (_selectedTag != null) {
      notes = notes.where((n) => n.tags.contains(_selectedTag)).toList();
    }

    notes.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case SortOption.updatedAt:
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case SortOption.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case SortOption.title:
          comparison = a.title.compareTo(b.title);
          break;
        case SortOption.color:
          comparison = a.color.index.compareTo(b.color.index);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    final pinned = notes.where((n) => n.isPinned).toList();
    final unpinned = notes.where((n) => !n.isPinned).toList();
    return [...pinned, ...unpinned];
  }

  int get totalNotes => allNotes.length;
  int get pinnedCount => allNotes.where((n) => n.isPinned).length;
  int get favoriteCount => favoriteNotes.length;

  Future<void> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('notes') ?? [];
      _notes = raw.map((e) => Note.fromJson(jsonDecode(e))).toList();
      notifyListeners();
    } catch (e) {
      _notes = _getSampleNotes();
      notifyListeners();
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _notes.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList('notes', raw);
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    if (_sortOption == option) {
      _sortAscending = !_sortAscending;
    } else {
      _sortOption = option;
      _sortAscending = false;
    }
    notifyListeners();
  }

  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
      await _saveNotes();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx] = _notes[idx].copyWith(isPinned: !_notes[idx].isPinned);
      await _saveNotes();
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx] =
          _notes[idx].copyWith(isFavorite: !_notes[idx].isFavorite);
      await _saveNotes();
      notifyListeners();
    }
  }

  Future<void> toggleArchive(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notes[idx] =
          _notes[idx].copyWith(isArchived: !_notes[idx].isArchived);
      await _saveNotes();
      notifyListeners();
    }
  }

  Future<void> deleteAllArchived() async {
    _notes.removeWhere((n) => n.isArchived);
    await _saveNotes();
    notifyListeners();
  }

  List<Note> _getSampleNotes() {
    final now = DateTime.now();
    return [
      Note(
        id: '1',
        title: '🚀 Welcome to Notiva!',
        content:
            'This is your intelligent notes companion. Create, organize, and discover your thoughts with beautiful simplicity.\n\n• Pin important notes\n• Add tags and categories\n• Search instantly\n• Archive old notes',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        color: NoteColor.purple,
        isPinned: true,
        tags: ['welcome', 'tutorial'],
        category: 'Personal',
      ),
      Note(
        id: '2',
        title: '📋 Shopping List',
        content: '',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        color: NoteColor.teal,
        isChecklist: true,
        checklist: [
          ChecklistItem(id: 'c1', text: 'Milk & Eggs', isChecked: true),
          ChecklistItem(id: 'c2', text: 'Fresh vegetables'),
          ChecklistItem(id: 'c3', text: 'Coffee beans'),
          ChecklistItem(id: 'c4', text: 'Whole grain bread'),
        ],
        tags: ['shopping', 'groceries'],
        category: 'Personal',
      ),
      Note(
        id: '3',
        title: '💡 Flutter Project Ideas',
        content:
            'Ideas for my next Flutter project:\n\n1. AR Navigation App\n2. AI-powered Journaling\n3. Real-time Collaboration Tool\n4. Fitness Tracker with ML\n5. Smart Budget Manager',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
        color: NoteColor.orange,
        isFavorite: true,
        tags: ['flutter', 'ideas', 'development'],
        category: 'Work',
      ),
      Note(
        id: '4',
        title: '📖 Book Notes: Atomic Habits',
        content:
            'Key takeaways from Atomic Habits by James Clear:\n\n"Every action is a vote for the type of person you want to become."\n\nThe 1% rule: Small improvements compound over time. Focus on systems not goals. Make good habits obvious, attractive, easy, and satisfying.',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 2)),
        color: NoteColor.blue,
        tags: ['books', 'habits', 'learning'],
        category: 'Learning',
      ),
      Note(
        id: '5',
        title: '🎯 Q4 Goals',
        content:
            'Goals for this quarter:\n\n✅ Launch portfolio website\n⬜ Complete Flutter certification\n⬜ Build 3 production apps\n⬜ Contribute to open source\n⬜ Get 500 GitHub stars',
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 4)),
        color: NoteColor.pink,
        isFavorite: true,
        tags: ['goals', 'career'],
        category: 'Work',
      ),
    ];
  }
}
