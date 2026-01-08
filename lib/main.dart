import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/livestream_provider.dart';
import 'views/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("FIREBASE: Initialized successfully with options");
  } catch (e) {
    print("FIREBASE ERROR: $e");
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LivestreamProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TikTok Livestream Clone',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.pink,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
