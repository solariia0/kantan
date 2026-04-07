import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// pages
import 'kanjiPage.dart';
import 'package:kantan/quiz_page.dart';

void main() {
  runApp(const MainApp());
}

// themes and colors
final int boxoutline = 0xFF4D92B4;
final int bg = 0xFF282B31;
final int accentblue = 0xFF242B3F;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kantan',
      home: Scaffold(
        backgroundColor: Color(bg),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [SideBar(), MainArea(), QuizModeBar()],
          ),
        ),
      ),
    );
  }
}

class MainArea extends StatelessWidget {
  final List<Widget> _pageWidgets = const [
    QuizzPage(),
    KanjiPage(),
    Center(child: Text('Settings Page')),
  ];

  const MainArea({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: pageNotifier,
      builder: (context, index, _) {
        return Container(
          margin: EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: componentDeco,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_pageWidgets[index]],
          ),
        );
      },
    );
  }
}

// navigation notifier
ValueNotifier<int> pageNotifier = ValueNotifier(0);

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width * 0.15,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: componentDeco,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 200, // this may break idk
            child: OutlinedButton.icon(
              onPressed: () => {pageNotifier.value = 0},
              label: Text('Home', style: TextStyle(color: Colors.white)),
              icon: Icon(Icons.home, color: Colors.white),
              style: buttondeco,
            ),
          ),
          BlankWiget(), // streak bar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
            height: 100,
            width: 100,
            decoration: itemdeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Kanji Learned', style: TextStyle(),),
                // futurue builder
                Text('150')
              ],
            ),
          ),
          Container(
            height: 100,
            width: 100,
            decoration: itemdeco,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Vocab Learned'),
                // futurue builder
                Text('20')
              ],
            ),
          ),
            ],
          ),
          Container(
            height: 50,
            width: 200,
            decoration: itemdeco,
            child: Column(
              children: [
                // all fetched level and mode and known
                Text('N3 Progress'),
                Container(
                  height: 20,
                  width: 150,
                  decoration: itemdeco,
                  child: Container(
                    height: 20,
                    // fetch width
                    width: 10,
                    decoration: BoxDecoration(
                      color: Color(boxoutline),
                      borderRadius: BorderRadius.circular(5)
                    ),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: OutlinedButton(
              onPressed: () => {pageNotifier.value = 1},
              style: buttondeco,
              child: Text('Manage Kanji', style: TextStyle(color: Colors.white)),
            ),
          ),
          SizedBox(
            width: 200,
            child: OutlinedButton.icon(
              onPressed: () => {pageNotifier.value = 2},
              label: Text('Settings', style: TextStyle(color: Colors.white)),
              icon: Icon(Icons.settings, color: Colors.white),
              style: buttondeco,
            ),
          ),
        ],
      ),
    );
  }
}

class QuizModeBar extends StatelessWidget {
  const QuizModeBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      width: MediaQuery.of(context).size.width * 0.15,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: componentDeco,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BlankWiget(), // streak bar
        ],
      ),
    );
  }
}

// decorations
final componentDeco = BoxDecoration(
  color: Color(accentblue),
  borderRadius: BorderRadius.circular(10),
  boxShadow: [
    // get the proper color
    BoxShadow(
      color: const Color.fromARGB(255, 21, 26, 36),
      blurRadius: 5,
      offset: Offset(0, 2),
    ),
  ],
);

final itemdeco = BoxDecoration(
  border: Border.all(width: 2, color: Color(boxoutline)),
  borderRadius: BorderRadius.circular(10),
);

final selecteditemdeco = BoxDecoration(
  border: Border.all(width: 2, color: Color(boxoutline)),
  color: Color(boxoutline),
  borderRadius: BorderRadius.circular(10),
);

final buttondeco = OutlinedButton.styleFrom(
  side: BorderSide(color: Color(boxoutline), width: 2),
  backgroundColor: Color(accentblue),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

// misc widgets
class BlankWiget extends StatelessWidget {
  const BlankWiget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 100, width: 200, decoration: itemdeco);
  }
}

class SideBarItem extends StatelessWidget {
  final String text;
  final Icon icon;
  const SideBarItem({super.key, required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: 200,
      decoration: itemdeco,
      child: Row(children: [icon, Text(text)]),
    );
  }
}

// http stuff
Future<List<dynamic>> getData(String path) async {
  var url = Uri.parse('http://localhost:8000/$path');
  final response = await http.get(url);
  //response.statusCode
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(response.statusCode);
  }
}

Future<http.Response> sendData(String path, Map data) {
  return http.post(
    Uri.parse('http://localhost:8000/$path'),
    headers: <String, String>{'Content-Type': 'application/json; chaset=UTF-8'},
    body: jsonEncode(data),
  );
}
