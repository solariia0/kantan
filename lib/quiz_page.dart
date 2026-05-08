import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
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

class QuizItem {
  final int id;
  final String kanji;
  final List<dynamic> onReadings;
  final List<dynamic> kunReadings;
  final List<dynamic> meanings;
  final List<dynamic> userRadicals;
  final List<dynamic> kanjiRadicals;
  int attempts;

  QuizItem({
    required this.id,
    required this.kanji,
    required this.onReadings,
    required this.kunReadings,
    required this.meanings,
    this.userRadicals = const [],
    this.attempts = 0,
    required this.kanjiRadicals,
  });
}

class Stage {
  final String name;
  List<QuizItem> items;

  Stage({required this.name, this.items = const []});

  bool get isComplete => items.every((item) => item.attempts >= 3);
}

class QuizController {
  final List<Stage> stages;
  int currentStageIndex = 0;
  int currentItemIndex = 0;
  bool quizOver = false;

  QuizController({required this.stages});

  Stage get currentStage => stages[currentStageIndex];
  QuizItem get currentItem => currentStage.items[currentItemIndex];

  Future<String> phoneticRadical(QuizItem kanji) async{
    List radicals = kanji.userRadicals;
    for (String radical in radicals) {
      List<dynamic> radReading = await getData('kanji/info/$radical');
      for (String reading in radReading[0]['onreadings']) {
        if (kanji.onReadings.contains(reading)) {
          return reading;
        } 
      }
    } return '';
  }

  void changeQuestion() {
    stages[currentStageIndex].items[currentItemIndex].attempts++;
    print('currentitemindex : ${currentItemIndex}');
    print('currentitemindex : ${currentStageIndex}');

    if (currentItemIndex < currentStage.items.length - 1) {
      currentItemIndex++; // increment
      print('increment');
    } else {
      currentItemIndex = 0; // reset
      print('reset');
      if (currentStage.isComplete) {
        if (currentStageIndex < stages.length - 1) currentStageIndex++; // increment stage
        else {
          quizOver = true;
        }
      }
    }
  }

  Future<int> selectQuestionType(int prevType) async{
    // 0 = input, 1 = mcq, 2 = mcqdnd, 3 = no question
    QuizItem kanji = currentStage.items[currentItemIndex];
    String rad = await phoneticRadical(kanji);
    if (currentStageIndex == 0 && currentItem.attempts == 0) {
      if (rad == '') { // or if has semantic meaning, mcq instead maybe
        return 3; // show info
      }
      return 0; 
    }
    while (prevType == 2) {
      // return either input or mcq if previous was mcqdnd
      return random.nextInt(2);
    }
    return random.nextInt(3);
  }

  Future<int> selectAnswerType() async{
    // 0 = onyomi, 1 = kunyomi, 2 = meaning
    QuizItem kanji = currentStage.items[currentItemIndex];
    String rad = await phoneticRadical(kanji);
    if (currentStageIndex == 0 && currentItem.attempts == 0) {
      if (rad != '') {
        return 0;
      } // else if semantic meaning return 2
      return 0;
    }
    return random.nextInt(3);
  }

  List<String> generateOptions(
    int answerType,
    int count,
    List<QuizItem> allItems,
  ) {
    List<String> options = [];

    while (options.length < count) {
      var candidate = allItems[random.nextInt(allItems.length)];
      String value = '';
      if (answerType == 0) {
        try {value =
              candidate.onReadings[random.nextInt(candidate.onReadings.length)];} 
              catch (e) {value = 'error: $e';}}  
      else if (answerType == 1) {
        try {value =
              candidate.kunReadings[random.nextInt(candidate.kunReadings.length)];} 
              catch (e) {value = 'error: $e';}}
      else if (answerType == 2) {
        value =
              candidate.onReadings[random.nextInt(candidate.meanings.length)];}
      if (!options.contains(value)) options.add(value);
    }

    options.shuffle(random);
    return options;
  }
}

class _QuizAreaState extends State<QuizArea> {
  late QuizController quizController;
  List<Stage> stages = [
    Stage(name: "New Kanji", items: []),
    Stage(name: "Known Kanji", items: []),
    Stage(name: "Vocab", items: []),
  ];
  List<QuizItem> allKanji = [];

  void initQuiz() async {
    List<dynamic> newKanji = await getData('quiz/jlpt/onyomi/1');
    List<dynamic> knownKanji = await getData('quiz/jlpt/kunyomi/1');
    List<dynamic> vocab = await getData('quiz/vocab/1');

    List sets = [newKanji, knownKanji, vocab];

    setState(() {
      for (int i = 0; i < stages.length; i++) {
        Stage stage = stages[i];
        for (var kanji in sets[i]) {
          bool nullRads = kanji['user_radicals'] == null;
          QuizItem quizItem = QuizItem(
            id: kanji['id'],
            kanji: kanji['literal'],
            onReadings: kanji['onreadings'],
            kunReadings: kanji['kunreadings'],
            meanings: kanji['meanings'],
            userRadicals: nullRads? [] : kanji['user_radicals'],
            kanjiRadicals: kanji['radicals'],
          );
          stage.items.add(quizItem);
          allKanji.add(quizItem);
        }
      }
    });

    quizController = QuizController(stages: stages);
    print('quiz initialized');
    setQuestion();
  }

  int questionType = 4;
  int answerType = 0;
  String answer = '';

  // question inputs
  bool answered = false;
  String userText = '';
  String hintText = '';
  String subText = '';
  String svgId = '';
  List userRadicals = [];
  List mcqOptions = [];
  Color ansColor = Colors.white;
  List<Map<String, dynamic>> dndOptions = [];
  // [{kanji: QuizItem.kanji, readings: QuizItem.readings, meanings: QuizItems.meanings}]
  List answers = [];
  List relevantRads = [];

  void setQuestion() async{
    int answerType = await quizController.selectAnswerType();
    int prevType = questionType;
    questionType = await quizController.selectQuestionType(prevType);
    setState(() {
      userText = '';
      relevantRads = [];
      print('currentitem index: ${quizController.currentItemIndex}');
      print(answerType);
      QuizItem currentQuizItem = stages[quizController.currentStageIndex].items[quizController.currentItemIndex];
      print('attempts: ${currentQuizItem.attempts}');
      print('on: ${currentQuizItem.onReadings}');
      print('kun: ${currentQuizItem.kunReadings}');
      print('meanings: ${currentQuizItem.meanings}');
      print('stage index: ${quizController.currentStageIndex}');
      print('item index: ${quizController.currentItemIndex}');
      print('qtype: $questionType');
      svgId = kanjiToId[currentQuizItem.kanji]!;
      relevantRads.add(quizController.phoneticRadical(currentQuizItem));

      if (answerType == 0) {
        subText = 'What is the onyomi reading?';
        answers = List.from(currentQuizItem.onReadings);
        }
      else if (answerType == 1) {subText = 'What is the kunyomi reading?';
      answers = List.from(currentQuizItem.kunReadings);
      print('kun answer :${currentQuizItem.kunReadings}');
      }
      else if (answerType == 2) {subText = 'What is the meaning?';
      answers = List.from(currentQuizItem.meanings);
      }
      
      // selecting single answer for on/kun
      // meaning takes list answers
      answer = answers[random.nextInt(answers.length)];
      answers.remove(answer);
      bool altNull = answers.isEmpty;
      hintText = altNull? '' : 'alternative: ${answers.join(', ')}';

      if (questionType == 1) {
        mcqOptions = [];
        mcqOptions.add(answer);
        print(mcqOptions.length);
        mcqOptions = quizController.generateOptions(answerType, 3, allKanji);
        print(mcqOptions.length);
        mcqOptions.shuffle();
      } else if (questionType == 2) {
        dndOptions = [];
        int currentStageLength = quizController.currentStage.items.length;
        kanjiBg = List.filled(currentStageLength, Color(boxoutline));
        readingBg = List.filled(currentStageLength, Color(boxoutline));
        meaningBg = List.filled(currentStageLength, Color(boxoutline));
        // assigning data for drag and drop questions
        bool onKun = random.nextBool();
        List kanji = [];
        List readings = [];
        List meanings = [];
        for (var item in stages[quizController.currentStageIndex].items) {
          kanji.add(item.kanji);
          readings.add(onKun? item.onReadings:item.kunReadings);
          meanings.add(item.meanings);        
        }

        // defining answer pairs for checking in mcqdnd
        answers = List.generate(kanji.length, (index) {
          return [kanji[index], meanings[index], readings[index]];
        });

        // randomizing pairs and kanji
        int kanjiLength = kanji.length;
        for (var i=0; i<kanjiLength; i++) {
          String tempKanji = kanji[random.nextInt(kanji.length)];
          kanji.remove(tempKanji);
          int readingMeaningIndex = random.nextInt(readings.length);
          List tempreading = readings[readingMeaningIndex];
          readings.remove(tempreading);
          List tempmeaning = meanings[readingMeaningIndex];
          meanings.remove(tempmeaning);
          dndOptions.add({
            'kanji': tempKanji,
            'readings': tempreading,
            'meanings': tempmeaning
            });
        }

      }
    });
  }

  // for input and mcq
  void checkAns(String userAns) {
    QuizItem currentQuizItem = stages[quizController.currentStageIndex].items[quizController.currentItemIndex];
    bool meaning = questionType == 2;
     Map postData = {"kanji_id": quizController.currentItem.id, "correct": 0, "wrong": 0};
    setState(() {
      if (!meaning) {
          userAns = kanaKit.toKatakana(userAns);
         if (userAns == answer) {
        ansColor = Color(0xFF3ACB9E);
        postData['correct'] = 1;
      } else {
        ansColor = Color(0xFFCB3A74);
        postData['wrong'] = 1;
      }
        if (answerType == 0) {
          subText = 'onyomi: ${currentQuizItem.onReadings.join(', ')}';
        } else if (answerType == 1) {
          subText = 'kunyomi: ${currentQuizItem.kunReadings.join(', ')}';
        }
        hintText = currentQuizItem.meanings.join(', '); 
      } else {
        hintText = 'kunyomi: ${currentQuizItem.kunReadings.join(', ')} | onyomi: ${currentQuizItem.onReadings.join(', ')}';
        subText = currentQuizItem.meanings.join(', ');
        if (answers.contains(userAns)) {
          ansColor = Color(0xFF3ACB9E);
          postData['correct'] = 1;
          }
        else {
          ansColor = Color(0xFFCB3A74);
          postData['wrong'] = 1;
          }
      }
      userText = userAns;
      answered = true;
    });
    sendData('user_kanji/1/onyomi', postData);
  }

  void changeQuestion() {
    setState(() {
      answered = false;
      quizController.changeQuestion();
      setQuestion();
    });
  }

  List<Color> kanjiBg = [];
  List<Color> readingBg = [];
  List<Color> meaningBg = [];

  // checking answer for drag and drop
  void checkDndAns(List<String?> acceptedData, List<TextEditingController> readingControllers, List<TextEditingController> meaningControllers) {
    // pairing index to corresponding answer
    List ansInputPairs = [];
    for (var i = 0; i < acceptedData.length; i++) {
      for (var x = 0; x < acceptedData.length; x++) {
        if (answers[i][1] == dndOptions[x]['meanings']) {
          // i = answer index, x = input index
          ansInputPairs.add([i, x]);
        }
      }
    }

    // asnwers = [[kanji, meanings, readings]]
    for (var pair in ansInputPairs) {
      setState(() {
          // checking if kanji is correct
          int i = pair[0];
          int x = pair[1];
    if (acceptedData[x] == answers[i][0]) {
      kanjiBg[x] = Color(0xFF3ACB9E);
    } else {kanjiBg[x] = Color(0xFFCB3A74);}
    // checking if meaning is correct
    if (meaningControllers[x].text != '') {
      String usrAns = meaningControllers[x].text;
      //usrAns = kanaKit.toKatakana(usrAns);
      if (answers[i][1].contains(usrAns)) {
        meaningBg[x] = Color(0xFF3ACB9E);
      } else {meaningBg[x] = Color(0xFFCB3A74);}
    }
    // checking if reading is correct
      if (readingControllers[x].text != '') {
      String usrAns = readingControllers[x].text;
      usrAns = kanaKit.toKatakana(usrAns);
      if (answers[i][2].contains(usrAns)) {
        readingBg[x] = Color(0xFF3ACB9E);
      } else {readingBg[x] = Color(0xFFCB3A74);}
      }

      });
    }
  }

  @override
  void initState() {
    super.initState();
    initQuiz();
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
              if(questionType == 4)
              Text('Loading....', style: TextStyle(fontSize: 50),),
              if (questionType == 3)
              DisplayKanji(kanji: quizController.currentStage.items[quizController.currentItemIndex], changeQuestion: changeQuestion),
              if (questionType == 0)
                InputQ(svgId: svgId, relevantRads: relevantRads, answered: answered, changeQuestion: changeQuestion, checkAns: (userAns) {checkAns(userAns);}, userText: userText, subText: subText, ansColor: ansColor, hintText: hintText),
              if (questionType == 1)
               Mcq(key: ValueKey(quizController.currentItemIndex), answered: answered, userText: userText, ansColor: ansColor, svgId: svgId, relevantRads: relevantRads, options: mcqOptions, changeQuestion: changeQuestion, checkAns: (userAns) {checkAns(userAns);}, subText: subText, hintText: hintText),
              if (questionType == 2)
              McqDnDContainer(key: ValueKey(quizController.currentItemIndex), kanjiBg: kanjiBg, readingBg: readingBg, meaningBg: meaningBg, options: dndOptions, checkDndAns: (kanji, readings, meanings) {checkDndAns(kanji, readings, meanings);}, changeQuestion: changeQuestion)
            ],
          ),
        ],
      ),
    );
  }
}

class DisplayKanji extends StatelessWidget {
  final QuizItem kanji;
  final Function changeQuestion;
  const DisplayKanji({super.key, required this.kanji, required this.changeQuestion});

  @override
  Widget build(BuildContext context) {
    return Column(
    children: [
    Text(kanji.kanji),
    Text('onyomi: ${(kanji.onReadings).join(', ')}'),
    Text('kunyomi: ${(kanji.kunReadings).join(', ')}'),
    Text('meaning: ${(kanji.meanings).join(', ')}'),
    OutlinedButton(onPressed: (){changeQuestion();}, child: Text('next')),
    ],
    );
  }
}

class InputQ extends StatefulWidget {
  bool answered;
  final String svgId;
  final List relevantRads;
  String userText;
  String hintText;
  String subText;
  Color ansColor;
  final Function() changeQuestion;
  final Function(String) checkAns;

  InputQ({
    super.key,
    required this.svgId,
    required this.relevantRads,
    required this.answered,
    required this.changeQuestion,
    required this.checkAns,
    required this.userText,
    required this.subText,
    required this.ansColor,
    required this.hintText
  });

  @override
  State<InputQ> createState() => _InputQState();
}

class _InputQState extends State<InputQ> {
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
          Center(
            child: KanjiSVG(
              paths: parseKanji(
                kanjivg,
                "kvg:${widget.svgId}",
                widget.relevantRads,
              ),
            ),
          ),
        if (widget.answered)
          Text(
            widget.userText,
            style: TextStyle(fontSize: 30, color: widget.ansColor),
          ),
        Text(widget.hintText, style: TextStyle(fontSize: 30)),
        Text(widget.subText, style: TextStyle(fontSize: 30)),

        if (!_inputOn)
          OutlinedButton(
            onPressed: () {
              widget.changeQuestion();
              setState(() {
                _inputOn = !_inputOn;
              });
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
              widget.checkAns(text);
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
  final String svgId;
  bool answered;
  final List relevantRads;
  final List options;
  String userText;
  String subText;
  String hintText;
  Color ansColor;
  final Function() changeQuestion;
  final Function(String) checkAns;

  Mcq({
    super.key,
    required this.answered,
    required this.userText,
    required this.ansColor,
    required this.svgId,
    required this.relevantRads,
    required this.options,
    required this.changeQuestion,
    required this.checkAns,
    required this.subText,
    required this.hintText,
  });

  @override
  State<Mcq> createState() => _McqState();
}

class _McqState extends State<Mcq> {
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
              paths: parseKanji(
                kanjivg,
                "kvg:${widget.svgId}",
                widget.relevantRads,
              ),
            ),
          ),
        if (widget.answered)
          Text(
            widget.userText,
            style: TextStyle(fontSize: 30, color: widget.ansColor),
          ),
        Text(widget.hintText, style: TextStyle(fontSize: 30)),
        Text(widget.subText, style: TextStyle(fontSize: 30)),
        if (!widget.answered)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.options.map((option) {
              return OutlinedButton(
                onPressed: () {
                  widget.checkAns(option);
                },
                child: Text(option),
              );
            }).toList(),
          ),
        if (widget.answered)
          OutlinedButton(
            onPressed: () {
                widget.changeQuestion();
                setState(() {
                  widget.answered = false;
                });
            },
            child: Text('next'),
          ),
      ],
    );
  }
}

class McqDragnDrop extends StatefulWidget {
  final Map options;
  final TextEditingController readingController;
  final TextEditingController meaningController;
    Color kanjiBg;
  Color readingBg;
  Color meaningBg;
  McqDragnDrop({
    super.key,
    required this.options,
    required this.meaningController,
    required this.readingController,
    required this.kanjiBg,
    required this.meaningBg,
    required this.readingBg,
  });

  @override
  State<McqDragnDrop> createState() => _McqDragnDropState();
}

class _McqDragnDropState extends State<McqDragnDrop> {
  String acceptedData = '';
  bool _isDropped = false;
  bool hidden = random.nextBool();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('reading:'),
                    hidden
                        ? Container(
                            margin: EdgeInsets.all(3),
                            width: 80,
                            height: 20,
                            child: makeInputField(widget.readingController, widget.readingBg),
                          )
                        : SizedBox(width: 150, child: Text(widget.options['readings'].join(', '), softWrap: true,)),
                  ],
                ),
                Text('meaning:'),
                Container(
                  margin: EdgeInsets.all(10),
                  child: !hidden
                      ? Container(
                          margin: EdgeInsets.all(3),
                          width: 80,
                          height: 20,
                          child: makeInputField(widget.meaningController, widget.meaningBg),
                        )
                      : SizedBox(width: 150, child: Text(widget.options['meanings'].join(', '), softWrap: true,)),
                ),
                Draggable<String>(
                  data: widget.options['kanji'],
                  feedback: Material(
                    child: Container(
                      decoration: makeDragDeco(Color(boxoutline)),
                      width: 80,
                      height: 80,
                      child: Center(child: Text(widget.options['kanji'])),
                    ),
                  ),
                  child: _isDropped
                      ? Container(decoration: makeDragDeco(Color(boxoutline)), width: 100, height: 100)
                      : Container(
                          decoration: makeDragDeco(Color(boxoutline)),
                          width: 80,
                          height: 80,
                          child: Center(child: Text(widget.options['kanji'])),
                        ),
                ),
              ],
            );
  }
}

// turn dnd items into a model at some point
class McqDnDContainer extends StatefulWidget {
  final List<Map> options;
  final Function(List<String?>, List<TextEditingController>, List<TextEditingController>) checkDndAns;
  List<Color> kanjiBg;
  List<Color> readingBg;
  List<Color> meaningBg;
  final Function() changeQuestion;
  McqDnDContainer ({super.key, required this.changeQuestion, required this.kanjiBg, required this.readingBg, required this.meaningBg, required this.checkDndAns, required this.options});

  @override
  State<McqDnDContainer> createState() => _McqDnDContainerState();
}

class _McqDnDContainerState extends State<McqDnDContainer> {
  bool answered = false;

  late List<String?> acceptedData;
  late List<bool> isDropped;
  late List<TextEditingController> readingControllers;
  late List<TextEditingController> meaningControllers;

  @override
  void initState() {
    super.initState();
    acceptedData = List.filled(widget.options.length, null);
    isDropped = List.filled(widget.options.length, false);
    readingControllers = List.generate(
    widget.options.length,
    (_) => TextEditingController());
    meaningControllers = List.generate(
    widget.options.length,
    (_) => TextEditingController(),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: List.generate(widget.options.length, (index) {
              return DragTarget<String>(
                builder: (context, accepted, rejected) {
                  return Container(
                    width: 130,
                    height: 130,
                    margin: const EdgeInsets.all(8),
                    decoration: makeDragDeco(widget.kanjiBg[index]),
                    child: acceptedData[index] == null
                        ? const SizedBox()
                        : Center(
                            child: Text(
                              acceptedData[index]!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                  );
                },
                onAcceptWithDetails: (details) {
                  setState(() {
                    acceptedData[index] = details.data;
                    isDropped[index] = true;
                  });});}
                  ),
              ),
          Row(
            children: List.generate(widget.options.length, (index) {
              return McqDragnDrop(kanjiBg: widget.kanjiBg[index], readingBg: widget.readingBg[index], meaningBg: widget.meaningBg[index], options: widget.options[index], readingController: readingControllers[index], meaningController: meaningControllers[index]);
            })
          ),
          if (!answered)
          OutlinedButton(onPressed: () {
            widget.checkDndAns(acceptedData, readingControllers, meaningControllers);
          }, child: Text('check')),
          OutlinedButton(onPressed: () {
            widget.changeQuestion();
            setState(() {
              answered = true; // make this show and hide properly
            });
          }, child: Text('next'))
        ],
      ),
    );
  }
}

BoxDecoration makeDragDeco(Color bgcolor) {
  return BoxDecoration(
  color: bgcolor,
  borderRadius: BorderRadius.circular(5),
  boxShadow: [
    BoxShadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 3)),
  ],
);
}

Container makeInputField(TextEditingController controller, Color bgcolor) {
  return Container(
  decoration: makeDragDeco(bgcolor),
  child: TextField(
    controller: controller,
    style: TextStyle(fontSize: 14),
    decoration: InputDecoration(
      border: InputBorder.none,
      //contentPadding: EdgeInsets.symmetric(vertical: 2)
    ),
  ),
);
}
