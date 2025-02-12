import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to Play',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Aim of the game: Collectively find and enter all the words in the dictionary.\n\n'
              'Every minute between 6 and 15 letters are randomly generated. At least one vowel is included.\n\n'
              'You and anyone else playing will be seeing the exact same letters and timer.\n\n'
              'Enter as many words as you can find using the available letters.\n\n'
              'If a word has been entered in a previous round it won\'t be valid.\n\n'
              'You see a counter of the words you\'ve entered this round (60 seconds) and total this session.\n\n'
              'Below this you\'ll see words you and everyone else has entered in the current round.\n\n'
              'In the side menu you\'ll see a the Big Dict with all the words to find and which one has have been found already.\n\n'
              'Lets use our energgy to crack the Big Dict!',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
