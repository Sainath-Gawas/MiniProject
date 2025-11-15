import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String? id;
  final String title;
  final String content;
  final DateTime datetime;
  final String subject; // Subject or "Other"

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.datetime,
    required this.subject,
  });

  factory Note.fromMap(String id, Map<String, dynamic> data) {
    return Note(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      datetime: (data['datetime'] as Timestamp).toDate(),
      subject: data['subject'] ?? 'Other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'datetime': datetime,
      'subject': subject,
    };
  }
}
