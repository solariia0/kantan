import 'package:kantan/main.dart';
import 'package:xml/xml.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

Map parseKanji(XmlDocument kanjivg, String id, List radicals) {
  final kanji = kanjivg
      .findAllElements('kanji')
      .firstWhere((e) => e.getAttribute('id') == id)
      .findAllElements('g');

  List kanjiElements = []; // delete if not used
  Map paths = {};

  for (var element in kanji) {
    String? elem = element.getAttribute('kvg:element');
    if (elem != null) {
      kanjiElements.add(elem);
      if (radicals.contains(elem)) {
        paths[elem] = {
          'paths': element.findAllElements('path'),
          'highlight': true,
        };
      } else {
        paths[elem] = {
          'paths': element.findAllElements('path'),
          'highlight': false,
        };
      }
    }
  }


  return paths;
}

class KanjiPainter extends CustomPainter {
  final Map paths;
  

  const KanjiPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    for (final element in paths.entries) {
      final paint = Paint()
        ..color = element.value['highlight'] ? Color(boxoutline) : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (var pathElement in element.value['paths']) {
        final d = pathElement.getAttribute('d');
        if (d != null) {
          final path = parseSvgPathData(d);
          canvas.drawPath(path, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

class KanjiSVG extends StatelessWidget {
  final Map paths;
  const KanjiSVG({super.key, required this.paths});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(200, 200),
      painter: KanjiPainter(paths: paths),
    );
  }
}

