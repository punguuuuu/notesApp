import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> updateNote({
  required String docId,
  required String title,
  required String description,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(docId)
        .update({
      'title': title,
      'description': description,
      'timestamp': Timestamp.now(),
    });
    print('Document updated successfully');
  } catch (e) {
    print('Failed to update document: $e');
  }
}

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  NotePageState createState() => NotePageState();
}

class NotePageState extends State<NotePage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String title = args['title'] ?? '';
    final String description = args['description'] ?? '';

    titleController = TextEditingController(text: title);
    descriptionController = TextEditingController(text: description);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String id = args['docId'];
    const placeHolder = 'Title';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            await updateNote(docId: id, title: titleController.text, description: descriptionController.text);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            hintText: placeHolder,
            border: InputBorder.none,
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(onPressed: () => {}, icon: Icon(Icons.dark_mode_outlined)),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: IconButton(onPressed: () async {
              await updateNote(docId: id, title: titleController.text, description: descriptionController.text);
            }, icon: Icon(Icons.save_outlined)),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 20),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ),
    );
  }
}
