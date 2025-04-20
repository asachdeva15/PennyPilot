import 'package:flutter/material.dart';
import '../models/bank_mapping.dart';

class CSVPreviewDialog extends StatelessWidget {
  final List<List<dynamic>> rows;
  final String? selectedBank;
  final BankMapping? mapping;

  const CSVPreviewDialog({
    super.key, 
    required this.rows,
    required this.selectedBank,
    required this.mapping,
  });

  @override
  Widget build(BuildContext context) {
    // Determine max columns for DataTable structure
    final int maxColumns = rows.fold<int>(
      0, 
      (max, row) => row.length > max ? row.length : max
    );

    // Show header row if we have a mapping
    final int? headerRowIndex = mapping?.headerRowIndex;
    
    return AlertDialog(
      title: const Text('CSV Preview'),
      insetPadding: const EdgeInsets.all(10.0),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bank information
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Bank: ${selectedBank ?? "Unknown"}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            // Table header information
            if (headerRowIndex != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Using header row: Row ${headerRowIndex + 1}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),

            // Scrollable CSV Preview Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 0,
                      dataRowMinHeight: 30, 
                      dataRowMaxHeight: 40,
                      border: TableBorder.all(width: 0.5, color: Colors.grey.shade700),
                      columns: [
                        const DataColumn(label: Text('#')),
                        for (int i = 0; i < maxColumns; i++)
                          DataColumn(label: Text('Col ${i + 1}')),
                      ],
                      rows: rows.asMap().entries.map((entry) {
                        int rowIndex = entry.key;
                        List<dynamic> row = entry.value;
                        
                        // Highlight header row
                        bool isHeader = rowIndex == headerRowIndex;
                        
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              if (isHeader) {
                                return Theme.of(context).highlightColor;
                              }
                              return null;
                            }
                          ),
                          cells: [
                            DataCell(
                              Text(
                                '${rowIndex + 1}',
                                style: TextStyle(
                                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal
                                )
                              )
                            ),
                            for (int i = 0; i < maxColumns; i++)
                              DataCell(
                                Text(
                                  i < row.length ? row[i].toString() : '',
                                  style: TextStyle(
                                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal
                                  )
                                )
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false);
          },
        ),
        TextButton(
          child: const Text('Import Transactions'),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
} 