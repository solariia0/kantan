import 'dart:convert';

import 'package:flutter/material.dart';
import 'main.dart';
import 'package:kana_kit/kana_kit.dart';

const kanaKit = KanaKit();

class QuizzPage extends StatefulWidget {
  const QuizzPage({super.key});

  @override
  State<QuizzPage> createState() => _QuizzPageState();
}

class _QuizzPageState extends State<QuizzPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuizArea(),
        OutlinedButton(
          onPressed: () {},
          style: buttondeco,
          child: Text('switch to vocabulary'),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(onPressed: () {}, child: Text('Learn')),
            OutlinedButton(onPressed: () {}, child: Text('Review')),
          ],
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

  int newkanjiindex = 0;
  String currentkanji = '';
  List<dynamic> ckanjirads = [];
  List<dynamic> qValue = [];
  List<dynamic> qAns = [];
  List<dynamic> kanjiListQuiz = [];

  // implement multiple question types

  void getNewKanji() async {
  try {
    List<dynamic> data = await getData('quiz/new');
    if (!mounted) return;
    setState(() {
      currentkanji = data[newkanjiindex]['literal'];
      ckanjirads = data[newkanjiindex]['radicals'];
      qAns = data[newkanjiindex]['onreadings'];
      qValue = data[newkanjiindex]['meanings'];
      kanjiListQuiz = data;

      print(qAns);
    });
  } catch (e) {
    setState(() {
      currentkanji = "ERROR: $e";
    });
  }
}

  @override
  void initState() {
    super.initState();
    getNewKanji();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.35,
      height: MediaQuery.of(context).size.height * 0.45,
      decoration: itemdeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            currentkanji,
            style: TextStyle(
              color: Colors.white,
              fontSize: 80,
            ),
          ),
          Text(
            '$ckanjirads',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
            ),
          ),
          Text(
            "Can you guess what the on'yomi reading is?",
            style: TextStyle(color: Colors.white),
            ),
          /*
          FutureBuilder(
            future: getNewKanji(),
            builder: (context, snapshot) { // curently new onyomi reading
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Text(
                      currentkanji,
                      style: TextStyle(color: Colors.white, fontSize: 40)),
                    //Text('$ckanjirads')
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('error: ${snapshot.error}');
              } else {
                return CircularProgressIndicator();
              }
            }
            ),*/
          TextField(
            controller: _controller,
            onChanged: (text) {
              String converted = kanaKit.toHiragana(text);

              if (converted != text) {
                _controller.value = TextEditingValue(
                  text: converted,
                  selection: TextSelection.collapsed(offset: converted.length),
                  );
              }
            },
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: Color(boxoutline)
                )
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: Color(boxoutline)
                )
              )
            ),
          ),
        ],
      ),
    );
  }
}

void Quiz() {
  // 3 stages of 3 characters each
  // onyomi, kunyomi, compound
  //List<int> stages = [0, 4, 10];
  //int stage = 0;

  //while (stage < 4) {
    // fetch 3 new random kanji from mode/level combo
    // input
  //}
  // fetch prev accuracy 


}
