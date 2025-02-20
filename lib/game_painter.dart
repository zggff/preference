import 'dart:collection';
import 'dart:ui';
import 'rotated_text.dart';

import 'package:format/format.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:preference/types.dart';

class Game3Painter extends CustomPainter {
  final double offset1 = 120;
  final double offset2 = 160;
  final GameState s;
  Game3Painter(
    this.s,
  );

  @override
  void paint(Canvas canvas, Size size) {
    paintLayout(canvas, size);
    paintNames(canvas, size);
    paintVals(canvas, size);
    paintBirds(canvas, size);
  }

  void drawList(Canvas canvas, Size size, double dist, Iterable<int> varsList,
      {double angleAdjustment = 0}) {
    var center = size / 2.0;
    for (var (i, val) in varsList.indexed) {
      if (val == 0) {
        continue;
      }

      final rayAngle = math.pi + math.pi / 2 * i + angleAdjustment;
      final textAngle = math.pi * i / 2;

      var start = Offset(center.width + dist * math.sin(rayAngle),
          center.height - dist * math.cos(rayAngle));

      var textPainter = TextPainter(
        text: TextSpan(
            text: "{}".format(val),
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
            )),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      canvas.drawRotatedText(
          pivot: start, textPainter: textPainter, angle: textAngle);
    }
  }

  void paintVals(Canvas canvas, Size size) {
    var center = size / 2.0;
    var dist1 = (center.height - offset1 - 20);
    drawList(canvas, size, dist1, s.players.values.map((v) => v.pos));
    var dist2 = (center.height - offset2 - 20);
    drawList(canvas, size, dist2, s.players.values.map((v) => v.neg));

    var names = s.players.keys.toList();
    var vistLeft = s.players.values.indexed
        .map((v) => v.$2.vist[names[((v.$1 + 1) % names.length)]]!);
    var vistTop = s.players.values.indexed
        .map((v) => v.$2.vist[names[((v.$1 + 2) % names.length)]]!);
    var dist = (center.height - offset1 + 30);
    if (s.players.length == 3) {
      var angle = 22.5 * math.pi / 180;
      drawList(canvas, size, dist / math.cos(angle), vistLeft,
          angleAdjustment: angle);
      drawList(canvas, size, dist / math.cos(angle), vistTop,
          angleAdjustment: -angle);
    } else {
      var angle = 30 * math.pi / 180;

      var vistRight = s.players.values.indexed
          .map((v) => v.$2.vist[names[((v.$1 + 3) % names.length)]]!);
      drawList(canvas, size, dist / math.cos(angle), vistLeft,
          angleAdjustment: angle);
      drawList(canvas, size, dist / math.cos(angle), vistRight,
          angleAdjustment: -angle);
      drawList(
        canvas,
        size,
        dist,
        vistTop,
      );
    }
  }

  void paintBirds(Canvas canvas, Size size) {
    var center = Offset(size.width / 2, size.height / 2);
    var degreeOffset = (s.players.length == 4 ? 20 : 5) * (math.pi / 180);
    for (var (i, val) in s.players.values.indexed) {
      var paint = Paint()
        ..color = Colors.black
        ..strokeWidth = 2;

      var dist = (center.dx - offset1) / math.cos(degreeOffset);
      var angle = (i + 1) * math.pi / 2;
      var lineOffset = Offset(math.cos(angle), math.sin(angle)) * offset1;
      var startLeft = center +
          Offset(math.cos(angle + degreeOffset),
                  math.sin(angle + degreeOffset)) *
              dist;
      var startRight = center +
          Offset(math.cos(angle - degreeOffset),
                  math.sin(angle - degreeOffset)) *
              dist;

      canvas.drawPoints(
          PointMode.lines,
          [
            startLeft,
            startLeft + lineOffset,
            startRight,
            startRight + lineOffset
          ],
          paint);

      var spacing = 10.0;
      var count = offset1 ~/ spacing;

      var start = startLeft;
      var offsetMult = 0;
      for (var (j, bon) in val.bonuses.indexed) {
        if (j >= count) {
          offsetMult = 0;
          start = startRight;
        }
        paint.color = bon == Bonus.bird ? Colors.black : Colors.red;
        var bonusStart = start +
            Offset(math.cos(angle), math.sin(angle)) * (spacing * offsetMult);
        offsetMult++;

        if (j < val.bonusesSpent) {
          canvas.drawPoints(
              PointMode.polygon,
              [
                bonusStart +
                    Offset(math.cos(angle + math.pi / 4),
                            math.sin(angle + math.pi / 4)) *
                        20,
                bonusStart,
                bonusStart +
                    Offset(math.cos(angle - math.pi / 4),
                            math.sin(angle - math.pi / 4)) *
                        20
              ],
              paint);
        } else {
          canvas.drawPoints(
              PointMode.lines,
              [
                bonusStart,
                bonusStart +
                    Offset(math.cos(angle + math.pi / 4),
                            math.sin(angle + math.pi / 4)) *
                        20
              ],
              paint);
        }
      }
    }
  }

  void paintLayout(Canvas canvas, Size size) {
    var center = Offset(size.width / 2, size.height / 2);
    var paint = Paint()..color = Colors.black12;
    canvas.drawRect(Rect.largest, paint);

    paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, 0), center, paint);
    canvas.drawLine(Offset(0, size.height), center, paint);

    if (s.players.length == 3) {
      canvas.drawLine(center, Offset(size.width, center.dy), paint);

      canvas.drawPoints(
          PointMode.polygon,
          [
            Offset(size.width, offset1),
            Offset(offset1, offset1),
            Offset(offset1, size.height - offset1),
            Offset(size.width, size.height - offset1)
          ],
          paint);
      canvas.drawPoints(
          PointMode.polygon,
          [
            Offset(size.width, offset2),
            Offset(offset2, offset2),
            Offset(offset2, size.height - offset2),
            Offset(size.width, size.height - offset2)
          ],
          paint);
    } else {
      canvas.drawLine(Offset(0, 0), (Offset(size.width, size.height)), paint);
      canvas.drawLine(Offset(size.width, 0), (Offset(0, size.height)), paint);

      canvas.drawPoints(
          PointMode.polygon,
          [
            Offset(offset1, offset1),
            Offset(size.width - offset1, offset1),
            Offset(size.width - offset1, size.height - offset1),
            Offset(offset1, size.height - offset1),
            Offset(offset1, offset1)
          ],
          paint);

      canvas.drawPoints(
          PointMode.polygon,
          [
            Offset(offset2, offset2),
            Offset(size.width - offset2, offset2),
            Offset(size.width - offset2, size.height - offset2),
            Offset(offset2, size.height - offset2),
            Offset(offset2, offset2)
          ],
          paint);
    }
  }

  void paintNames(Canvas canvas, Size size) {
    var severityColor = [Colors.green, Colors.orange, Colors.red];
    var center = Offset(size.width, size.height) / 2;

    for (var (i, name) in s.players.keys.indexed) {
      final angle = math.pi * i / 2;
      final mult =
          Offset(math.cos(angle + math.pi / 2), math.sin(angle + math.pi / 2));
      final nameStyle = TextStyle(
        color: name == s.dealer.current
            ? severityColor[s.dealerConsequitive]
            : Colors.black,
        fontSize: 40,
      );
      final namePainter = TextPainter(
        text: TextSpan(
          text: "{}".format(name),
          style: nameStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      canvas.drawRotatedText(
          pivot: center + mult * 40, textPainter: namePainter, angle: angle);

      final color = s.res[name] == 0
          ? Colors.black
          : s.res[name]! < 0
              ? Colors.red
              : Colors.green;

      final winStyle = TextStyle(
        color: color,
        fontSize: 25,
      );

      final winPainter = TextPainter(
        text: TextSpan(
          text: "{}".format(s.res[name]!),
          style: winStyle,
        ),
        textDirection: TextDirection.ltr,
      );

      winPainter.layout();
      final double winDist = 100;

      var dim = [
        math.max(winPainter.width + 20, winPainter.height + 20),
        winPainter.height + 20
      ];

      canvas.drawOval(
          Rect.fromCenter(
              center: center + mult * winDist,
              width: dim[i % 2],
              height: dim[(i + 1) % 2]),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawRotatedText(
          pivot: center + mult * winDist,
          textPainter: winPainter,
          angle: angle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
