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
    // FirebaseFirestore.instance.collection('notes').add({
    //   'title': 'First Note',
    //   'content': 'This is my first Firestore note',
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
    FirebaseFirestore.instance.collection('notes').get().then((querySnapshot) {
      for (var doc in querySnapshot.docs) {
        print(doc.id); // document ID
        print(doc['title']); // data field
      }
    });

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
        onPressed: () => {},
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
  bool isPressed = false;
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
    final double spacing = 16;
    final crossAxisCount = 2;

    final itemWidth = (screenWidth - padding - spacing) / crossAxisCount;
    final itemHeight = 300;

    final childAspectRatio = itemWidth / itemHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return PressableGridItem(
            title: 'Widget ${index + 1}',
            description: 'bla bla bla',
          );
        },
      ),
    );
  }
}

class PressableGridItem extends StatefulWidget {
  final String title;
  final String description;

  const PressableGridItem({
    required this.title,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  State<PressableGridItem> createState() => _PressableGridItemState();
}

class _PressableGridItemState extends State<PressableGridItem> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => setState(() => isPressed = true),
            onTapUp: (_) => setState(() => isPressed = false),
            onTapCancel: () => setState(() => isPressed = false),
            onTap: () {
              Navigator.pushNamed(context, '/NotePage');
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isPressed ? Colors.grey[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: Text('Content here')),
            ),
          ),
        ),
        Center(child: Text(widget.description)),
      ],
    );
  }
}
