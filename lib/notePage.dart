import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'main.dart';

Future<void> updateNote({
  required String docId,
  required String title,
  required String description,
  required List<Stroke> strokes,
}) async {
  final drawingData = strokes.map((s) => s.toMap()).toList();
  try {
    await FirebaseFirestore.instance
        .collection('notes')
        .doc(docId)
        .update({
      'title': title,
      'titleLower': title.toLowerCase(),
      'description': description,
      'content': drawingData,
      'timestamp': Timestamp.now(),
    });
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
  } catch (e) {
    print('Failed to delete document: $e');
  }
}

Future<List<Stroke>> loadDrawingData(String docId) async {
  final doc = await FirebaseFirestore.instance.collection('notes').doc(docId).get();
  final data = doc.data();
  if (data == null) return [];

  final content = data['content'] as List<dynamic>? ?? [];

  return content.map((strokeMap) => Stroke.fromMap(strokeMap)).toList();
}

class NotePage extends StatefulWidget {
  const NotePage({super.key});

  @override
  NotePageState createState() => NotePageState();
}

class NotePageState extends State<NotePage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late DrawingController drawingController;

  bool isDrawing = false;

  void toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  void initState() {
    super.initState();
    drawingController = DrawingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
      final docId = args['docId'] ?? '';
      final strokes = await loadDrawingData(docId);
      setState(() {
        drawingController.strokes = strokes;
      });
    });
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
            await updateNote(
              docId: id,
              title: titleController.text,
              description: descriptionController.text,
              strokes: drawingController.strokes,
            );
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
              await updateNote(
                  docId: id,
                  title: titleController.text,
                  description: descriptionController.text,
                  strokes: drawingController.strokes,
              );
            }, icon: Icon(Icons.save_outlined)),
          ),
        ],
      ),
      body: DrawingTextFieldOverlay(
        descriptionController: descriptionController,
        drawingController: drawingController,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }
}

class DrawingTextFieldOverlay extends StatefulWidget {
  final TextEditingController descriptionController;
  final DrawingController drawingController;
  final bool isDark;

  const DrawingTextFieldOverlay({
    super.key,
    required this.descriptionController,
    required this.drawingController,
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

  Color selectedColor = Colors.black;
  double brushSize = 3.0;

  List<Color> colors = [
    Colors.black,
    Colors.white,
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
                widget.drawingController.currentPoints = [local];
              });
            },
            onPanUpdate: (details) {
              final box = _paintKey.currentContext?.findRenderObject();
              if (box is! RenderBox) return;
              final local = box.globalToLocal(details.globalPosition);
              setState(() {
                widget.drawingController.addPoint(local);
              });
            },
            onPanEnd: (_) {
              setState(() {
                widget.drawingController.endStroke(selectedColor, brushSize);
              });
            },

            child: CustomPaint(
              key: _paintKey,
              painter: DrawingPainter(
                strokes: widget.drawingController.strokes,
                currentPoints: widget.drawingController.currentPoints,
                currentColor: selectedColor,
                currentStrokeWidth: brushSize,
              ),
              child: const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              ),
            )
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
                      widget.drawingController.undo();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: () {
                    setState(() {
                      widget.drawingController.redo();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      widget.drawingController.clear();
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
                      width: selectedColor == color ? 16 : 24,
                      height: selectedColor == color ? 16 : 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
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

  Map<String, dynamic> toMap() {
    return {
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  static Stroke fromMap(Map<String, dynamic> map) {
    return Stroke(
      points: (map['points'] as List)
          .map((p) => Offset(p['x'] * 1.0, p['y'] * 1.0))
          .toList(),
      color: Color(map['color']),
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
    );
  }
}

class DrawingController {
  List<Stroke> strokes = [];
  List<Stroke> redoStrokes = [];
  List<Offset> currentPoints = [];

  void addPoint(Offset point) {
    currentPoints.add(point);
  }

  void endStroke(Color color, double strokeWidth) {
    if (currentPoints.isNotEmpty) {
      strokes.add(Stroke(
        points: List.from(currentPoints),
        color: color,
        strokeWidth: strokeWidth,
      ));
      currentPoints.clear();
      redoStrokes.clear();
    }
  }

  void undo() {
    if (strokes.isNotEmpty) {
      redoStrokes.add(strokes.removeLast());
    }
  }

  void redo() {
    if (redoStrokes.isNotEmpty) {
      strokes.add(redoStrokes.removeLast());
    }
  }

  void clear() {
    strokes.clear();
    redoStrokes.clear();
    currentPoints.clear();
  }
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