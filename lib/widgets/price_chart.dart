import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PriceChart extends StatelessWidget {
  final List<FlSpot> dataPoints;
  final Color lineColor;

  const PriceChart({
    super.key,
    required this.dataPoints,
    this.lineColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: dataPoints.first.x,
          maxX: dataPoints.last.x,
          minY: _getMinY(),
          maxY: _getMaxY(),
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints,
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  double _getMinY() {
    return dataPoints.map((point) => point.y).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxY() {
    return dataPoints.map((point) => point.y).reduce((a, b) => a > b ? a : b);
  }
}