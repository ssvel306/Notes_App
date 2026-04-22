import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../note.dart';
import '../notes_provider.dart';
import '../app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class NoteCard extends StatefulWidget {
  final Note note;
  final bool isGrid;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.isGrid,
    required this.onTap,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _showContextMenu(BuildContext ctx) {
    final provider = ctx.read<NotesProvider>();
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _NoteContextMenu(
        note: widget.note,
        onPin: () {
          provider.togglePin(widget.note.id);
          Navigator.pop(ctx);
        },
        onFavorite: () {
          provider.toggleFavorite(widget.note.id);
          Navigator.pop(ctx);
        },
        onArchive: () {
          provider.toggleArchive(widget.note.id);
          Navigator.pop(ctx);
        },
        onDelete: () {
          Navigator.pop(ctx);
          showDialog(
            context: ctx,
            builder: (dctx) => AlertDialog(
              title: const Text('Delete Note'),
              content: const Text('This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () {
                    provider.deleteNote(widget.note.id);
                    Navigator.pop(dctx);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final noteColor = Color(widget.note.color.value);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (_, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: () => _showContextMenu(context),
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) => _hoverController.reverse(),
        onTapCancel: () => _hoverController.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Color.lerp(
                    const Color(0xFF22222F), noteColor, 0.08)
                : Color.lerp(Colors.white, noteColor, 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: noteColor.withOpacity(isDark ? 0.25 : 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: noteColor.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Color accent line
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: noteColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(theme, noteColor),
                    const SizedBox(height: 8),
                    _buildContent(theme),
                    if (widget.note.isChecklist &&
                        widget.note.checklist.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildChecklistPreview(theme, noteColor),
                    ],
                    if (widget.note.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildTags(theme, noteColor),
                    ],
                    const SizedBox(height: 10),
                    _buildFooter(theme, noteColor),
                  ],
                ),
              ),
              // Pin indicator
              if (widget.note.isPinned)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: noteColor,
                  ),
                ),
              // Favorite indicator
              if (widget.note.isFavorite && !widget.note.isPinned)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: Colors.red.shade400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color noteColor) {
    if (widget.note.title.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Text(
        widget.note.title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
          height: 1.3,
        ),
        maxLines: widget.isGrid ? 2 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (widget.note.isChecklist) {
      final total = widget.note.checklist.length;
      final done = widget.note.checklist.where((c) => c.isChecked).length;
      return Text(
        '$done / $total items done',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      );
    }
    if (widget.note.content.isEmpty) return const SizedBox.shrink();
    return Text(
      widget.note.preview,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
        height: 1.55,
      ),
      maxLines: widget.isGrid ? 4 : 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildChecklistPreview(ThemeData theme, Color noteColor) {
    final items = widget.note.checklist.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                item.isChecked
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 14,
                color: item.isChecked
                    ? noteColor
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: item.isChecked
                        ? theme.colorScheme.onSurface.withOpacity(0.35)
                        : theme.colorScheme.onSurface.withOpacity(0.65),
                    decoration: item.isChecked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTags(ThemeData theme, Color noteColor) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: widget.note.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: noteColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: noteColor,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(ThemeData theme, Color noteColor) {
    return Row(
      children: [
        if (widget.note.category != null) ...[
          Icon(Icons.folder_rounded, size: 12,
              color: noteColor.withOpacity(0.7)),
          const SizedBox(width: 4),
          Text(
            widget.note.category!,
            style: TextStyle(
              fontSize: 11,
              color: noteColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
        ],
        const Spacer(),
        Text(
          widget.note.formattedDate,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// Context Menu
// ─────────────────────────────────────────
class _NoteContextMenu extends StatelessWidget {
  final Note note;
  final VoidCallback onPin;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _NoteContextMenu({
    required this.note,
    required this.onPin,
    required this.onFavorite,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noteColor = Color(note.color.value);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: noteColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.note_rounded, color: noteColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note.title.isEmpty ? 'Untitled' : note.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(note.formattedDate,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _ContextAction(
            icon: note.isPinned
                ? Icons.push_pin_rounded
                : Icons.push_pin_outlined,
            label: note.isPinned ? 'Unpin' : 'Pin to top',
            onTap: onPin,
          ),
          _ContextAction(
            icon: note.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: note.isFavorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            color: Colors.red,
            onTap: onFavorite,
          ),
          _ContextAction(
            icon: Icons.archive_rounded,
            label: note.isArchived ? 'Unarchive' : 'Archive',
            onTap: onArchive,
          ),
          _ContextAction(
            icon: Icons.delete_rounded,
            label: 'Delete',
            color: Colors.red,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ContextAction({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: TextStyle(
              color: c,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
