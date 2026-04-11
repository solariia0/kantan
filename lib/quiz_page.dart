import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';
import 'package:kana_kit/kana_kit.dart';

const kanaKit = KanaKit();
var random = Random();

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
    Text('practice page'),
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
        if (quizStarted)
        quizContent[currentQuiz],
        if (!quizStarted)
          Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.35,
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: itemdeco,
                child: Center(child: quizContent[currentQuiz]),
              ),
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
                    child: Container(
                      margin: EdgeInsets.all(5),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            quizStarted = true;
                            currentQuiz = 2;
                          });
                        },
                        child: Text('Learn'),
                      ),
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
                    child: Container(
                      margin: EdgeInsets.all(5),
                      child: OutlinedButton(
                        onPressed: () {
                          currentQuiz = 3;
                          quizStarted = true;
                        },
                        child: Text('Review'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        if (!quizStarted)
          OutlinedButton(onPressed: () {}, child: Text('switch to vocabulary')),
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
  int kanjiId = 0;
  int kanjiIndex = 0;

  String kanji = '';
  List<dynamic> kanjiRads = [];
  List<dynamic> kun = [];
  List<dynamic> on = [];
  List<dynamic> meaning = [];

  List<dynamic> kanjiListQuiz = [];

  //
  int stage = 0;
  List currentSet = [];
  List allKanji = [];

  List newKanji = [];
  List knownKanji = [];
  List newVocab = [];

  List<int> newTracking = [];
  List<int> knownTracking = [];
  List<int> vocabTracking = [];

  Future<void> initializeKanji() async {
    newKanji = await getData('quiz/onyomi/1');
    for (var item in newKanji) {
      newTracking.add(0);
    }
    allKanji = newKanji;
    List<dynamic> onData = await getData('total/1');
    if (onData[0]['on_accuracy'] >= 70 && onData[0]['learned kanji'] >= 3) {
      try {
        knownKanji = await getData('quiz/kunyomi/1');
        allKanji.add(knownKanji[0]);
        for (var item in knownKanji) {
          knownTracking.add(0);
        }
      } catch (e) {
        if (e is TypeError) {
          if (e.toString().contains('null')) {
            List<dynamic> moreKanji = await getData('quiz/onyomi/1');
            newKanji.add(moreKanji[0]);
            allKanji.add(moreKanji[0]);
            for (var item in newKanji) {
              newTracking.add(0);
            }
          }
        }
      }
    }
    // implement voacb
    //List<dynamic> newVocabData = await getData('quiz/new');
    //allKanji[0].add(newVocabData[0]);
    // for (var item in vocabKanji) {vocabTracking.add(0);}

    updateQuiz();
  }

  // implement multiple question types
  int trackingType = 0; // new, kun, vocab
  int qType = 0; // input, mcq, dragndrop
  List<dynamic> qAns = [];
  List<dynamic> qValue = [];

  void updateQuiz() {
    try {
      if (!mounted) return;
      setState(() {
        // setting quiz stage
        if (stage <= 2) {
          currentSet = newKanji;
          trackingType = 0;
          print('newkanji');
        } else if (stage <= 5) {
          currentSet = newKanji;
          trackingType = 0;
          print('newkanji');
          if (knownKanji.isNotEmpty) {
            currentSet = knownKanji;
            trackingType = 1;
            print('known kanji');
          }
        } else if (stage >= 7) {
          currentSet = newVocab;
          trackingType = 2;
          print('vocab');
        }

        // define kanji values
        kanji = currentSet[kanjiIndex]['literal'];
        kanjiRads = currentSet[kanjiIndex]['radicals'];
        kun = currentSet[kanjiIndex]['kunreadings'];
        on = currentSet[kanjiIndex]['onreadings'];
        meaning = currentSet[kanjiIndex]['meanings'];
        kanjiListQuiz = currentSet;
        kanjiId = currentSet[kanjiIndex]['id'];

        mainText = kanji;
        subText = '$kanjiRads';
        hintText = "can you guess what the on'yomi reading is?";

        setQuestion();
        ansColor = Colors.white;
      });
    } catch (e) {
      setState(() {
        kanji = "ERROR: $e";
      });
    }
  }

  void setQuestion() {
    print(allKanji);
    List tracking = [newTracking, knownTracking, vocabTracking];
    List values = [kun, on, meaning];
    if (tracking[trackingType][kanjiIndex] == 0) {
      qType = 0;
      qAns = on;
      qValue = values[2];
    } else {
      qType = Random().nextInt(2) + 1;
      int ans = Random().nextInt(2);
      int value = Random().nextInt(2);
      while (ans == value) {
        value = Random().nextInt(2);
      }
      qAns = values[ans];
      qValue = values[value];
    }
  }

  Color ansColor = Colors.white;
  bool answered = false;
  String answer = '';
  bool correct = false;
  String mainText = '';
  String subText = '';
  String hintText = '';

  void inputCheck(String text) {
    Map postData = {"kanji_id": kanjiId, "correct": 0, "wrong": 0};

    String converted = kanaKit.toKatakana(text);
    answered = true;
    answer = converted;

    if (qAns.contains(converted)) {
      postData['correct'] = 1;
      correct = true;
      setState(() {
        ansColor = Color.fromARGB(255, 68, 185, 113);
        subText = '$meaning';
        hintText = '';
      });
    } else {
      postData['wrong'] = 1;
      setState(() {
        ansColor = Color.fromARGB(255, 192, 45, 65);
        correct = false;
        subText = '$qAns';
        hintText = '$meaning';
      });
      sendData('user_kanji/1/onyomi', postData);
    }
  }

  void next() {
    kanjiIndex++;
    // stage
    updateQuiz();
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
          Column(
            children: [
              if (qType == 0) /*
                InputQuestion(
                  kanji: kanji,
                  kanjiRads: kanjiRads,
                  kun: kun,
                  on: on,
                  meaning: meaning,
                  kanjiListQuiz: kanjiListQuiz,
                  kanjiId: kanjiId,
                  qAns: qAns,
                  qValue: qValue,
                  onSubmit: (text) {
                    inputCheck(text);
                  },
                  ansColor: ansColor,
                  answer: answer,
                  answered: answered,
                  correct: correct,
                  mainText: mainText,
                  subText: subText,
                  hintText: hintText,
                  next: () {
                    next();
                  },
                ),*/
                McqDragnDrop(
                  meaningHidden: true,
                  readingHidden: true,
                  allKanji: allKanji,
                  kanji: kanji,
                  kanjiRads: kanjiRads,
                  kun: kun,
                  on: on,
                  meaning: meaning,
                  kanjiId: kanjiId,
                  qAns: qAns,
                  qValue: qValue,
                ),
              if (qType == 1)
                Mcq(
                  allKanji: allKanji,
                  kanji: kanji,
                  kanjiRads: kanjiRads,
                  kun: kun,
                  on: on,
                  meaning: meaning,
                  kanjiId: kanjiId,
                  qAns: qAns,
                  qValue: qValue,
                ),
              if (qType == 2)
                //McqDragnDrop(meaningHidden: false, readingHidden: true),
                McqDragnDrop(
                  meaningHidden: true,
                  readingHidden: true,
                  allKanji: allKanji,
                  kanji: kanji,
                  kanjiRads: kanjiRads,
                  kun: kun,
                  on: on,
                  meaning: meaning,
                  kanjiId: kanjiId,
                  qAns: qAns,
                  qValue: qValue,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class InputQuestion extends StatefulWidget {
  final String kanji;
  final List<dynamic> kanjiRads;
  final List<dynamic> kun;
  final List<dynamic> on;
  final List<dynamic> meaning;
  final int kanjiId;
  final List<dynamic> qAns;
  final List<dynamic> qValue;
  final Function(String) onSubmit;
  bool answered;
  Color ansColor;
  String answer;
  bool correct;
  String mainText;
  String subText;
  String hintText;
  final Function() next;

  final List<dynamic> kanjiListQuiz;
  InputQuestion({
    super.key,
    required this.kanji,
    required this.kanjiRads,
    required this.kun,
    required this.on,
    required this.meaning,
    required this.kanjiListQuiz,
    required this.kanjiId,
    required this.qAns,
    required this.qValue,
    required this.onSubmit,
    required this.answered,
    required this.answer,
    required this.ansColor,
    required this.correct,
    required this.mainText,
    required this.subText,
    required this.hintText,
    required this.next,
  });

  @override
  State<InputQuestion> createState() => _InputQuestionState();
}

class _InputQuestionState extends State<InputQuestion> {
  final TextEditingController _controller = TextEditingController();
  bool _inputOn = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          widget.mainText,
          style: TextStyle(
            color: widget.answered ? widget.ansColor : Colors.white,
            fontSize: 80,
          ),
        ),
        Text(widget.subText, style: TextStyle(fontSize: 30)),
        Text(widget.hintText),
        if (!_inputOn)
          OutlinedButton(
            onPressed: () {
              widget.next();
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
              widget.onSubmit(text);
              setState(() {
                _inputOn = !_inputOn;
              });
              _controller.clear();
            },
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
    );
  }
}

class Mcq extends StatefulWidget {
  final String kanji;
  final List<dynamic> kanjiRads;
  final List<dynamic> allKanji;
  final List<dynamic> kun;
  final List<dynamic> on;
  final List<dynamic> meaning;
  final int kanjiId;
  final List<dynamic> qAns;
  final List<dynamic> qValue;
  const Mcq({
    super.key,
    required this.allKanji,
    required this.kanji,
    required this.kanjiRads,
    required this.kun,
    required this.on,
    required this.meaning,
    required this.kanjiId,
    required this.qAns,
    required this.qValue,
  });

  @override
  State<Mcq> createState() => _McqState();
}

class _McqState extends State<Mcq> {
  // make qans postion random
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.kanji, style: TextStyle(fontSize: 80)),
        Text('${widget.kanjiRads}', style: TextStyle(fontSize: 30)),
        Text("Can you guess what the on'yomi reading is?"),
        Wrap(
          children: [
            OutlinedButton(
              onPressed: () {},
              child: Text(
                '${widget.allKanji[Random().nextInt(widget.allKanji.length)]['onreadings']}',
              ),
            ),
            OutlinedButton(onPressed: () {}, child: Text('${widget.qAns}')),
            OutlinedButton(
              onPressed: () {},
              child: Text(
                '${widget.allKanji[Random().nextInt(widget.allKanji.length)]['onreadings']}',
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text(
                '${widget.allKanji[Random().nextInt(widget.allKanji.length)]['onreadings']}',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class McqDragnDrop extends StatefulWidget {
  final String kanji;
  final List<dynamic> kanjiRads;
  final List<dynamic> allKanji;
  final List<dynamic> kun;
  final List<dynamic> on;
  final List<dynamic> meaning;
  final int kanjiId;
  final List<dynamic> qAns;
  final List<dynamic> qValue;
  final bool meaningHidden;
  final bool readingHidden;
  const McqDragnDrop({
    super.key,
    required this.meaningHidden,
    required this.readingHidden,
    required this.allKanji,
    required this.kanji,
    required this.kanjiRads,
    required this.kun,
    required this.on,
    required this.meaning,
    required this.kanjiId,
    required this.qAns,
    required this.qValue,
  });

  @override
  State<McqDragnDrop> createState() => _McqDragnDropState();
}

class _McqDragnDropState extends State<McqDragnDrop> {
  String test = 'data';
  String option = 'option';
  String acceptedData = '';
  bool _isDropped = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DragTarget<String>(
          builder: (context, accepted, rejected) {
            return Container(
              width: 100,
              height: 100,
              decoration: dragDeco,
              child: acceptedData.isEmpty
                  ? const SizedBox()
                  : Container(
                      decoration: dragDeco,
                      child: Center(child: Text(acceptedData)),
                    ),
            );
          },
          onAcceptWithDetails: (details) {
            setState(() {
              acceptedData = details.data;
              _isDropped = true;
            });
          },
        ),
        SizedBox(
          child: Row(
            children: [
              Text('reading:'),
              widget.readingHidden
                  ? SizedBox(width: 80, height: 30, child: inputField)
                  : Text('reading'),
            ],
          ),
        ),
        SizedBox(
          child: Row(
            children: [
              Text('meaning:'),
              widget.meaningHidden
                  ? SizedBox(width: 80, height: 30, child: inputField)
                  : Text('meaning'),
            ],
          ),
        ),
        Draggable<String>(
          data: option,
          feedback: Material(
            child: Container(
              decoration: dragDeco,
              width: 100,
              height: 100,
              child: Center(child: Text(option)),
            ),
          ),
          child: _isDropped
              ? Container(decoration: dragDeco, width: 100, height: 100)
              : Container(
                  decoration: dragDeco,
                  width: 100,
                  height: 100,
                  child: Center(child: Text(option)),
                ),
        ),
      ],
    );
  }
}

BoxDecoration dragDeco = BoxDecoration(
  color: Color(boxoutline),
  borderRadius: BorderRadius.circular(5),
  boxShadow: [
    BoxShadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 3)),
  ],
);

Widget inputField = Container(decoration: dragDeco, child: TextField(
  decoration: InputDecoration(
    border: InputBorder.none,
    contentPadding: EdgeInsets.symmetric(horizontal: 5)
  ),
));


/*
pressing learn starts a new quiz session
for each quiz
2 new kanji - 3 q's in a session 
  first is input onyomi guessing -> these will be the first two introduced at the start of a session
  alternative
3 kanji know the onyomi  - 4 q types, 2 kun , 2 meanigns, 1 input each
2 vocab 
*/