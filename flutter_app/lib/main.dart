import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile.dart';
import 'package:flutter_app/models/swipe.dart';
import 'package:flutter_app/screens/dev_login.dart';
import 'package:flutter_app/show_kit/screens/contestant_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/supabase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SwipeModel()),
        ChangeNotifierProvider(create: (context) => ProfileModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoggedIn = false;
  StreamSubscription<AuthState>? authSubscription;

  @override
  void initState() {
    super.initState();

    authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      setState(() {
        isLoggedIn = data.session != null;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    authSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return isLoggedIn ? const ContestantRouter() : const DevLogin();
  }
}
