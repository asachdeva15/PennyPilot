import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/monthly_summary.dart';
import '../providers/monthly_summary_provider.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/monthly_stat_card.dart';
import '../services/transaction_summary_service.dart';
import '../repositories/summary_repository.dart';
import '../repositories/transaction_repository.dart';
import '../widgets/summary_card.dart';
import '../repositories/file_summary_repository.dart';
import '../services/file_service.dart';
import '../repositories/file_transaction_repository.dart';

class MonthlySummaryScreen extends StatefulWidget {
  final int year;
  final int month;

  const MonthlySummaryScreen({
    Key? key,
    required this.year,
    required this.month,
  }) : super(key: key);

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late final TransactionSummaryService _summaryService;
  bool _isLoading = true;
  MonthlyTransactionSummary? _summary;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final fileService = FileService();
    _summaryService = TransactionSummaryService(
      transactionRepository: FileTransactionRepository(fileService: fileService),
      summaryRepository: FileSummaryRepository(
        fileService: fileService,
      ),
    );
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final summary = await _summaryService.getMonthlySummary(
        widget.year,
        widget.month,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load summary: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSummary() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final summary = await _summaryService.generateMonthlySummary(
        widget.year,
        widget.month,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to refresh summary: $e';
        _isLoading = false;
      });
    }
  }

  String _getMonthYearString() {
    final dateTime = DateTime(widget.year, widget.month);
    return DateFormat('MMMM yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary: ${_getMonthYearString()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSummary,
            tooltip: 'Regenerate Summary',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
              : _buildSummaryContent(),
    );
  }

  Widget _buildSummaryContent() {
    if (_summary == null) {
      return const Center(child: Text('No summary available'));
    }

    return RefreshIndicator(
      onRefresh: _refreshSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(),
            const SizedBox(height: 16),
            _buildTopExpensesCard(),
            const SizedBox(height: 16),
            _buildCategoryBreakdownCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final summary = _summary!;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildOverviewRow(
              'Total Income:',
              currencyFormat.format(summary.totalIncome),
              Colors.green,
            ),
            _buildOverviewRow(
              'Total Expenses:',
              currencyFormat.format(summary.totalExpenses),
              Colors.red,
            ),
            const Divider(),
            _buildOverviewRow(
              'Net Savings:',
              currencyFormat.format(summary.netSavings),
              summary.netSavings >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpensesCard() {
    final summary = _summary!;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    if (summary.topExpenseCategories.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No expense data available for this month'),
        ),
      );
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...summary.topExpenseCategories.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            category.subcategory != null
                                ? '${category.category} > ${category.subcategory}'
                                : category.category,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currencyFormat.format(category.amount),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: category.percentageOfTotal / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    Text(
                      '${category.percentageOfTotal.toStringAsFixed(1)}% of total expenses',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (summary.topExpenseCategories.last != category) const Divider(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final summary = _summary!;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    if (summary.categoryBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort categories by amount (descending)
    final sortedCategories = summary.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...sortedCategories.map((entry) {
              final categoryName = entry.key;
              final amount = entry.value;
              final percentage = summary.totalExpenses > 0
                  ? (amount / summary.totalExpenses) * 100
                  : 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        categoryName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(amount),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final summary = _summary!;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated: ${dateFormat.format(summary.generatedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 