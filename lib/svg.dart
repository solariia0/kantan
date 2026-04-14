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

//
class StrokeInfo {
  final Path path;
  final Rect bounds;
  final bool highlight;
  final String elementId;

  StrokeInfo({
    required this.path,
    required this.bounds,
    required this.highlight,
    required this.elementId,
  });
}

List<StrokeInfo> buildStrokes(Map paths, Size size) {
  List<StrokeInfo> strokeInfos = [];

  for (final element in paths.entries) {
    final highlight = element.value['highlight'] as bool;
    final elementId = element.key;

    for (var pathElement in element.value['paths']) {
      final d = pathElement.getAttribute('d');
      if (d != null) {
        final path = parseSvgPathData(d);

        final bounds = path.getBounds();
        final scaleX = size.width / bounds.width;
        final scaleY = size.height / bounds.height;
        final matrix = Matrix4.identity()
          ..scale(scaleX, scaleY)
          ..translate(-bounds.left, -bounds.top);
        path.transform(matrix.storage);

        strokeInfos.add(StrokeInfo(
          path: path,
          bounds: path.getBounds(),
          highlight: highlight,
          elementId: elementId,
        ));
      }
    }
  }

  return strokeInfos;
}

class KanjiSVGDrag extends StatelessWidget {
  final Map paths;

  const KanjiSVGDrag({super.key, required this.paths});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        final strokeInfos = buildStrokes(paths, size);

        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: KanjiPainter(paths: paths),
            ),
            ...strokeInfos.map((stroke) {
              return Positioned(
                left: stroke.bounds.left,
                top: stroke.bounds.top,
                width: stroke.bounds.width,
                height: stroke.bounds.height,
                child: DragTarget<String>(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      color: stroke.highlight
                          ? Colors.red.withOpacity(0.2)
                          : Colors.transparent,
                    );
                  },
                  onAccept: (data) {
                    //print(
                      //  "Dropped $data on stroke ${stroke.elementId}"); 
                    // handle logic here
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}