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

  bool isDrawing = false;
  bool isChangingColor = false;
  bool isChangingSize = false;

  List<Stroke> strokes = [];
  List<Stroke> redoStrokes = [];
  List<Offset> currentPoints = [];

  Color selectedColor = Colors.black;
  double brushSize = 3.0;

  List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
  ];

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
              final box = _paintKey.currentContext?.findRenderObject();
              if (box is! RenderBox) return;

              final local = box.globalToLocal(details.globalPosition);
              setState(() {
                currentPoints = [local];
              });
            },
            onPanUpdate: (details) {
              final context = _paintKey.currentContext;
              if (context == null) return;
              final renderObject = context.findRenderObject();
              if (renderObject is! RenderBox) return;

              final local = renderObject.globalToLocal(details.globalPosition);
              setState(() {
                currentPoints.add(local);
              });
            },
            onPanEnd: (_) {
              if (currentPoints.isEmpty) return;
              setState(() {
                strokes.add(Stroke(
                  points: List.from(currentPoints),
                  color: selectedColor,
                  strokeWidth: brushSize,
                ));
                currentPoints.clear();
                redoStrokes.clear();
              });
            },
            child: CustomPaint(
              key: _paintKey,
              painter: DrawingPainter(
                strokes: strokes,
                currentPoints: currentPoints,
                currentColor: selectedColor,
                currentStrokeWidth: brushSize,
              ),
              child: SizedBox.expand(
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),

        if (isDrawing)
          Positioned(
            bottom: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              spacing: 12,
              children: [
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      isChangingSize = !isChangingSize;
                      isChangingColor = false;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.palette),
                  onPressed: () {
                    setState(() {
                      isChangingColor = !isChangingColor;
                      isChangingSize = false;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: () {
                    setState(() {
                      if (strokes.isNotEmpty) {
                        setState(() {
                          redoStrokes.add(strokes.removeLast());
                        });
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: () {
                    if (redoStrokes.isNotEmpty) {
                      setState(() {
                        strokes.add(redoStrokes.removeLast());
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      currentPoints.clear();
                      strokes.clear();
                      redoStrokes.clear();
                    });
                  },
                ),
              ],
            ),
          ),

        Positioned(
          bottom: 30,
          right: 24,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                isDrawing = !isDrawing;
                isChangingColor = false;
                isChangingSize = false;
              });
            },
            backgroundColor: widget.isDark ? Colors.black12 : Colors.grey[200],
            shape: const CircleBorder(),
            child: Icon(isDrawing ? Icons.text_fields : Icons.brush),
          ),
        ),

      if (isChangingSize)
        Positioned(
          bottom: 90,
          left: 20,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Width:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Slider(
                    min: 1.0,
                    max: 20.0,
                    value: brushSize,
                    label: brushSize.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        brushSize = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isChangingColor)
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                spacing: 20,
                children: colors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  Stroke({required this.points, required this.color, required this.strokeWidth});
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;

  DrawingPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    if (currentPoints.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}