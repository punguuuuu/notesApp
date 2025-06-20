import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'main.dart';
import 'notePage.dart';

Future<UserCredential> signIn(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("Signed in: ${userCredential.user?.uid}");
    return userCredential;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided.');
    }
    rethrow;
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  String searchText = "";

  void updateSearchText(String newText) {
    setState(() {
      searchText = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBarWidget(onSearchChanged: updateSearchText),
      body: HomeBody(searchText: searchText),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final docRef = FirebaseFirestore.instance.collection('notes').doc();
          Navigator.pushNamed(context, '/NotePage', arguments: {
            'docId': docRef.id,
          });
          docRef.set({
            'title': '',
            'titleLower': '',
            'description': '',
            'timestamp': FieldValue.serverTimestamp(),
          });
        },
        backgroundColor: isDark ? Colors.black12 : Colors.grey[200],
        shape: const CircleBorder(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final Function(String) onSearchChanged;

  const AppBarWidget({Key? key, required this.onSearchChanged}) : super(key: key);

  @override
  AppBarWidgetState createState() => AppBarWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 80);
}

class AppBarWidgetState extends State<AppBarWidget> {
  TextEditingController _searchController = TextEditingController();
  String searchText = "";
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void performSearch(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(value);
    });
  }

  void toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Padding(
        padding: EdgeInsets.only(top: 30, left: 16),
        child: Text('Folders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),),
      ),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      actions: [
        Padding(
          padding: EdgeInsets.only(top: 20, right: 16),
          child: IconButton(onPressed: () => {
            toggleTheme()
          }, icon: Icon(isDark ? Icons.dark_mode : Icons.dark_mode_outlined)),
        ),
      ],
    bottom: PreferredSize(
      preferredSize: Size.fromHeight(56.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search here',
            prefixIcon: GestureDetector(
              onTap: () => performSearch(_searchController.text),
              child: const Icon(Icons.search),
            ),
            filled: true,
            fillColor: isDark ? Colors.black12 : Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30.0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: performSearch
        ),
        ),
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  final String searchText;
  const HomeBody({super.key, required this.searchText});

  @override
  HomeBodyState createState() => HomeBodyState();
}

class HomeBodyState extends State<HomeBody> {
  static final Color containerColor = Colors.grey[300]!;
  static const double containerHeight = 200;

  Stream<QuerySnapshot> getNotesStream() {
    final collection = FirebaseFirestore.instance.collection('notes');

    if (widget.searchText.isNotEmpty) {
      return collection
          .where('titleLower', isGreaterThanOrEqualTo: widget.searchText.toLowerCase())
          .where('titleLower', isLessThanOrEqualTo: '${widget.searchText.toLowerCase()}\uf8ff')
          .snapshots();
    } else {
      return collection.orderBy('timestamp', descending: true).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16 * 2;
    const double spacing = 16;
    const crossAxisCount = 2;

    final itemWidth = (screenWidth - padding - spacing) / crossAxisCount;
    const itemHeight = 300;
    final childAspectRatio = itemWidth / itemHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notes found.'));
          }

          final notes = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final doc = notes[index];
              return PressableGridItem(doc: doc);
            },
          );
        },
      ),
    );
  }
}

List<Stroke> parseStrokes(dynamic data) {
  if (data == null) return [];

  return (data as List).map((stroke) {
    final points = (stroke['points'] as List).map((p) {
      return Offset(p['dx'] * 1.0, p['dy'] * 1.0);
    }).toList();

    return Stroke(
      points: points,
      color: Color(int.parse(stroke['color'].substring(1, 7), radix: 16) + 0xFF000000),
      strokeWidth: (stroke['width'] as num).toDouble(),
    );
  }).toList();
}

class PressableGridItem extends StatelessWidget {
  final DocumentSnapshot doc;
  const PressableGridItem({required this.doc, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rawTitle = doc['title'] as String? ?? '';
    final title = rawTitle.trim().isEmpty ? 'Untitled' : rawTitle;

    final description = doc['description'] ?? '';
    final timestamp = doc['timestamp'] as Timestamp?;
    final dt = timestamp?.toDate() ?? DateTime.now();
    final date = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await deleteNote(docId: doc.id);
                },
                child: const Icon(Icons.delete_outline, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/NotePage', arguments: {
                'title': title,
                'titleLower': title.toLowerCase(),
                'description': description,
                'docId': doc.id,
              });
            },
            child: FutureBuilder<List<Stroke>>(
              future: loadDrawingData(doc.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }

                final strokes = snapshot.data ?? [];

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Drawing
                      Positioned.fill(
                        child: CustomPaint(
                          painter: DrawingPainter(strokes: strokes),
                        ),
                      ),
                      // Description text
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(description),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Center(child: Text(date)),
      ],
    );
  }
}