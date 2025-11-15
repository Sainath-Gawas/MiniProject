import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/note_model.dart';
import '/services/firestore_service.dart';

class NotesScreen extends StatefulWidget {
  final String semesterName;
  const NotesScreen({Key? key, required this.semesterName}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  void _openNoteDialog({Note? note}) {
    if (note != null) {
      _titleController.text = note.title;
      _contentController.text = note.content;
      _subjectController.text = note.subject;
    } else {
      _titleController.clear();
      _contentController.clear();
      _subjectController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          note == null ? "Add Note" : "Edit Note",
          style: const TextStyle(
            color: Color(0xFF283593),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Content",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: "Subject",
                  hintText: "Enter subject (e.g., Math, Physics, Custom)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF283593),
            ),
            onPressed: () async {
              final title = _titleController.text.trim();
              final content = _contentController.text.trim();
              final subject = _subjectController.text.trim().isEmpty
                  ? "Other"
                  : _subjectController.text.trim();

              if (title.isEmpty || content.isEmpty) return;

              final noteData = Note(
                id: note?.id,
                title: title,
                content: content,
                subject: subject,
                datetime: DateTime.now(),
              );

              if (note == null) {
                await _firestoreService.addNote(
                  uid,
                  widget.semesterName,
                  noteData,
                );
              } else {
                await _firestoreService.updateNote(
                  uid,
                  widget.semesterName,
                  noteData,
                );
              }

              if (mounted) Navigator.pop(context);
            },
            child: Text(note == null ? "Add" : "Update"),
          ),
        ],
      ),
    );
  }

  void _deleteNoteConfirmation(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Note"),
        content: const Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _firestoreService.deleteNote(
                uid,
                widget.semesterName,
                note.id!,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          note.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.content,
                style: const TextStyle(color: Color(0xFF616161)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                "${note.datetime.day}/${note.datetime.month}/${note.datetime.year}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _openNoteDialog(note: note);
            } else if (value == 'delete') {
              _deleteNoteConfirmation(note);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Notes"),
        backgroundColor: const Color(0xFF283593),
      ),
      body: StreamBuilder<List<Note>>(
        stream: _firestoreService.getNotes(uid, widget.semesterName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No notes yet.\nTap + to add one!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final notes = snapshot.data!;
          final Map<String, List<Note>> groupedNotes = {};

          for (var note in notes) {
            if (!groupedNotes.containsKey(note.subject)) {
              groupedNotes[note.subject] = [];
            }
            groupedNotes[note.subject]!.add(note);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: groupedNotes.entries.map((entry) {
              final subject = entry.key;
              final subjectNotes = entry.value;

              return ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF283593),
                  ),
                ),
                children: subjectNotes.map(_buildNoteCard).toList(),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF283593),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () => _openNoteDialog(),
      ),
    );
  }
}
