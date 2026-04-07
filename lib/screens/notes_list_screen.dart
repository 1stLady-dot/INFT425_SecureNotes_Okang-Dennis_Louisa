import 'package:flutter/material.dart';
import '../services/notes_service.dart';
import '../services/secure_storage_service.dart';
import 'add_edit_note_screen.dart';
import 'auth_screen.dart';  // ADDED: Required for logout navigation
import '../models/note.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final NotesService _notesService = NotesService();
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Auto-lock timer
  DateTime? _lastInteraction;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _resetAutoLockTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetAutoLockTimer();
  }

  void _resetAutoLockTimer() {
    _lastInteraction = DateTime.now();
    SecureStorageService.updateLastActivity();
  }

  Future<void> _loadNotes() async {
    await _notesService.loadNotes();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleInteraction() {
    _resetAutoLockTimer();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleInteraction,
      onPanDown: (_) => _handleInteraction(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Secure Notes'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchBar(),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildNoteList(),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNote,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildNoteList() {
    final notes = _searchQuery.isEmpty 
        ? _notesService.sortedNotes 
        : _notesService.searchNotes(_searchQuery);
    
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.note_add : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'No notes. Tap + to add.' 
                  : 'No notes matching "$_searchQuery"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // ListView.builder for virtualization (performance optimization)
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return NoteCard(
          key: ValueKey(note.id),
          note: note,
          onTap: () => _editNote(note),
          onLongPress: () => _showNoteOptions(note),
          onPinToggle: () => _togglePin(note),
        );
      },
    );
  }

  void _showSearchBar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search notes',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showNoteOptions(Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(note.isPinned ? 'Unpin Note' : 'Pin Note'),
              onTap: () {
                Navigator.pop(context);
                _togglePin(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Note', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteNote(note.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(Note note) async {
    await _notesService.togglePin(note.id);
    if (mounted) setState(() {});
  }

  Future<void> _addNote() async {
    _resetAutoLockTimer();
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const AddEditNoteScreen())
    );
    if (result == true) {
      await _loadNotes();
      if (mounted) setState(() {});
    }
  }

  Future<void> _editNote(Note note) async {
    _resetAutoLockTimer();
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => AddEditNoteScreen(note: note))
    );
    if (result == true) {
      await _loadNotes();
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteNote(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _notesService.deleteNote(id);
      await _loadNotes();
      if (mounted) setState(() {});
      _showSnackBar('Note deleted');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// Separate widget for performance optimization (const constructor where possible)
class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onPinToggle;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.onPinToggle,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(date.year, date.month, date.day);
    
    if (noteDate == today) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.isPinned) ...[
                const Icon(Icons.push_pin, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.content.length > 100 
                          ? '${note.content.substring(0, 100)}...' 
                          : note.content,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(note.lastEdited),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  size: 20,
                ),
                onPressed: onPinToggle,
                tooltip: note.isPinned ? 'Unpin' : 'Pin',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
     / /   U s i n g   L i s t V i e w . b u i l d e r   f o r   o p t i m a l   p e r f o r m a n c e   w i t h   l a r g e   n o t e   l i s t s  
 