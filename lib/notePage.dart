import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';

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
      'titleLower': title.toLowerCase(),
      'description': description,
      'timestamp': Timestamp.now(),
    });
    print('Document updated successfully');
  } catch (e) {
    print('Failed to update document: $e');
  }
}

Future<void> deleteNote({
  required String docId,
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(docId)
        .delete();
    print('Document deleted successfully');
  } catch (e) {
    print('Failed to delete document: $e');
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

  bool isDrawing = false;
  final GlobalKey _paintKey = GlobalKey();
  final List<Offset?> points = [];

  void toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final String id = args['docId'] ?? '';
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
          IconButton(onPressed: () => {
            toggleTheme()
          }, icon: Icon(isDark ? Icons.dark_mode : Icons.dark_mode_outlined)),
          IconButton(onPressed: () async {
            await deleteNote(docId: id);
            Navigator.pop(context);
          }, icon: Icon(Icons.delete_outline)),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: IconButton(onPressed: () async {
              await updateNote(docId: id, title: titleController.text, description: descriptionController.text);
            }, icon: Icon(Icons.save_outlined)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isDrawing = !isDrawing;
          });
        },
        backgroundColor: isDark ? Colors.black12 : Colors.grey[200],
        shape: const CircleBorder(),
        child: Icon(isDrawing ? Icons.text_fields : Icons.brush),
      ),
      body: Stack(
        children: [
          // TextField Layer
          SizedBox.expand(
            child: Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
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

          // Drawing Layer
          IgnorePointer(
            ignoring: !isDrawing,
            child: GestureDetector(
              onPanUpdate: (details) {
                final box = _paintKey.currentContext?.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.globalPosition);
                setState(() {
                  points.add(local);
                });
              },
              onPanEnd: (_) => setState(() => points.add(null)),
              child: CustomPaint(
                key: _paintKey,
                painter: DrawingPainter(List.from(points)),
                child: SizedBox.expand(
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          if (isDrawing)
            Positioned(
              bottom: 100,
              right: 21,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      // change brush
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.palette),
                    onPressed: () {
                      // change brush
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.redo),
                    onPressed: () {
                      // change brush
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.undo),
                    onPressed: () {
                      // change color
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      setState(() {
                        points.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}