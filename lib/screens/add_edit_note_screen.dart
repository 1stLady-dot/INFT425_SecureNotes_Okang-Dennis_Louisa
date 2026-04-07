import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/notes_service.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;
  
  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final NotesService _notesService = NotesService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    print('=== AddEditNoteScreen INITIALIZED ===');
    if (widget.note != null) {
      print('Editing existing note: ${widget.note!.id}');
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
    } else {
      print('Creating NEW note');
    }
  }

  Future<void> _saveNote() async {
    print('=== SAVE BUTTON PRESSED ===');
    print('Title: "${_titleController.text.trim()}"');
    print('Content: "${_contentController.text.trim()}"');
    
    // Simple validation
    if (_titleController.text.trim().isEmpty) {
      print('ERROR: Title is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    
    if (_contentController.text.trim().isEmpty) {
      print('ERROR: Content is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter content')),
      );
      return;
    }
    
    print('Validation passed!');
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (widget.note == null) {
        // Create new note
        print('Creating new note...');
        final newId = _notesService.generateId();
        print('Generated ID: $newId');
        
        final newNote = Note(
          id: newId,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          lastEdited: DateTime.now(),
          isPinned: false,
        );
        
        await _notesService.addNote(newNote);
        print('SUCCESS: Note added to service');
      } else {
        // Update existing note
        print('Updating existing note...');
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          lastEdited: DateTime.now(),
        );
        
        await _notesService.updateNote(updatedNote);
        print('SUCCESS: Note updated');
      }
      
      if (mounted) {
        print('Returning to notes list with success=true');
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('ERROR CAUGHT: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveNote,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter note title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Enter note content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('AddEditNoteScreen DISPOSED');
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}