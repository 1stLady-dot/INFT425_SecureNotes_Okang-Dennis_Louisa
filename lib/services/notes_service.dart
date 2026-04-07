import 'dart:convert';
import 'dart:math';
import '../models/note.dart';
import '../utils/encryption_helper.dart';
import 'secure_storage_service.dart';

class NotesService {
  List<Note> _notes = [];
  
  List<Note> get notes => _notes;
  
  // Pinned notes appear first
  List<Note> get sortedNotes {
    final pinned = _notes.where((n) => n.isPinned).toList();
    final unpinned = _notes.where((n) => !n.isPinned).toList();
    pinned.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
    unpinned.sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
    return [...pinned, ...unpinned];
  }

  Future<void> loadNotes() async {
    final encryptedJson = await SecureStorageService.loadNotes();
    if (encryptedJson == null) {
      _notes = [];
      return;
    }
    try {
      final decryptedJson = EncryptionHelper.decrypt(encryptedJson);
      final List<dynamic> decoded = jsonDecode(decryptedJson);
      _notes = decoded.map((item) => Note.fromJson(item)).toList();
    } catch (e) {
      _notes = [];
    }
  }

  Future<void> _saveNotes() async {
    final jsonString = jsonEncode(_notes.map((n) => n.toJson()).toList());
    final encrypted = EncryptionHelper.encrypt(jsonString);
    await SecureStorageService.saveNotes(encrypted);
  }

  Future<void> addNote(Note note) async {
    _notes.insert(0, note);
    await _saveNotes();
  }

  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      await _saveNotes();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveNotes();
  }

  Future<void> togglePin(String id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notes[index].isPinned = !_notes[index].isPinned;
      await _saveNotes();
    }
  }

  // Search functionality
  List<Note> searchNotes(String query) {
    if (query.isEmpty) return sortedNotes;
    final lowercaseQuery = query.toLowerCase();
    return sortedNotes.where((note) =>
      note.title.toLowerCase().contains(lowercaseQuery) ||
      note.content.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(10000).toString();
  }
}