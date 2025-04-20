import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/monthly_summary.dart';
import 'category_breakdown_chart.dart';
import '../models/category.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  
  const MonthlySummaryCard({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(summary.month),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  currencyFormat.format(summary.totalExpenses),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Income: ${currencyFormat.format(summary.totalIncome)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Savings: ${currencyFormat.format(summary.totalIncome - summary.totalExpenses)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: summary.totalIncome - summary.totalExpenses >= 0 
                  ? Colors.green 
                  : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Expense Breakdown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            CategoryBreakdownChart(
              categoryAmounts: summary.categoryExpenses,
              totalAmount: summary.totalExpenses,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context, 
                  'Transactions', 
                  summary.transactionCount.toString(),
                  Icons.receipt,
                ),
                _buildStatItem(
                  context, 
                  'Avg. Transaction', 
                  currencyFormat.format(summary.averageTransaction),
                  Icons.trending_up,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 