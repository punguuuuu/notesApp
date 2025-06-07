import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'notePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await signIn('thungxeng@gmail.com', 'tttttt');
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    print("User is signed in: ${user.uid}");
  } else {
    print("No user signed in");
  }

  runApp(const Application());
}

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

class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black12),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/NotePage': (context) => const NotePage(),
      },
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      body: const HomeBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final docRef = FirebaseFirestore.instance.collection('notes').doc();
          Navigator.pushNamed(context, '/NotePage', arguments: {
            'docId': docRef.id,
          });
          docRef.set({
            'title': '',
            'description': '',
            'timestamp': FieldValue.serverTimestamp(),
          });
        },
        backgroundColor: Colors.grey[200],
        shape: const CircleBorder(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Padding(
        padding: EdgeInsets.only(left: 16),
        child: Text('Folders'),
      ),
      backgroundColor: Colors.white,
      actions: [
        IconButton(onPressed: () => {}, icon: Icon(Icons.dark_mode_outlined)),
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: IconButton(onPressed: () => {}, icon: Icon(Icons.search)),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  HomeBodyState createState() => HomeBodyState();
}

class HomeBodyState extends State<HomeBody> {
  static final Color containerColor = Colors.grey[300]!;
  static const double containerHeight = 200;

  List<Widget> listOfWidgets = [
    Container(
      color: containerColor,
      height: containerHeight,
      child: Center(child: Text('Widget 1')),
    ),
  ];

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
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .orderBy('timestamp', descending: true)
            .snapshots(),
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


class PressableGridItem extends StatelessWidget {
  final DocumentSnapshot doc;
  const PressableGridItem({required this.doc, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                'description': description,
                'docId': doc.id,
              });
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(description, textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ),
        Center(child: Text(date)),
      ],
    );
  }
}