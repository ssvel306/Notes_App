import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notes_provider.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────
// Stats Header
// ─────────────────────────────────────────
class StatsHeader extends StatelessWidget {
  const StatsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stats = [
      _StatItem(
        value: provider.totalNotes,
        label: 'Total',
        icon: Icons.notes_rounded,
        color: AppTheme.primary,
      ),
      _StatItem(
        value: provider.pinnedCount,
        label: 'Pinned',
        icon: Icons.push_pin_rounded,
        color: const Color(0xFF0D9488),
      ),
      _StatItem(
        value: provider.favoriteCount,
        label: 'Favourites',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFDB2777),
      ),
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final stat = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: entry.key < stats.length - 1 ? 10 : 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Color.lerp(const Color(0xFF1A1A24), stat.color, 0.08)
                  : Color.lerp(Colors.white, stat.color, 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: stat.color.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(stat.icon, color: stat.color, size: 18),
                const SizedBox(height: 8),
                Text(
                  '${stat.value}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: stat.color,
                  ),
                ),
                Text(
                  stat.label,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ─────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────
class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;

  const SearchBarWidget({super.key, required this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      widget.onSearch(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search notes, tags...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            size: 22,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Filter Chips Row
// ─────────────────────────────────────────
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = provider.allCategories;
    final tags = provider.allTags;

    if (categories.isEmpty && tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // All
          _FilterChip(
            label: 'All',
            isSelected: provider.selectedCategory == null &&
                provider.selectedTag == null,
            onTap: () {
              provider.setSelectedCategory(null);
              provider.setSelectedTag(null);
            },
          ),
          const SizedBox(width: 8),
          // Categories
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: cat,
                  isSelected: provider.selectedCategory == cat,
                  icon: Icons.folder_rounded,
                  onTap: () {
                    provider.setSelectedCategory(
                        provider.selectedCategory == cat ? null : cat);
                    provider.setSelectedTag(null);
                  },
                ),
              )),
          // Tags
          ...tags.map((tag) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: '#$tag',
                  isSelected: provider.selectedTag == tag,
                  onTap: () {
                    provider.setSelectedTag(
                        provider.selectedTag == tag ? null : tag);
                    provider.setSelectedCategory(null);
                  },
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
