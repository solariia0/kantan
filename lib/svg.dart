import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MainApp());
}

//extract kanjivg manually at some point
final kanjivgpath = 'assets/kanjivg-20250816.xml';

Future<String> extractKanjiSvg(String kanjiId) async {
  final kanjivg = await rootBundle.loadString(kanjivgpath);
  final document = XmlDocument.parse(kanjivg);

  final kanjiElement = document
      .findAllElements('kanji')
      .firstWhere((e) => e.getAttribute('id') == kanjiId);

  //print(kanjiElement.toXmlString());

  return '''
    <svg xmlns="http://www.w3.org/2000/svg"
        xmlns:kvg="http://kanjivg.tagaini.net"
        viewBox="0 0 109 109"
        width="200"
        height="200">
      <style>
        path {
          stroke: black;
          stroke-width: 6;
          fill: none;
        }
      </style>
      ${kanjiElement.innerXml}
    </svg>
    ''';
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'kantan',
      home: Scaffold(
        body: Center(
          child:  FutureBuilder<String>(
            future: extractKanjiSvg('kvg:kanji_06524'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              return SvgPicture.string(snapshot.data!);
            },
          ),
      ),
      ),
    );
  }
}
