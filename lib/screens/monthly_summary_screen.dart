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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month)),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Transactions:',
                  style: TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${summary.transactionCount}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No categorized transactions available"),
        ),
      );
    }
    
    // Sort categories by amount (descending)
    final sortedCategories = summary.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Generate different colors for categories in the pie chart
    final List<Color> categoryColors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    
    // Map categories to colors
    final Map<String, Color> categoryColorMap = {};
    for (int i = 0; i < sortedCategories.length; i++) {
      categoryColorMap[sortedCategories[i].key] = 
          categoryColors[i % categoryColors.length];
    }
    
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
            // Add a pie chart visualization
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  
                  return Row(
                    children: [
                      // Pie chart (simplified implementation)
                      Container(
                        width: availableWidth * 0.6,
                        child: _buildSimplePieChart(sortedCategories, summary.totalExpenses, categoryColorMap),
                      ),
                      
                      // Chart legend
                      Container(
                        width: availableWidth * 0.4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: sortedCategories.take(5).map((entry) {
                            final categoryName = entry.key;
                            final percentage = summary.totalExpenses > 0
                                ? (entry.value / summary.totalExpenses) * 100
                                : 0;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: categoryColorMap[categoryName],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      categoryName,
                                      style: const TextStyle(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(),
            const Text(
              'Breakdown Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...sortedCategories.map((entry) {
              final categoryName = entry.key;
              final amount = entry.value;
              final percentage = summary.totalExpenses > 0
                  ? (amount / summary.totalExpenses) * 100
                  : 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showCategoryDetails(categoryName, amount),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: categoryColorMap[categoryName],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormat.format(amount),
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(categoryColorMap[categoryName] ?? Colors.red),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${percentage.toStringAsFixed(1)}% of total expenses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'View transactions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 10,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSimplePieChart(List<MapEntry<String, double>> categories, double total, Map<String, Color> colorMap) {
    if (total <= 0) {
      return Container(); // Empty container if no data
    }
    
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: PieChartPainter(categories, total, colorMap),
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

  void _showCategoryDetails(String categoryName, double amount) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // In a real implementation, you would fetch actual transactions for this category
    // from your repository or service
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Text(
                    'Transactions for ${DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month))}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<TransactionMock>>(
                      future: _getMockTransactionsForCategory(categoryName, amount),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No transactions found for this category'),
                          );
                        }
                        
                        final transactions = snapshot.data!;
                        
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            
                            return ListTile(
                              title: Text(transaction.description),
                              subtitle: Text(
                                DateFormat('MMM d, yyyy').format(transaction.date),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                              trailing: Text(
                                currencyFormat.format(transaction.amount),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  // Helper method to generate mock transactions
  Future<List<TransactionMock>> _getMockTransactionsForCategory(String category, double totalAmount) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Generate 5-10 random transactions
    final count = 5 + (category.length % 6); // Use category length to make it deterministic
    final transactions = <TransactionMock>[];
    
    // List of mock descriptions based on category
    final descriptions = _getMockDescriptionsForCategory(category);
    
    double remainingAmount = totalAmount;
    
    for (int i = 0; i < count; i++) {
      // For the last transaction, use the remaining amount
      double amount;
      if (i == count - 1) {
        amount = remainingAmount;
      } else {
        // Use a random amount between 10-30% of the remaining total
        final percentage = 0.1 + (0.2 * (i / count));
        amount = remainingAmount * percentage;
        remainingAmount -= amount;
      }
      
      // Create a random date within the month
      final day = 1 + (i * 28 ~/ count); // Distribute across the month
      final date = DateTime(widget.year, widget.month, day);
      
      transactions.add(
        TransactionMock(
          description: descriptions[i % descriptions.length],
          amount: amount,
          date: date,
          category: category,
        ),
      );
    }
    
    // Sort by date
    transactions.sort((a, b) => b.date.compareTo(a.date));
    
    return transactions;
  }
  
  // Helper method to get mock descriptions based on category
  List<String> _getMockDescriptionsForCategory(String category) {
    final Map<String, List<String>> categoryDescriptions = {
      'Groceries': [
        'SuperMarket Purchase', 
        'Local Grocery Store', 
        'Fresh Produce Market',
        'Organic Foods',
        'Bulk Food Shopping',
        'Weekly Grocery Run'
      ],
      'Rent': [
        'Monthly Rent Payment', 
        'Apartment Fee',
        'Housing Payment',
        'Rent Transfer'
      ],
      'Transportation': [
        'Gas Station', 
        'Public Transit Pass', 
        'Uber Ride',
        'Taxi Service',
        'Car Maintenance',
        'Parking Fee'
      ],
      'Dining': [
        'Restaurant Dinner', 
        'Cafe Purchase', 
        'Fast Food Lunch',
        'Food Delivery',
        'Coffee Shop'
      ],
      'Entertainment': [
        'Movie Tickets', 
        'Concert Tickets', 
        'Streaming Service',
        'Game Purchase',
        'Theme Park Entry'
      ],
      'Utilities': [
        'Electric Bill', 
        'Water Bill', 
        'Internet Service',
        'Phone Bill',
        'Gas Bill'
      ],
      'Healthcare': [
        'Pharmacy Purchase', 
        'Doctor Visit', 
        'Health Insurance',
        'Dental Appointment',
        'Eyewear Purchase'
      ],
      'Shopping': [
        'Clothing Store', 
        'Online Shop', 
        'Department Store',
        'Electronics Purchase',
        'Home Goods'
      ],
    };
    
    // Find the most appropriate category key
    String bestMatch = 'Other';
    for (final key in categoryDescriptions.keys) {
      if (category.contains(key) || key.contains(category)) {
        bestMatch = key;
        break;
      }
    }
    
    // Return descriptions for the matched category, or generic ones
    return categoryDescriptions[bestMatch] ?? [
      'Payment for $category',
      '$category Purchase',
      '$category Service',
      '$category Monthly Fee',
      '$category Subscription'
    ];
  }
}

class TransactionMock {
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String? subcategory;

  TransactionMock({
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.subcategory,
  });
}

class PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> categories;
  final double total;
  final Map<String, Color> colorMap;
  
  PieChartPainter(this.categories, this.total, this.colorMap);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 : size.height / 2;
    
    double startAngle = 0;
    
    for (final category in categories) {
      final sweepAngle = (category.value / total) * 2 * 3.14159;
      final paint = Paint()
        ..color = colorMap[category.key] ?? Colors.grey
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
    
    // Draw a white circle in the middle for a donut chart effect
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.6, innerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 