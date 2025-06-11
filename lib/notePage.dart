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
      body: DrawingTextFieldOverlay(
        descriptionController: descriptionController,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }
}

class DrawingTextFieldOverlay extends StatefulWidget {
  final TextEditingController descriptionController;
  final bool isDark;

  const DrawingTextFieldOverlay({
    super.key,
    required this.descriptionController,
    this.isDark = false,
  });

  @override
  State<DrawingTextFieldOverlay> createState() => _DrawingTextFieldOverlayState();
}

class _DrawingTextFieldOverlayState extends State<DrawingTextFieldOverlay> {
  final GlobalKey _paintKey = GlobalKey();
  final List<Offset?> points = [];
  final List<Offset?> tempPoints = [];
  bool isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // TextField Layer
        SizedBox.expand(
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: widget.descriptionController,
              decoration: const InputDecoration(border: InputBorder.none),
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
            onPanStart: (details) {
              final RenderBox box = _paintKey.currentContext?.findRenderObject() as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              setState(() {
                points.add(null);
                points.add(local);
              });
            },
            onPanUpdate: (details) {
              final RenderBox box = _paintKey.currentContext?.findRenderObject() as RenderBox;
              final local = box.globalToLocal(details.globalPosition);
              setState(() {
                points.add(local);
                tempPoints.clear();
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
            bottom: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              spacing: 12,
              children: [
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // change brush
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.palette),
                  onPressed: () {
                    // change brush
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: () {
                    setState(() {
                      if (points.isEmpty) return;

                      List<Offset?> removedStroke = [];

                      if (points.last == null) {
                        removedStroke.insert(0, points.removeLast());
                      }

                      while (points.isNotEmpty) {
                        final last = points.removeLast();
                        removedStroke.insert(0, last);
                        if (last == null) break;
                      }
                      tempPoints.addAll(removedStroke);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: () {
                    setState(() {
                      if (tempPoints.isEmpty) return;

                      List<Offset?> redoStroke = [];

                      if (tempPoints.last == null) {
                        redoStroke.insert(0, tempPoints.removeLast());
                      }

                      while (tempPoints.isNotEmpty) {
                        final last = tempPoints.removeLast();
                        redoStroke.insert(0, last);
                        if (last == null) break;
                      }
                      points.addAll(redoStroke);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      points.clear();
                    });
                  },
                ),
              ],
            ),
          ),

        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                isDrawing = !isDrawing;
              });
            },
            backgroundColor: widget.isDark ? Colors.black12 : Colors.grey[200],
            shape: const CircleBorder(),
            child: Icon(isDrawing ? Icons.text_fields : Icons.brush),
          ),
        ),
      ],
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