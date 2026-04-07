import 'package:flutter/material.dart';
import 'main.dart';

class KanjiPage extends StatefulWidget {
  const KanjiPage({super.key});

  @override
  State<KanjiPage> createState() => _KanjiPageState();
}

class _KanjiPageState extends State<KanjiPage> {
  int currentPage = 1;
  String mode = 'jlpt'; // fetch from user settings
  String level = '4'; // this too
  List<Widget> kanjiList = [];
  // make sidebar invisible when this page is loaded

  List<String> selectedKanji = [];
  void getKanjiList() async {
    try {
      List<dynamic> data = await getData('$mode/$level/$currentPage');
      if (data.isEmpty) {
        setState(() {
          kanjiList = [];
        });
        return;
      }

      List<Widget> newKanjiList = [];
      for (var item in data) {
        String kanji = item['literal'];
        newKanjiList.add(
          KanjiHolder(
            text: kanji,
            onSelected: (kanji, selected) {
              setState(() {
                if (selected) {
                  selectedKanji.add(kanji);
                } else {
                  selectedKanji.remove(kanji);
                }
              });
            },
          ),
        );
      }
      setState(() {
        kanjiList = newKanjiList;
      });
    } catch (e) {
      setState(() {
        String error = 'Error fetching Kanji data: $e';
        kanjiList = [
          KanjiHolder(text: error, onSelected: (kanji, selected) {}),
        ];
      });
    }
  }

  void sendKanji() async {
    String urlQuery = 'kanji_id?';
    for (var kanji in selectedKanji) {
      urlQuery += 'kanji=$kanji&';
      if (kanji == selectedKanji.last) {
        urlQuery += 'kanji=$kanji';
      }
    }
    List<dynamic> idListdb = await getData(urlQuery);
    // /kanji_id?kanji=日&kanji=月&kanji=火
    List<int> idList = [];
    for (var item in idListdb) {
      idList.add(item['id']);
    }

    String postPath = 'user_kanji/1/';
    for (var kanji in selectedKanji) {
      urlQuery += 'kanji=$kanji&';
      if (kanji == selectedKanji.last) {
        urlQuery += 'kanji=$kanji';
      }
    }

    // add try catch
    sendData(postPath, {'id': idList});
  }

  @override
  void initState() {
    super.initState();
    getKanjiList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          '${mode.toUpperCase()} - $level',
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
        Row(
          // reset selection if these are pressed
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => {
                setState(() {
                  mode = 'grade';
                  getKanjiList();
                }),
              },
              style: buttondeco,
              child: Text('Grade (Joyo)'),
            ),
            OutlinedButton(
              onPressed: () => {
                setState(() {
                  mode = 'jlpt';
                  getKanjiList();
                }),
              },
              style: buttondeco,
              child: Text('JLPT'),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => {
                setState(() {
                  level = '1';
                  getKanjiList();
                }),
              },
              style: buttondeco,
              child: Text('1'),
            ),
            OutlinedButton(
              onPressed: () => {
                setState(() {
                  level = '2';
                  getKanjiList();
                }),
              },
              style: buttondeco,
              child: Text('2'),
            ),
            OutlinedButton(
              onPressed: () => {
                setState(() {
                  level = '3';
                  getKanjiList();
                }),
              },
              style: buttondeco,
              child: Text('3'),
            ),
            OutlinedButton(
              onPressed: () => {
                setState(() {
                  level = '4';
                  getKanjiList();
                }),
              },
              style: buttondeco,
              child: Text('4'),
            ),
            OutlinedButton(
              onPressed: () => {
                setState(() {
                  level = '5';
                  getKanjiList();
                }),
              },
              style: buttondeco,
              child: Text('5'),
            ),
            OutlinedButton(
              onPressed: () {
                sendKanji();
              },
              style: buttondeco,
              child: Text('Add to known kanji'),
            ),
          ],
        ),
        Wrap(spacing: 10, runSpacing: 10, children: kanjiList),
      ],
    );
  }
}

// widgets
class KanjiHolder extends StatefulWidget {
  final String text;
  final Function(String, bool) onSelected;
  const KanjiHolder({super.key, required this.text, required this.onSelected});

  @override
  State<KanjiHolder> createState() => _KanjiHolderState();
}

class _KanjiHolderState extends State<KanjiHolder> {
  bool selected = false;
  // if known give it a different look

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selected = !selected;
          widget.onSelected(widget.text, selected);
        });
      },
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: selected ? selecteditemdeco : itemdeco,
        child: Text(
          widget.text,
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      ),
    );
  }
}
