import 'package:flutter/material.dart';

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  NotePageState createState() => NotePageState();
}

class NotePageState extends State<NotePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_rounded),
        ),
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Title',
            hintStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.grey,
            ),
            border: InputBorder.none,
          ),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(border: InputBorder.none),
            style: TextStyle(fontSize: 20),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
        ),
      ),
    );
  }
}
