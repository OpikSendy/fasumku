import 'package:fasumku/utils/page_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  await Supabase.initialize(
      url: "https://vjtecbqbcargjksiacjc.supabase.co",
      anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
          "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqdGVjYnFiY2FyZ2prc2lhY2pjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM5NjgxNjEsImV4cCI6MjA1OTU0NDE2MX0."
          "1GAF2uStw46OLzC6_UR8CMgo_1HngJsLYlxOJ61xmKk",
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fasumku',
      debugShowCheckedModeBanner: false,
      initialRoute: '/loading',
      onGenerateRoute: PageRouter.generateRoute,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}