import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/game_screen.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/game_display.dart';
import 'controllers/game_controller.dart';
import 'services/word_service.dart';
import 'package:my_app/screens/how_to_play_screen.dart';
import 'package:my_app/screens/dictionary_screen.dart';
import 'package:my_app/screens/about_screen.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first and wait for it to complete
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
    // Show error UI instead of crashing
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Failed to initialize app. Please try again later.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ));
    return;
  }

  // Create services only after Firebase is initialized
  final wordService = WordService();
  final gameController = GameController(wordService);

  // Show the app immediately with loading state
  runApp(MyApp(gameController: gameController));

  try {
    // Initialize remaining services
    await wordService.initializeWords();
    await gameController.initialize();
    print("All initialization complete");
  } catch (e) {
    print("Error during initialization: $e");
    // The app will show the loading state if there's an error
  }
}

class MyApp extends StatelessWidget {
  final GameController gameController;

  const MyApp({Key? key, required this.gameController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Big Dict Energy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameDisplay(
        gameState: gameController.gameState,
        onSubmitWord: gameController.submitWord,
        onResetGame: gameController.resetGame,
      ),
      routes: {
        '/how-to-play': (context) => const HowToPlayScreen(),
        '/dictionary': (context) => const DictionaryScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
