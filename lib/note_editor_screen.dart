import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../note.dart';
import '../notes_provider.dart';
import '../app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _tagController;
  late NoteColor _selectedColor;
  late bool _isPinned;
  late bool _isFavorite;
  late bool _isChecklist;
  late List<ChecklistItem> _checklistItems;
  late List<String> _tags;
  late String? _category;
  bool _hasChanges = false;
  bool _showColorPicker = false;
  bool _showTagInput = false;
  late AnimationController _colorAnimController;
  late Animation<double> _colorAnimation;

  final List<String> _categories = [
    'Personal', 'Work', 'Learning', 'Health', 'Finance', 'Ideas', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagController = TextEditingController();
    _selectedColor = note?.color ?? NoteColor.purple;
    _isPinned = note?.isPinned ?? false;
    _isFavorite = note?.isFavorite ?? false;
    _isChecklist = note?.isChecklist ?? false;
    _checklistItems = List.from(note?.checklist ?? []);
    _tags = List.from(note?.tags ?? []);
    _category = note?.category;
    _colorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _colorAnimation = CurvedAnimation(
      parent: _colorAnimController,
      curve: Curves.easeOut,
    );
    _titleController.addListener(() => _hasChanges = true);
    _contentController.addListener(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _colorAnimController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final provider = context.read<NotesProvider>();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _checklistItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note is empty — nothing to save')),
      );
      return;
    }

    final now = DateTime.now();

    if (widget.note == null) {
      final note = Note(
        id: const Uuid().v4(),
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        createdAt: now,
        updatedAt: now,
        color: _selectedColor,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        isChecklist: _isChecklist,
        checklist: _checklistItems,
        tags: _tags,
        category: _category,
      );
      await provider.addNote(note);
    } else {
      final updated = widget.note!.copyWith(
        title: title.isEmpty ? 'Untitled' : title,
        content: content,
        updatedAt: now,
        color: _selectedColor,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        isChecklist: _isChecklist,
        checklist: _checklistItems,
        tags: _tags,
        category: _category,
      );
      await provider.updateNote(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content:
            const Text('Are you sure? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              if (widget.note != null) {
                await context.read<NotesProvider>().deleteNote(widget.note!.id);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addChecklistItem() {
    setState(() {
      _checklistItems.add(ChecklistItem(
        id: const Uuid().v4(),
        text: '',
      ));
    });
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final noteColorValue = Color(_selectedColor.value);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F0F14),
                    Color.lerp(const Color(0xFF0F0F14), noteColorValue, 0.05)!,
                  ]
                : [
                    Colors.white,
                    Color.lerp(Colors.white, noteColorValue, 0.04)!,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(theme, isDark, noteColorValue),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildColorAccentBar(noteColorValue),
                      const SizedBox(height: 16),
                      _buildTitleField(theme),
                      const SizedBox(height: 12),
                      if (!_isChecklist)
                        _buildContentField(theme)
                      else
                        _buildChecklist(theme),
                      const SizedBox(height: 16),
                      _buildMetaSection(theme, noteColorValue),
                      if (_showColorPicker) ...[
                        const SizedBox(height: 16),
                        _buildColorPicker(theme),
                      ],
                      if (_showTagInput) ...[
                        const SizedBox(height: 16),
                        _buildTagSection(theme),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildSaveFAB(noteColorValue),
    );
  }

  Widget _buildTopBar(ThemeData theme, bool isDark, Color noteColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.colorScheme.onBackground,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          // Stats chip
          if (widget.note != null || _contentController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: noteColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_contentController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} words',
                style: TextStyle(
                  fontSize: 12,
                  color: noteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: _isPinned ? noteColor : theme.colorScheme.onBackground.withOpacity(0.5),
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.red : theme.colorScheme.onBackground.withOpacity(0.5),
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          if (widget.note != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.withOpacity(0.7),
              ),
              onPressed: _confirmDelete,
            ),
        ],
      ),
    );
  }

  Widget _buildColorAccentBar(Color noteColor) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [noteColor, noteColor.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitleField(ThemeData theme) {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: theme.colorScheme.onBackground,
      ),
      decoration: InputDecoration(
        hintText: 'Note title...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onBackground.withOpacity(0.25),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildContentField(ThemeData theme) {
    return TextField(
      controller: _contentController,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onBackground.withOpacity(0.85),
        height: 1.7,
      ),
      decoration: InputDecoration(
        hintText: 'Start writing...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          color: theme.colorScheme.onBackground.withOpacity(0.3),
          height: 1.7,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      minLines: 6,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildChecklist(ThemeData theme) {
    return Column(
      children: [
        ..._checklistItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _checklistItems[i] = ChecklistItem(
                        id: item.id,
                        text: item.text,
                        isChecked: !item.isChecked,
                      );
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.isChecked
                          ? Color(_selectedColor.value)
                          : Colors.transparent,
                      border: Border.all(
                        color: item.isChecked
                            ? Color(_selectedColor.value)
                            : theme.colorScheme.onBackground.withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: item.isChecked
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: item.text)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: item.text.length),
                      ),
                    onChanged: (v) {
                      _checklistItems[i] = ChecklistItem(
                        id: item.id,
                        text: v,
                        isChecked: item.isChecked,
                      );
                    },
                    style: TextStyle(
                      decoration: item.isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: item.isChecked
                          ? theme.colorScheme.onBackground.withOpacity(0.4)
                          : theme.colorScheme.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'List item...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.colorScheme.onBackground.withOpacity(0.3),
                  ),
                  onPressed: () => setState(
                      () => _checklistItems.removeAt(i)),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addChecklistItem,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add item'),
          style: TextButton.styleFrom(
            foregroundColor: Color(_selectedColor.value),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaSection(ThemeData theme, Color noteColor) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Color toggle
        _ToolChip(
          icon: Icons.palette_rounded,
          label: 'Color',
          color: noteColor,
          isActive: _showColorPicker,
          onTap: () {
            setState(() {
              _showColorPicker = !_showColorPicker;
              if (_showColorPicker) {
                _colorAnimController.forward();
              } else {
                _colorAnimController.reverse();
              }
            });
          },
        ),
        // Checklist toggle
        _ToolChip(
          icon: Icons.checklist_rounded,
          label: 'Checklist',
          color: noteColor,
          isActive: _isChecklist,
          onTap: () => setState(() => _isChecklist = !_isChecklist),
        ),
        // Tags toggle
        _ToolChip(
          icon: Icons.label_rounded,
          label: _tags.isEmpty ? 'Tags' : 'Tags (${_tags.length})',
          color: noteColor,
          isActive: _showTagInput,
          onTap: () => setState(() => _showTagInput = !_showTagInput),
        ),
        // Category
        _CategoryChip(
          categories: _categories,
          selected: _category,
          color: noteColor,
          onSelected: (c) => setState(() => _category = c),
        ),
      ],
    );
  }

  Widget _buildColorPicker(ThemeData theme) {
    final colors = NoteColor.values;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note Color',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: colors.map((color) {
              final isSelected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 44 : 36,
                  height: isSelected ? 44 : 36,
                  decoration: BoxDecoration(
                    color: Color(color.value),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Colors.white,
                            width: 3,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(color.value).withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tags', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text('#$tag',
                            style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => _removeTag(tag),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: InputDecoration(
                    hintText: 'Add a tag...',
                    prefixText: '#',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: _addTag,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addTag(_tagController.text),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveFAB(Color noteColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [noteColor, noteColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: noteColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saveNote,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Save Note',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _ToolChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: isActive ? color : theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? color : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final Color color;
  final ValueChanged<String?> onSelected;

  const _CategoryChip({
    required this.categories,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => _CategorySheet(
            categories: categories,
            selected: selected,
            onSelected: (c) {
              onSelected(c);
              Navigator.pop(ctx);
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected != null
              ? color.withOpacity(0.15)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null
                ? color
                : theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_rounded,
                size: 16,
                color: selected != null
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              selected ?? 'Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected != null
                    ? color
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySheet extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategorySheet({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select Category', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (selected != null)
            ListTile(
              leading: const Icon(Icons.clear_rounded),
              title: const Text('No Category'),
              onTap: () => onSelected(null),
            ),
          ...categories.map((cat) => ListTile(
                leading: Icon(
                  Icons.folder_rounded,
                  color: selected == cat ? AppTheme.primary : null,
                ),
                title: Text(cat),
                trailing: selected == cat
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () => onSelected(cat),
              )),
        ],
      ),
    );
  }
}
