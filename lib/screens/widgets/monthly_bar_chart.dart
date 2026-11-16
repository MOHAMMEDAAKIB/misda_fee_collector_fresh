// lib/screens/widgets/monthly_bar_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../services/analytics.dart';

class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({super.key, required this.data, required this.selected});
  final List<MapEntry<String, num>> data;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final maxV = data.fold<num>(0, (a, e) => e.value > a ? e.value : a);

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(BarChartData(
        maxY: maxV == 0 ? 100 : maxV * 1.15,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                // Month on line 1, amount on line 2 (no tooltip API needed).
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${shortMonth(data[i].key)}\n${money(data[i].value)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].value.toDouble(),
                width: 24,
                borderRadius: BorderRadius.circular(4),
                color: data[i].key == selected
                    ? color
                    : color.withValues(alpha: 0.35),
              ),
            ]),
        ],
      )),
    );
  }
}
