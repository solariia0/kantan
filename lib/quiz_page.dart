import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'package:kana_kit/kana_kit.dart';

const kanaKit = KanaKit();

class QuizzPage extends StatefulWidget {
  const QuizzPage({super.key});

  @override
  State<QuizzPage> createState() => _QuizzPageState();
}

class _QuizzPageState extends State<QuizzPage> {
  // managing quiz state pages
  bool quizStarted = false;
  int currentQuiz = 0;
  List<Widget> quizContent = [
    Text('learn new'),
    Text('pracitce mistakes'),
    QuizArea(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //QuizArea(),
        quizContent[currentQuiz],
        if (!quizStarted)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    if (quizStarted == false) {
                      currentQuiz = 0;
                    }
                  });
                },
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      quizStarted = true;
                      currentQuiz = 2;
                    });
                  },
                  style: buttondeco,
                  child: Text('Learn'),
                ),
              ),
              MouseRegion(
                onEnter: (_) {
                  setState(() {
                    if (quizStarted == false) {
                      currentQuiz = 1;
                    }
                  });
                },
                child: OutlinedButton(
                  onPressed: () {},
                  style: buttondeco,
                  child: Text('Review'),
                ),
              ),
            ],
          ),
        if (!quizStarted)
          OutlinedButton(
            onPressed: () {},
            style: buttondeco,
            child: Text('switch to vocabulary'),
          ),
      ],
    );
  }
}

class QuizArea extends StatefulWidget {
  const QuizArea({super.key});

  @override
  State<QuizArea> createState() => _QuizAreaState();
}

class _QuizAreaState extends State<QuizArea> {
  final TextEditingController _controller = TextEditingController();
  bool _inputOn = true;
  List<Widget> questionBlock = [];

  int kanjiId = 0;
  int kanjiIndex = 0;

  String kanji = '';
  List<dynamic> kanjiRads = [];

  List<dynamic> qValue = [];
  List<dynamic> qAns = [];
  List<dynamic> kanjiListQuiz = [];

  //
  int stage = 0;
  List currentSet = [];
  List newKanji = [];
  List<int> newKanjiTracking = [];
  List knownKanji = [];
  List newVocab = [];

  Future<void> initializeKanji() async {
    newKanji = await getData('quiz/onyomi/1');
    print('onyomi success');
    print(newKanji);
    List<dynamic> onData = await getData('total/1');
    if (onData[0]['on_accuracy'] >= 70 && onData[0]['learned kanji'] >= 3) {
      try {
        knownKanji = await getData('quiz/kunyomi/1');
        print('kunyomi success');
      } catch (e) {
        if (e is TypeError) {
          if (e.toString().contains('null')) {
            newKanji.add(await getData('quiz/onyomi/1'));
            print('no kunyomi | to do added more new');
          }
        }
      }
    }
    // implement voacb
    //List<dynamic> newVocabData = await getData('quiz/new');

    updateQuiz();
  }
  // implement multiple question types

  void updateQuiz() {
    try {
      if (!mounted) return;
      setState(() {
        if (stage < 3) {
          currentSet = newKanji;
        } else if (stage < 6 && knownKanji.isNotEmpty) {
          currentSet = knownKanji;
        } else if (stage >= 7) {
          currentSet = newVocab;
        }
        kanji = currentSet[kanjiIndex]['literal'];
        kanjiRads = currentSet[kanjiIndex]['radicals'];
        qAns = currentSet[kanjiIndex]['onreadings'];
        qValue = currentSet[kanjiIndex]['meanings'];
        kanjiListQuiz = currentSet;
        kanjiId = currentSet[kanjiIndex]['id'];

        questionBlock = [
          Text(kanji, style: TextStyle(color: Colors.white, fontSize: 80)),
          Text(
            '$kanjiRads',
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
          Text(
            "Can you guess what the on'yomi reading is?",
            style: TextStyle(color: Colors.white),
          ),
        ];
      });
    } catch (e) {
      setState(() {
        kanji = "ERROR: $e";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initializeKanji();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.35,
      height: MediaQuery.of(context).size.height * 0.45,
      padding: EdgeInsets.all(5),
      decoration: itemdeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(children: questionBlock),
          if (!_inputOn)
            OutlinedButton(
              onPressed: () {
                updateQuiz();
                _inputOn = !_inputOn;
              },
              child: Text('next'),
            ),
          if (_inputOn)
            TextField(
              controller: _controller,
              onChanged: (text) {
                /* handle live conversion
              String converted = kanaKit.toHiragana(text);
              

              if (converted != text) {
                _controller.value = TextEditingValue(
                  text: converted,
                  selection: TextSelection.collapsed(offset: converted.length),
                );
              }*/
              },
              onSubmitted: (text) {
                Map postData = {"kanji_id": kanjiId, "correct": 0, "wrong": 0};

                String converted = kanaKit.toKatakana(text);
                setState(() {
                  _inputOn = !_inputOn;
                });
                if (qAns.contains(converted)) {
                  postData['correct'] = 1;
                  setState(() {
                    questionBlock[0] = Text(
                      converted,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 68, 185, 113),
                        fontSize: 80,
                      ),
                    );
                  });
                } else {
                  postData['wrong'] = 1;
                  setState(() {
                    questionBlock[0] = Text(
                      converted,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 192, 45, 65),
                        fontSize: 80,
                      ),
                    );

                    questionBlock[1] = Text(
                      '$qAns',
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    );

                    questionBlock[2] = Text(
                      '$qValue',
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    );
                  });
                }
                _controller.clear();

                sendData('user_kanji/1/onyomi', postData);
              },
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(boxoutline)),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Color(boxoutline)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/*
pressing learn starts a new quiz session
for each quiz
2 new kanji - 3 q's in a session 
  first is input onyomi guessing -> these will be the first two introduced at the start of a session
  alternative
3 kanji know the onyomi  - 4 q types, 2 kun , 2 meanigns, 1 input each
2 vocab 
*/