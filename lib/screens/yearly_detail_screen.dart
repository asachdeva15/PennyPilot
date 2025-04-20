import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/yearly_data.dart';

class YearlyDetailScreen extends StatelessWidget {
  final YearlyData yearlyData;
  final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');

  YearlyDetailScreen({super.key, required this.yearlyData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${yearlyData.year} Summary'),
        backgroundColor: const Color(0xFFE68A00),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 24),
            _buildCategoriesSection(),
            const SizedBox(height: 24),
            _buildMonthlyBreakdownSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yearly Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Total Income', yearlyData.summary.totalIncome, Colors.green),
            _buildSummaryRow('Total Expenses', yearlyData.summary.totalExpenses, Colors.red),
            _buildSummaryRow('Total Savings', yearlyData.summary.totalSavings, Colors.blue),
            _buildSummaryRow('Transactions', yearlyData.summary.transactionCount.toDouble(), Colors.grey),
            
            const SizedBox(height: 16),
            Text(
              'Last Updated: ${yearlyData.summary.lastUpdated != null 
                ? DateFormat('yyyy-MM-dd HH:mm').format(yearlyData.summary.lastUpdated!) 
                : 'Not available'}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (yearlyData.summary.categoryTotals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No category data available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Spending by Category',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...yearlyData.summary.categoryTotals.entries
                  .map((entry) {
                    final category = entry.key;
                    final amount = entry.value.abs(); // Display as positive number
                    return _buildSummaryRow(
                      category, 
                      amount, 
                      _getCategoryColor(category)
                    );
                  })
                  .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBreakdownSection() {
    if (yearlyData.months.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No monthly data available'),
        ),
      );
    }

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Breakdown',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        ...yearlyData.months.entries.map((entry) {
          final month = entry.key;
          final monthData = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        monthNames[month - 1],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total: ${currencyFormat.format(monthData.summary.totalSavings)}',
                        style: TextStyle(
                          color: monthData.summary.totalSavings >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMonthSummaryItem('Income', monthData.summary.totalIncome, Colors.green),
                      _buildMonthSummaryItem('Expenses', monthData.summary.totalExpenses, Colors.red),
                      _buildMonthSummaryItem('Transactions', monthData.summary.transactionCount.toDouble(), Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList().reversed.toList(),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            label == 'Transactions' ? value.toInt().toString() : currencyFormat.format(value),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryItem(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          label == 'Transactions' ? value.toInt().toString() : currencyFormat.format(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper method to get a color for each category
  Color _getCategoryColor(String category) {
    // Map categories to specific colors
    final Map<String, Color> categoryColors = {
      'Fundamentals': Colors.blue,
      'Lifestyle': Colors.purple,
      'Income': Colors.green,
      'Uncategorized': Colors.grey,
    };
    
    // Return the mapped color or a default
    return categoryColors[category] ?? Colors.orange;
  }
} 