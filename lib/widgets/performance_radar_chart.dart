import 'package:flutter/material.dart';
import 'dart:math' as math;

class PerformanceRadarChart extends StatelessWidget {
  final List<String> metrics;
  final List<double> values;
  final Color color;
  
  const PerformanceRadarChart({
    Key? key,
    required this.metrics,
    required this.values,
    this.color = Colors.blue,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      child: CustomPaint(
        size: Size.infinite,
        painter: RadarChartPainter(
          metrics: metrics,
          values: values,
          color: color,
        ),
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<String> metrics;
  final List<double> values;
  final Color color;
  