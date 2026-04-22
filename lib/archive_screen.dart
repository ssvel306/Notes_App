import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notes_provider.dart';
import 'note.dart';
import 'note_card.dart';
import 'note_editor_screen.dart';

// ─────────────────────────────────────────
// Archive Screen
// ─────────────────────────────────────────
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archive'),
        actions: [
          Consumer<NotesProvider>(
            builder: (ctx, provider, _) => provider.archivedNotes.isNotEmpty
                ? TextButton.icon(
                    onPressed: () => _confirmDeleteAll(ctx, provider),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (ctx, provider, _) {
          final notes = provider.archivedNotes;
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.archive_rounded,
                      size: 64,
                      color: theme.colorScheme.onBackground.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Archive is empty',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Archived notes will appear here',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: notes.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NoteCard(
                note: notes[i],
                isGrid: false,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                      builder: (_) => NoteEditorScreen(note: notes[i])),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteAll(BuildContext ctx, NotesProvider provider) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Clear Archive'),
        content: const Text(
            'Permanently delete all archived notes? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteAllArchived();
              Navigator.pop(dctx);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Favorites Screen
// ─────────────────────────────────────────
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: Consumer<NotesProvider>(
        builder: (ctx, provider, _) {
          final notes = provider.favoriteNotes;
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 64,
                      color: theme.colorScheme.onBackground.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No favorites yet',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Tap ♥ on any note to add it here',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: notes.length,
            itemBuilder: (_, i) => NoteCard(
              note: notes[i],
              isGrid: true,
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                    builder: (_) => NoteEditorScreen(note: notes[i])),
              ),
            ),
          );
        },
      ),
    );
  }
}
