# 📝 Notiva — Flutter Notes App

A beautiful, feature-rich notes application built with Flutter. Designed to showcase production-quality code architecture, modern UI design, and thoughtful UX — perfect for your portfolio.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📝 Rich Notes | Full title + body text editor |
| ✅ Checklists | Tap-to-check todo lists inside notes |
| 🎨 Note Colors | 6 accent colors with gradient theming |
| 📌 Pin Notes | Pinned notes appear at top |
| ❤️ Favorites | Mark and browse favourite notes |
| 🗂 Categories | Folder-style categories (Work, Personal, etc.) |
| 🏷 Tags | Multi-tag system with filter chips |
| 🔍 Search | Real-time full-text search across title, content, tags |
| 🗃 Archive | Archive notes instead of deleting |
| 📊 Stats Header | Live notes count, pinned, and favorites stats |
| 🌙 Dark/Light Mode | Smooth theme toggle |
| 📐 Grid / List View | Switch between layouts |
| 🔃 Sort Options | Sort by date, title, or color |
| 📱 Long-press Context Menu | Pin, favorite, archive, delete |
| 💾 Persistent Storage | Notes saved with SharedPreferences |
| ✨ Animations | Press animations, color transitions |
| 📏 Word Count | Live word count in editor |

---

## 🏗 Architecture

```
lib/
├── main.dart                    # App entry + Provider setup
├── models/
│   └── note.dart                # Note + ChecklistItem models
├── providers/
│   └── notes_provider.dart      # State management (ChangeNotifier)
├── screens/
│   ├── home_screen.dart         # Main notes list screen
│   ├── note_editor_screen.dart  # Create/edit note screen
│   ├── archive_screen.dart      # Archive + Favorites screens
│   └── favorites_screen.dart    # (re-exports from archive_screen)
├── widgets/
│   ├── note_card.dart           # Note card (grid + list)
│   ├── stats_header.dart        # Stats + SearchBar + FilterChips
│   ├── search_bar_widget.dart   # Barrel export
│   └── filter_chips.dart        # Barrel export
└── theme/
    └── app_theme.dart           # Dark + Light ThemeData
```

### Design Patterns Used
- **Provider** for reactive state management
- **ChangeNotifier** pattern for notes store
- **Repository-style** provider with load/save abstraction
- **Model-View separation** (models never touch UI)
- **Barrel exports** for clean imports
- **Factory constructors** and `copyWith` on models

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0

### Setup

```bash
# Clone / create project
flutter create notiva
cd notiva

# Replace lib/ with the provided source files
# Replace pubspec.yaml

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Dependencies

```yaml
provider: ^6.1.2          # State management
google_fonts: ^6.2.1      # Plus Jakarta Sans font
shared_preferences: ^2.2.3 # Local persistence
uuid: ^4.4.0              # Unique note IDs
```

---

## 📸 Key Screens

### Home Screen
- Animated gradient background with color glow
- Stats cards (total / pinned / favorites)
- Real-time search bar
- Category and tag filter chips
- Grid (2-col) and List view toggle
- Floating "New Note" button with gradient

### Note Editor
- Full-screen editor with color-matched gradient
- Title (large, bold) + body text
- Checklist mode toggle
- Color picker (6 accent colors)
- Tag manager with add/remove
- Category selector
- Pin and Favorite toggles
- Live word count chip
- Color-matched save button

### Note Cards
- Left accent color bar
- Tag chips
- Checklist progress preview
- Category icon
- Relative time ("2h ago", "Yesterday")
- Long-press context menu

---

## 🎨 Design System

| Token | Value |
|---|---|
| Primary | `#7C3AED` (Purple) |
| Secondary | `#0D9488` (Teal) |
| Accent | `#EA580C` (Orange) |
| Font | Plus Jakarta Sans |
| Dark BG | `#0F0F14` |
| Card radius | `20px` |
| Accent bar | `4px` left border |

---

## 💡 Resume Highlights

- **State Management**: Provider + ChangeNotifier with reactive UI
- **Persistence**: SharedPreferences with JSON serialization
- **Custom Widgets**: Reusable, parameterized components
- **Animations**: Scale press, color transitions, slide page routes
- **Architecture**: Clean separation of concerns (Model / Provider / View)
- **Dark Mode**: Full dual-theme support with Material 3
- **Accessibility**: Semantic labels, adequate touch targets

---

## 📄 License

MIT — Free to use in portfolio projects.
