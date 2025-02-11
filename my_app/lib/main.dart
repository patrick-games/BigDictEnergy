import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/game_screen.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/game_display.dart';
import 'controllers/game_controller.dart';
import 'services/word_service.dart';

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
    );
  }
}
