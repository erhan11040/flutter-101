import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final _saved = <WordPair>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
              onPressed: () => {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (BuildContext context) {
                      final tiles = _saved.map(
                        (WordPair pair) {
                          return ListTile(
                            title: Text(
                              pair.asPascalCase,
                              style: _biggerFont,
                            ),
                          );
                        },
                      );
                      final divided = tiles.isNotEmpty
                          ? ListTile.divideTiles(context: context, tiles: tiles)
                              .toList()
                          : <Widget>[];
                      return Scaffold(
                        appBar: AppBar(
                          title: Text('Saved Suggestions'),
                        ),
                        body: ListView(children: divided),
                      );
                    })),
                  },
              icon: Icon(Icons.list))
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemBuilder: (context, i) {
          if (i.isOdd) return const Divider();

          final index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        setState(() => {
              alreadySaved ? _deleteFromFireStore(pair) : _saveToFireStore(pair)
            });
      },
    );
  }

  void _saveToFireStore(WordPair pair) {
    _saved.add(pair);
    FirebaseFirestore.instance.collection('testText').add({
      'title': pair.asLowerCase,
    }).then((value) => {
          _showToast(context, pair.asLowerCase + " is added to your favorites")
        });
  }

  void _deleteFromFireStore(WordPair pair) {
    _saved.remove(pair);
    FirebaseFirestore.instance
        .collection('testText')
        .where('title', isEqualTo: pair.asLowerCase)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.length > 0) {
        var id = querySnapshot.docs.first.id;
        FirebaseFirestore.instance.collection('testText').doc(id).delete().then(
            (value) => {
                  _showToast(context,
                      pair.asLowerCase + " is removed from your favorites")
                });
      }
    });
  }

  void _showToast(BuildContext context, String text) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
            label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}
