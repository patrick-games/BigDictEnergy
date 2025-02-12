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
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final wordService = WordService();
  await wordService.initializeWords();
  final gameController = GameController(wordService);
  await gameController.startGame();

  runApp(MyApp(gameController: gameController));
}

class MyApp extends StatelessWidget {
  final GameController gameController;

  const MyApp({Key? key, required this.gameController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Game',
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
