import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double amount;
  final bool isPositive;
  final String? subtitle;

  const SummaryCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.amount,
    this.isPositive = true,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final formattedAmount = currencyFormat.format(amount);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(
                    icon,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              formattedAmount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SummaryProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final String? valueLabel;

  const SummaryProgressBar({
    Key? key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.valueLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percent = max > 0 ? value / max : 0.0;
    final percentString = '${(percent * 100).toStringAsFixed(1)}%';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueLabel ?? percentString,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
} 