import 'package:flutter/material.dart';

class WeatherGraphPainter extends CustomPainter {
  final List<double> temperatures;
  final List<double> minMax;
  final Color color;
  final bool showLabels;

  WeatherGraphPainter({
    required this.temperatures,
    required this.minMax,
    required this.color,
    this.showLabels = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (temperatures.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double stepX = size.width / (temperatures.length - 1);

    // Calculate vertical scaling
    // Add some padding to min/max so the curve doesn't touch the edges
    double minTemp = minMax[0];
    double maxTemp = minMax[1];
    double range = maxTemp - minTemp;
    if (range == 0) range = 1;

    double normalize(double temp) {
      // Invert Y axis because canvas 0 is top
      return size.height -
          ((temp - minTemp) / range * size.height * 0.6 + size.height * 0.2);
    }

    // Move to first point
    path.moveTo(0, normalize(temperatures[0]));

    // Draw smooth curve using cubic bezier
    for (int i = 0; i < temperatures.length - 1; i++) {
      double p1x = i * stepX;
      double p1y = normalize(temperatures[i]);
      double p2x = (i + 1) * stepX;
      double p2y = normalize(temperatures[i + 1]);

      // Control points for smooth curve
      double c1x = p1x + stepX / 2;
      double c1y = p1y;
      double c2x = p2x - stepX / 2;
      double c2y = p2y;

      path.cubicTo(c1x, c1y, c2x, c2y, p2x, p2y);
    }

    // Draw the main line
    canvas.drawPath(path, paint);

    // Draw fill gradient
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
      stops: const [0.0, 1.0],
    );

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant WeatherGraphPainter oldDelegate) {
    return oldDelegate.temperatures != temperatures ||
        oldDelegate.color != color;
  }
}
