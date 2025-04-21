import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/yearly_summary.dart';
import '../services/transaction_summary_service.dart';
import '../repositories/file_summary_repository.dart';
import '../repositories/file_transaction_repository.dart';
import '../services/file_service.dart';
import 'monthly_summary_screen.dart';
import 'home_screen.dart';

class YearlySummaryScreen extends StatefulWidget {
  final int year;

  const YearlySummaryScreen({
    Key? key,
    required this.year,
  }) : super(key: key);

  @override
  State<YearlySummaryScreen> createState() => _YearlySummaryScreenState();
}

class _YearlySummaryScreenState extends State<YearlySummaryScreen> {
  late final TransactionSummaryService _summaryService;
  bool _isLoading = true;
  YearlySummary? _yearlySummary;
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
    _loadYearlySummary();
  }

  Future<void> _loadYearlySummary() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Load the comprehensive data instead of just the summary
      final comprehensiveData = await _summaryService.getComprehensiveYearlyData(widget.year);
      
      // Extract the yearly summary from the comprehensive data
      final summary = comprehensiveData.yearlySummary;

      setState(() {
        _yearlySummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load yearly summary: $e';
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

      // Regenerate all summaries
      await _summaryService.regenerateAllSummaries();
      
      // Generate the comprehensive data (which will also generate the yearly summary)
      final comprehensiveData = await _summaryService.getComprehensiveYearlyData(widget.year);

      setState(() {
        _yearlySummary = comprehensiveData.yearlySummary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to refresh summary: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToMonth(int month) {
    print('Navigating to month: $month');
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MonthlySummaryScreen(
            year: widget.year,
            month: month,
          ),
        ),
      );
      print('Navigation successful');
    } catch (e) {
      print('Navigation error: $e');
      // Show a snackbar to notify the user of the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error navigating to month details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFE68A00),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'LOGO.png',
                    width: 100,
                    height: 89,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PennyPilot',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // We're already on the home screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_chart),
              title: const Text('Add Transactions'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('${widget.year} Financial Summary'),
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
    if (_yearlySummary == null) {
      return const Center(
        child: Text('No data available for this year'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearOverviewCard(),
            const SizedBox(height: 16),
            _buildTopExpensesCard(),
            const SizedBox(height: 16),
            _buildMonthlyBreakdownCard(),
            const SizedBox(height: 16),
            _buildCategoryBreakdownCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildYearOverviewCard() {
    final summary = _yearlySummary!;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yearly Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildOverviewRow(
              'Total Income:',
              currencyFormat.format(summary.totalYearlyIncome),
              Colors.green,
            ),
            _buildOverviewRow(
              'Total Expenses:',
              currencyFormat.format(summary.totalYearlyExpenses),
              Colors.red,
            ),
            const Divider(),
            _buildOverviewRow(
              'Net Savings:',
              currencyFormat.format(summary.yearlyNetSavings),
              summary.yearlyNetSavings >= 0 ? Colors.green : Colors.red,
              isBold: true,
            ),
            const SizedBox(height: 8),
            _buildSavingsRateRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsRateRow() {
    final summary = _yearlySummary!;
    final savingsRate = summary.totalYearlyIncome > 0 
        ? (summary.yearlyNetSavings / summary.totalYearlyIncome) * 100 
        : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Savings Rate:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${savingsRate.toStringAsFixed(1)}%',
            style: TextStyle(
              color: savingsRate >= 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
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
    final summary = _yearlySummary!;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    if (summary.topYearlyExpenses.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No expense data available for this year'),
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
            ...summary.topYearlyExpenses.map((category) {
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
                    if (summary.topYearlyExpenses.last != category) const Divider(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdownCard() {
    final summary = _yearlySummary!;
    final currencyFormat = NumberFormat.currency(symbol: '€', decimalDigits: 2);
    final months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            
            // Months list
            Column(
              children: List.generate(months.length, (index) {
                final month = months[index];
                final monthName = monthNames[index];
                final monthData = summary.monthlySummaries[month];
                
                // Skip months with no data
                if (monthData == null) {
                  return const SizedBox.shrink();
                }
                
                // Use GestureDetector to make the entire row tappable
                return GestureDetector(
                  onTap: () {
                    print('Month tapped: $monthName');
                    _navigateToMonth(month);
                  },
                  // Highlight effect when tapped
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    color: Colors.transparent, // Important for tap detection
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month header with highlight color
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE68A00),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                monthName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        
                        // Financial details
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              // Income
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Income',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(monthData.totalIncome),
                                      style: const TextStyle(
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Expenses
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Expenses',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      currencyFormat.format(monthData.totalExpenses),
                                      style: const TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Transactions count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Transactions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${monthData.transactionCount}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Total
                        Container(
                          width: double.infinity,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Text(
                            'Total: ${currencyFormat.format(monthData.netSavings)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: monthData.netSavings >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                        
                        const Divider(),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownCard() {
    final summary = _yearlySummary!;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    if (summary.categoryTotals.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No categorized transactions available"),
        ),
      );
    }
    
    // Sort categories by amount (descending)
    final sortedCategories = summary.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expenses by Category',
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
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currencyFormat.format(amount),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total expenses',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (sortedCategories.last != entry) const Divider(),
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            ElevatedButton.icon(
              icon: const Icon(Icons.pie_chart),
              label: const Text('View Detailed Breakdown'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE68A00),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Future enhancement: show detailed category breakdown
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Feature coming in Phase 4'))
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final summary = _yearlySummary!;
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