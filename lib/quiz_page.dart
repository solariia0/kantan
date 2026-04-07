import 'package:flutter/material.dart';
import 'main.dart';

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

class QuizArea extends StatelessWidget {
  const QuizArea({super.key});
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
          Text('kanji'),
          //FutureBuilder(
          //future: future,
          //builder: builder
          //)
          TextField(),
        ],
      ),
    );
  }
}

void Quiz() {
  // 3 stages of 3 characters each
  // onyomi, kunyomi, compound
  List<int> stages = [0, 4, 10];
  int stage = 0;

  while (stage < 4) {
    // fetch 3 new random kanji from mode/level combo
    // input
  }
  // fetch prev accuracy 
}
