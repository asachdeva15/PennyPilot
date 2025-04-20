import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final Map<String, double> categoryAmounts;
  final double totalAmount;

  const CategoryBreakdownChart({
    Key? key,
    required this.categoryAmounts,
    required this.totalAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (categoryAmounts.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Create a list of PieChartSectionData from the categoryAmounts
    final sections = <PieChartSectionData>[];
    int colorIndex = 0;
    
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];
    
    categoryAmounts.forEach((category, amount) {
      final percentage = (amount / totalAmount) * 100;
      
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      );
      colorIndex++;
    });

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: categoryAmounts.entries.map((entry) {
            final index = categoryAmounts.entries.toList().indexOf(entry);
            return _buildLegendItem(
              entry.key,
              colors[index % colors.length],
              isDarkMode,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
} 