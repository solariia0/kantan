import 'package:flutter/material.dart';
import 'package:kantan/main.dart';
import 'package:kantan/svg.dart';

class SettingsPage extends StatefulWidget { //remove reload fn
  ValueNotifier<int> level;
  ValueNotifier<String> mode;
  final Future<void> Function() reload;
  SettingsPage({super.key, required this.mode, required this.level, required this.reload});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool reset = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Settings'),
        OutlinedButton(onPressed: () {
          setState(() {
            widget.level.value = 0;
            widget.mode.value = 'none';
            reset = true;
          });
          sendData('1/reset', {});
        }, child: Text(reset? 'User reset' : 'Reset User')),
        // change user level
        OutlinedButton(onPressed: () {
          try {sendData('1/jlpt/5', {});}
          catch (e) {print(e.toString());}
        }, child: Text('Add all N5 kanji')),
        OutlinedButton(onPressed: () {
          try {sendData('1/jlpt/5', {});}
          catch (e) {print(e.toString());}
        }, child: Text('Add all N4 kanji')),
        OutlinedButton(onPressed: () {
          try {sendData('1/jlpt/3', {});}
          catch (e) {print(e.toString());}
        }, child: Text('Add all N3 kanji')),
        OutlinedButton(onPressed: () {
          try {sendData('1/jlpt/2', {});}
          catch (e) {print(e.toString());}
        }, child: Text('Add all N2 kanji')),
        OutlinedButton(onPressed: () {
          try {sendData('1/jlpt/1', {});}
          catch (e) {print(e.toString());}
        }, child: Text('Add all N1 kanji')),
        /*
        FutureBuilder(
          future: getData('mode'),
          builder: (context, snapshot) {
            return OutlinedButton(onPressed: () {
              List<dynamic> currentMode = snapshot.data;
              Map postData = {'user_id': 1, 'mode': }
            },
             child: Text('Switch mode'));
          }
        ),*/
        //KanjiSVG(paths: parseKanji(kanjivg, 'kvg:kanji_08526', ['鳥'])),
      ],
    );
  }
}