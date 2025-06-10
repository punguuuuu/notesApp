import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notePage.dart';
import 'notes.dart';

final themeNotifier = ValueNotifier(ThemeMode.light);

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


class Application extends StatelessWidget {
  const Application({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData.light().copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[900],
              foregroundColor: Colors.white,
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const Home(),
            '/NotePage': (context) => const NotePage(),
          },
        );
      },
    );
  }
}