import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:kantan/settings.dart';
import 'kanji_page.dart';
import 'package:kantan/quiz_page.dart';

void main() {
  runApp(const MainApp());
}

late XmlDocument kanjivg;
Map<String, String> kanjiToId = {};

// themes and colors
final int boxoutline = 0xFF4D92B4;
final int blueDarker = 0xFF305B70;
//final int accentblue = 0xFF12182B;
//final int bg = 0xFF222A46; //0xFF242B3F

final int bg = 0xFF222A46;
final int accentblue = 0xFF222A46;

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<void> extractKanjiSvg() async {
    final kanjivgpath = 'assets/kanjivg-20250816.xml';
    final kanjivgxml = await rootBundle.loadString(kanjivgpath);
    kanjivg = XmlDocument.parse(kanjivgxml);

    // kanjiid mapping
    final kanjiElement = kanjivg.findAllElements('kanji');
    for (var element in kanjiElement) {
      final idAttr = element.getAttribute('id');
      final id = idAttr?.split(':').last;

      final gElement = element.getElement('g');
      if (gElement != null) {
        final kanjiChar = gElement.getAttribute('kvg:element');
        if (kanjiChar != null && id != null) {
          kanjiToId[kanjiChar] = id;
        }
      }
    }

    print('done mapping');
  }

  @override
  void initState() {
    super.initState();
    extractKanjiSvg();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kantan',
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white, // light theme maybe?
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            alignment: Alignment.centerLeft,
            side: BorderSide(color: Color(boxoutline), width: 1),
            backgroundColor: Color(accentblue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
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
    SettingsPage(),
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

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  List<Widget> streakCircles = [];
  String streakText = '';

  Future<void> _updateStreakWidget() async {
    List<dynamic> data = await getData('streak/1');

    setState(() {
    streakText = "${data.length} Day streak";

    for (var day in data) {
      streakCircles.add(
        Icon(
          Icons.circle,
          color: day['practiced'] ? Colors.indigoAccent : Colors.blueAccent,
        ),
      );
    }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateStreakWidget();
  }

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
          Container(
            // home button
            margin: EdgeInsets.all(5),
            width: 200, // this may break idk
            child: OutlinedButton.icon(
              onPressed: () => {pageNotifier.value = 0},
              label: Text('Home'),
              icon: Icon(Icons.home),
            ),
          ),
          Container(
            margin: EdgeInsets.all(5),
            padding: EdgeInsets.all(10),
            decoration: itemdeco,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.circle,
                        size: 40,
                        color: Colors.indigoAccent,
                      ),
                    ),
                    Text(streakText),
                  ],
                ),
                Row(children: streakCircles),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                    decoration: itemdeco,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Kanji Learned', textAlign: TextAlign.center),
                        // futurue builder
                        FutureBuilder(
                          future: getData('user_kanji/1/total'),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                '${snapshot.data![0]['count']}',
                                style: TextStyle(fontSize: 35),
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                '${snapshot.error}',
                                style: TextStyle(fontSize: 35),
                              );
                            } else {
                              return CircularProgressIndicator();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.all(5),
                    padding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                    decoration: itemdeco,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Vocab Learned', textAlign: TextAlign.center),
                        // futurue builder
                        Text('20', style: TextStyle(fontSize: 35)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.all(3),
            child: OutlinedButton(
              onPressed: () => {pageNotifier.value = 1},

              child: Text('Manage Kanji'),
            ),
          ),
          Container(
            // progress bar
            margin: EdgeInsets.all(5),
            height: 50,
            width: 200,
            decoration: itemdeco,
            child: Column(
              children: [
                // all fetched level and mode and known
                Text('N3 Progress'),
                Stack(
                  children: [
                    Container(decoration: itemdeco, height: 20, width: 150),
                    FutureBuilder(
                      future: getData('total/1'),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Color(boxoutline),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: SizedBox(
                              height: 20,
                              width:
                                  snapshot.data![0]["learned kanji"] *
                                  150 /
                                  100,
                            ),
                          );
                        } else {
                          return LinearProgressIndicator();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Spacer(),
          Container(
            margin: EdgeInsets.all(5),
            width: 200,
            child: OutlinedButton.icon(
              onPressed: () => {pageNotifier.value = 2},
              label: Text('Settings'),
              icon: Icon(Icons.settings),
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
          Text('Current mode:', style: TextStyle(fontSize: 25)),
          Text('JLPT - N3', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

// decorations
final componentDeco = BoxDecoration(
  color: Color(accentblue),
  borderRadius: BorderRadius.circular(5),
  boxShadow: [
    BoxShadow(color: Colors.black, blurRadius: 3, offset: Offset(0, 3)),
  ],
);

final itemdeco = BoxDecoration(
  border: Border.all(width: 1, color: Color(boxoutline)),
  borderRadius: BorderRadius.circular(10),
);

final selecteditemdeco = BoxDecoration(
  border: Border.all(width: 1, color: Color(boxoutline)),
  color: Color(boxoutline),
  borderRadius: BorderRadius.circular(10),
);

// http stuff
Future<List<dynamic>> getData(String path) async {
  var url = Uri.parse('http://localhost:8000/$path');
  final response = await http.get(url);
  //response.statusCode
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception();
  }
}

Future<http.Response> sendData(String path, Map data) {
  return http.post(
    Uri.parse('http://localhost:8000/$path'),
    headers: <String, String>{'Content-Type': 'application/json; chaset=UTF-8'},
    body: jsonEncode(data),
  );
}
