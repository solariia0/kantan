import 'package:flutter/material.dart';
import 'package:kantan/main.dart';
import 'package:kantan/svg.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: getData('mode'),
          builder: (context, snapshot) {
            return OutlinedButton(onPressed: () {
              List<dynamic> currentMode = snapshot.data;
              Map postData = {'user_id': 1, 'mode': }
            },
             child: Text('Switch mode'));
          }
        ),
        KanjiSVG(paths: parseKanji(kanjivg, 'kvg:kanji_08526', ['鳥'])),
      ],
    );
  }
}