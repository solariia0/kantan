import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kantan/svg.dart';
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
        if (quizStarted) quizContent[currentQuiz],
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
  void newQuiz() async {
    List<dynamic> newKanji = await getData('path');
    List newTracking = [for (var i = 0; i < newKanji.length; i++) 0];
    List<dynamic> knownKanji = await getData('path');
    List knownTracking = [for (var i = 0; i < newKanji.length; i++) 0];
    List<dynamic> vocab = await getData('path');
    List vocabTracking = [for (var i = 0; i < newKanji.length; i++) 0];

    final List<List<dynamic>> stages = [newKanji, knownKanji, vocab];
    final List stageAttempts = [newTracking, knownTracking, vocabTracking];

    int stage = 0; // index for currentStage taken from stages
    List currentStage = stages[stage];
    int stageItem = 0; // index of currentKanji taken from currentStage
    List<dynamic> currentKanji = currentStage[stageItem];

    int kanjidicId = currentKanji['id'];

    final List questionTypes = ['input', 'mcq', 'mcqdnd'];
    int questionType = 0; // index for questionTypes
    final List answerTypes = ['onyomi', 'kunyomi', 'meaning'];
    int answerType = 0;

    if (stage == 0 && stageAttempts[0][stageItem] == 0) {
      questionType = 0;
      
      // answer type is based on flowchart
    }
  }

  // kanji info
  int kanjiId = 0; // id in kanjidic2 table
  int kanjiIndex = 0; // current kanji index
  String kanji = '';
  List<dynamic> kanjiRads = [];
  List<dynamic> kun = []; // kunyomi
  List<dynamic> on = []; // onyomi
  List<dynamic> meaning = [];
  List<dynamic> userRads = [];

  List<dynamic> kanjiListQuiz = []; // probably safe to delete

  // managing quiz state
  int stage = 0; // quiz stage
  List currentSet = [];
  List allKanji = [];

  List newKanji = [];
  List knownKanji = [];
  List newVocab = [];

  // tracks the number of times each character is quizzed
  List<int> newTracking = [];
  List<int> knownTracking = [];
  List<int> vocabTracking = [];

  Future<void> initializeKanji() async {
    newKanji = await getData('quiz/onyomi/1');
    for (int i = 0; i < newKanji.length; i++) {
      newTracking.add(0);
    }
    allKanji = newKanji;
    List<dynamic> onData = await getData('total/1');
    if (onData[0]['on_accuracy'] >= 70 && onData[0]['learned kanji'] >= 3) {
      try {
        knownKanji = await getData('quiz/kunyomi/1');
        allKanji.add(knownKanji[0]);
        for (int i = 0; i < knownKanji.length; i++) {
          knownTracking.add(0);
        }
      } catch (e) {
        if (e is TypeError) {
          if (e.toString().contains('null')) {
            List<dynamic> moreKanji = await getData('quiz/onyomi/1');
            print("Length of newKanji before: ${newKanji.length}");
            print("length of moreKanji ${moreKanji.length}");
            print("new tracking length before: ${newTracking.length}");
            print(newKanji);
            print(moreKanji);
            newKanji.add(moreKanji[0]);
            allKanji.add(moreKanji[0]);
            for (int i = 0; i < moreKanji.length; i++) {
              newTracking.add(0);
            }
            print("length of new kanji after: ${newKanji.length}");
            print("new tracking length: ${newTracking.length}");
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
        // if stage 2 doesn't exist skip it
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
        } else if (stage >= 6) {
          currentSet = newVocab;
          trackingType = 2;
          print('vocab');
        }

        // define kanji values
        kanji = currentSet[kanjiIndex]['literal'];
        kanjiRads = currentSet[kanjiIndex]['radicals'];
        kun = currentSet[kanjiIndex]['kunreadings'];
        on = currentSet[kanjiIndex]['onreadings'];
        for (var onyomi in on) {
          onyomi = kanaKit.toHiragana(onyomi);
        }
        for (var kunyomi in kun) {
          kunyomi = kanaKit.toHiragana(kunyomi);
        }
        meaning = currentSet[kanjiIndex]['meanings'];
        kanjiListQuiz = currentSet;
        kanjiId = currentSet[kanjiIndex]['id'];

        subText = '$kanjiRads';

        svgid = kanjiToId[kanji]!;

        setQuestion();
        ansColor = Colors.white;
      });
    } catch (e) {
      setState(() {
        kanji = "ERROR: $e";
      });
    }
  }

  String readingType = '';

  void setQuestion() {
    List tracking = [newTracking, knownTracking, vocabTracking];
    List values = [kun, on, meaning];
    if (tracking[trackingType][kanjiIndex] == 0) {
      readingType = 'kunreadings'; //testing
      qType = 0;
      qAns = on;
      qValue = values[2];
      hintText = "Can you guess the on'yomi reading?";
      print('first on first, apparently');
      print("tracking type [new, known, vocab]: $trackingType");
      print("values in the tracking type: ${tracking[trackingType]}");
      print("index of the current kanji: $kanjiIndex");
      print("length of newkanji: ${newKanji.length}");
      print("stage:  $stage");
    } else {
      qType = Random().nextInt(2) + 1;
      int ans = Random().nextInt(2);
      int value = Random().nextInt(2);
      while (ans == value) {
        value = Random().nextInt(2);
      }
      qAns = values[ans];
      qValue = values[value];
      if (ans == 0) {
        hintText = "What is the kun'yomi reading?";
        readingType = 'kunreadings';
      } else if (ans == 1) {
        hintText = "Can you guess the on'yomi reading?";
        readingType = 'onreadings';
      } else if (ans == 2) {
        hintText = "What is the meaning?";
      } else {
        hintText = "something has gone wrong";
      }

      print('passed first round of onyomi');
      print("tracking type [new, known, vocab]: $trackingType");
      print("values in the tracking type: ${tracking[trackingType]}");
      print("index of the current kanji: $kanjiIndex");
      print("stage:  $stage");
      qType = 1; // for testing
    }
  }

  Color ansColor = Colors.white;
  bool answered = false;
  String answer = '';
  bool correct = false;
  String mainText = '';
  String subText = '';
  String hintText = '';
  String svgid = '';

  void inputCheck(String text) {
    List tracking = [newTracking, knownTracking, vocabTracking];
    tracking[trackingType][kanjiIndex] += 1;

    Map postData = {"kanji_id": kanjiId, "correct": 0, "wrong": 0};

    String converted = kanaKit.toKatakana(text);
    answered = true;
    answer = converted;
    mainText = converted;

    if (qAns.contains(converted)) {
      postData['correct'] = 1;
      correct = true;
      setState(() {
        ansColor = Color.fromARGB(255, 68, 185, 113);
        subText = meaning.join(', ');
        hintText = '';
      });
    } else {
      postData['wrong'] = 1;
      setState(() {
        ansColor = Color.fromARGB(255, 192, 45, 65);
        correct = false;
        subText = qAns.join(', ');
        hintText = meaning.join(', ');
      });
      sendData('user_kanji/1/onyomi', postData);
    }
  }

  void next() {
    print('submitted');
    print(kanjiIndex);
    if (kanjiIndex >= currentSet.length) {
      kanjiIndex = 0;
      print('index reset');
      List tracking = [newTracking, knownTracking, vocabTracking];
      if (tracking[trackingType][currentSet.length] >= 3) {
        stage++; //
        print('stage change');
      }
    } else {
      kanjiIndex++;
    }

    //reset bool
    correct = false;
    answered = false;
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
      //width: MediaQuery.of(context).size.width * 0.35,
      //height: MediaQuery.of(context).size.height * 0.55,
      //margin: EdgeInsets.symmetric(horizontal: 50),
      //padding: EdgeInsets.symmetric(vertical: 40),
      //decoration: itemdeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              if (qType == 0)
                InputQuestion(
                  svgid: svgid,
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
                  answered: answered,
                  answer: answer,
                  ansColor: ansColor,
                  correct: correct,
                  mainText: mainText,
                  subText: subText,
                  hintText: hintText,
                  next: next,
                ),
              if (qType == 1)
                Mcq(
                  svgid: svgid,
                  kanji: kanji,
                  kanjiRads: kanjiRads,
                  kun: kun,
                  on: on,
                  meaning: meaning,
                  kanjiId: kanjiId,
                  qAns: qAns,
                  qValue: qValue,
                  onSubmit: (text) {
                    inputCheck(text);
                  },
                  answered: answered,
                  answer: answer,
                  ansColor: ansColor,
                  correct: correct,
                  mainText: mainText,
                  subText: subText,
                  hintText: hintText,
                  next: () {
                    next();
                  },
                  allKanji: allKanji,
                ),
              if (qType == 2)
                McqDragnDrop(readingType: readingType, currentSet: currentSet),
            ],
          ),
        ],
      ),
    );
  }
}

class InputQuestion extends StatefulWidget {
  final String svgid;
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
    required this.svgid,
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
        if (!widget.answered)
          Center(
            child: KanjiSVG(
              paths: parseKanji(kanjivg, "kvg:${widget.svgid}", []),
            ),
          ),
        if (widget.answered)
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
  final String svgid;
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
  final List<dynamic> allKanji;

  Mcq({
    super.key,
    required this.svgid,
    required this.kanji,
    required this.kanjiRads,
    required this.kun,
    required this.on,
    required this.meaning,
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
    required this.allKanji,
  });

  @override
  State<Mcq> createState() => _McqState();
}

class _McqState extends State<Mcq> {
  List<String> options = [];

  void _generateOptions() {
    // when showing kunyomi options don't update properly
    // options don't update at all go to next()
    setState(() {
      options = [];
      var ans = widget.qAns[random.nextInt(widget.qAns.length)];
      ans = kanaKit.toHiragana(ans);
      options.add(ans);

      while (options.length < 4) {
        var candidate = widget
            .allKanji[random.nextInt(widget.allKanji.length)]['onreadings'];
        candidate = kanaKit.toHiragana(
          candidate[random.nextInt(candidate.length)],
        );

        if (!options.contains(candidate)) {
          options.add(candidate);
        }
      }
      options.shuffle(random);
    });
  }

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  // make qans postion random
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!widget.answered)
          Center(
            child: KanjiSVG(
              paths: parseKanji(kanjivg, "kvg:${widget.svgid}", []),
            ),
          ),
        if (widget.answered)
          Text(
            widget.mainText,
            style: TextStyle(
              color: widget.answered ? widget.ansColor : Colors.white,
              fontSize: 80,
            ),
          ),
        Text(widget.subText, style: TextStyle(fontSize: 30)),
        Text(widget.hintText),
        if (!widget.answered)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options.map((option) {
              return OutlinedButton(
                onPressed: () {
                  widget.onSubmit(option);
                },
                child: Text(option),
              );
            }).toList(),
          ),
        if (widget.answered)
          OutlinedButton(onPressed: widget.next, child: Text('next')),
      ],
    );
  }
}

class McqDragnDrop extends StatefulWidget {
  final List<dynamic> currentSet;
  final String readingType;
  const McqDragnDrop({
    super.key,
    required this.readingType,
    required this.currentSet,
  });

  @override
  State<McqDragnDrop> createState() => _McqDragnDropState();
}

class _McqDragnDropState extends State<McqDragnDrop> {
  String test = 'data';
  String acceptedData = '';
  bool _isDropped = false;

  final List<bool> _hidden = [true, true, false, false];
  int i = -1;
  List options = [];

  void _generateOptions() {
    setState(() {
      while (options.length < widget.currentSet.length) {
        Map<String, dynamic> candidate =
            widget.currentSet[random.nextInt(widget.currentSet.length)];

        if (!options.contains(candidate)) {
          options.add(candidate);
        }
      }
      options.shuffle();
    });
  }

  @override
  void initState() {
    super.initState();
    _generateOptions();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: options.map((option) {
        i++;
        return Column(
          children: [
            DragTarget<String>(
              builder: (context, accepted, rejected) {
                return Container(
                  width: 130,
                  height: 130,
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
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('reading:'),
                  _hidden[i]
                      ? Container(
                          margin: EdgeInsets.all(3),
                          width: 80,
                          height: 20,
                          child: inputField,
                        )
                      : Wrap(
                          children: [Text((option['kunreadings']).join(', '))],
                        ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('meaning:'),
                  !_hidden[i]
                      ? Container(
                          margin: EdgeInsets.all(3),
                          width: 80,
                          height: 20,
                          child: inputField,
                        )
                      : Text((option['meanings']).join(', ')),
                ],
              ),
            ),
            Draggable<String>(
              data: option['literal'],
              feedback: Material(
                child: Container(
                  decoration: dragDeco,
                  width: 80,
                  height: 80,
                  child: Center(child: Text(option['literal'])),
                ),
              ),
              child: _isDropped
                  ? Container(decoration: dragDeco, width: 100, height: 100)
                  : Container(
                      decoration: dragDeco,
                      width: 80,
                      height: 80,
                      child: Center(child: Text(option['literal'])),
                    ),
            ),
          ],
        );
      }).toList(),
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

Widget inputField = Container(
  decoration: dragDeco,
  child: TextField(
    style: TextStyle(fontSize: 14),
    decoration: InputDecoration(
      border: InputBorder.none,
      //contentPadding: EdgeInsets.symmetric(vertical: 2)
    ),
  ),
);
