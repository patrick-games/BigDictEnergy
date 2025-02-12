import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({Key? key}) : super(key: key);

  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  Map<String, List<String>> wordsByLetter = {};
  Set<String> completedWords = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDictionary();
    _loadCompletedWords();
  }

  Future<void> _loadDictionary() async {
    try {
      // Load dictionary
      String jsonString = await rootBundle.loadString('assets/word_list.json');
      Map<String, dynamic> jsonData = json.decode(jsonString);

      // Group words by first letter
      for (String word in jsonData.keys) {
        String firstLetter = word[0].toUpperCase();
        wordsByLetter.putIfAbsent(firstLetter, () => []);
        wordsByLetter[firstLetter]!.add(word.toUpperCase());
      }

      // Sort each list
      wordsByLetter.forEach((key, value) {
        value.sort();
      });

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading dictionary: $e");
    }
  }

  Future<void> _loadCompletedWords() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('completedWords').get();

      setState(() {
        completedWords = snapshot.docs
            .map((doc) => doc.get('word').toString().toUpperCase())
            .toSet();
      });
    } catch (e) {
      print("Error loading completed words: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: wordsByLetter.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('The Big Dict'),
          bottom: TabBar(
            isScrollable: true,
            tabs: wordsByLetter.keys
                .toList()
                .map((letter) => Tab(text: letter))
                .toList(),
          ),
        ),
        body: TabBarView(
          children: wordsByLetter.keys.map((letter) {
            return ListView.builder(
              itemCount: wordsByLetter[letter]!.length,
              itemBuilder: (context, index) {
                String word = wordsByLetter[letter]![index];
                bool isFound = completedWords.contains(word);

                return Container(
                  color: isFound ? Colors.green.withOpacity(0.2) : null,
                  child: ListTile(
                    title: Text(word),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
