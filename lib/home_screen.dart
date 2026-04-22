import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notes_provider.dart';
import 'note.dart';
import 'app_theme.dart';
import 'note_card.dart';
import 'stats_header.dart';
import 'note_editor_screen.dart';
import 'archive_screen.dart';

import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  bool _isGridView = true;
  bool _isSearchActive = false;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingHeader = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 100;
    if (shouldShow != _showFloatingHeader) {
      setState(() => _showFloatingHeader = shouldShow);
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openNoteEditor({Note? note}) async {
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            NoteEditorScreen(note: note),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showSortOptions() {
    final provider = context.read<NotesProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _SortBottomSheet(provider: provider),
    );
  }

  void _showDrawer(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MenuDrawer(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
        onNavigateArchive: () {
          Navigator.pop(ctx);
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const ArchiveScreen()),
          );
        },
        onNavigateFavorites: () {
          Navigator.pop(ctx);
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF0F0F14),
                          const Color(0xFF13101F),
                        ]
                      : [
                          const Color(0xFFF5F5FF),
                          const Color(0xFFEEEEFF),
                        ],
                ),
              ),
            ),
          ),
          // Glow accent
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(theme, isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StatsHeader(),
                      const SizedBox(height: 20),
                      SearchBarWidget(
                        onSearch: (q) =>
                            context.read<NotesProvider>().setSearchQuery(q),
                      ),
                      const SizedBox(height: 16),
                      const FilterChipsRow(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Consumer<NotesProvider>(
                builder: (ctx, provider, _) {
                  final notes = provider.filteredNotes;
                  if (notes.isEmpty) {
                    return SliverFillRemaining(
                      child: _EmptyState(
                        hasSearch: provider.searchQuery.isNotEmpty,
                        onCreateNote: () => _openNoteEditor(),
                      ),
                    );
                  }
                  return _isGridView
                      ? SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => NoteCard(
                                note: notes[i],
                                isGrid: true,
                                onTap: () =>
                                    _openNoteEditor(note: notes[i]),
                              ),
                              childCount: notes.length,
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: NoteCard(
                                  note: notes[i],
                                  isGrid: false,
                                  onTap: () =>
                                      _openNoteEditor(note: notes[i]),
                                ),
                              ),
                              childCount: notes.length,
                            ),
                          ),
                        );
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'Notiva',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onBackground,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            color: theme.colorScheme.onBackground,
          ),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          tooltip: _isGridView ? 'List view' : 'Grid view',
        ),
        IconButton(
          icon: Icon(
            Icons.sort_rounded,
            color: theme.colorScheme.onBackground,
          ),
          onPressed: _showSortOptions,
          tooltip: 'Sort',
        ),
        IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: theme.colorScheme.onBackground,
          ),
          onPressed: () => _showDrawer(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openNoteEditor(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'New Note',
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

// ─────────────────────────────────────────
// Sort Bottom Sheet
// ─────────────────────────────────────────
class _SortBottomSheet extends StatelessWidget {
  final NotesProvider provider;
  const _SortBottomSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = [
      (SortOption.updatedAt, Icons.update_rounded, 'Last Modified'),
      (SortOption.createdAt, Icons.calendar_today_rounded, 'Date Created'),
      (SortOption.title, Icons.sort_by_alpha_rounded, 'Title A–Z'),
      (SortOption.color, Icons.palette_rounded, 'Color'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Sort Notes',
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = provider.sortOption == opt.$1;
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary.withOpacity(0.15)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(opt.$2,
                    size: 20,
                    color: isSelected
                        ? AppTheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              title: Text(opt.$3, style: theme.textTheme.bodyLarge),
              trailing: isSelected
                  ? Icon(
                      provider.sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: AppTheme.primary,
                      size: 18)
                  : null,
              onTap: () {
                provider.setSortOption(opt.$1);
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Menu Drawer
// ─────────────────────────────────────────
class _MenuDrawer extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onNavigateArchive;
  final VoidCallback onNavigateFavorites;

  const _MenuDrawer({
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onNavigateArchive,
    required this.onNavigateFavorites,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotesProvider>();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Menu',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                _MenuTile(
                  icon: Icons.favorite_rounded,
                  label: 'Favourites',
                  count: provider.favoriteCount,
                  color: const Color(0xFFDB2777),
                  onTap: onNavigateFavorites,
                ),
                _MenuTile(
                  icon: Icons.archive_rounded,
                  label: 'Archive',
                  count: provider.archivedNotes.length,
                  color: const Color(0xFF2563EB),
                  onTap: onNavigateArchive,
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    const Icon(Icons.dark_mode_rounded, size: 22),
                    const SizedBox(width: 12),
                    Text('Dark Mode', style: theme.textTheme.bodyLarge),
                    const Spacer(),
                    Switch.adaptive(
                      value: isDarkMode,
                      onChanged: (_) => onToggleTheme(),
                      activeColor: AppTheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${provider.totalNotes} notes · ${provider.pinnedCount} pinned',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: count > 0
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            )
          : null,
      onTap: onTap,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// ─────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onCreateNote;

  const _EmptyState({required this.hasSearch, required this.onCreateNote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.note_add_rounded,
              size: 48,
              color: AppTheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            hasSearch ? 'No notes found' : 'No notes yet',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'Tap the button below to create your first note',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Note'),
              onPressed: onCreateNote,
            ),
          ]
        ],
      ),
    );
  }
}
