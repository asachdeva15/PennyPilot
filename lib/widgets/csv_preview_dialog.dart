import 'package:flutter/material.dart';

class CsvPreviewDialog extends StatefulWidget {
  final List<List<dynamic>> csvData;

  const CsvPreviewDialog({super.key, required this.csvData});

  @override
  State<CsvPreviewDialog> createState() => _CsvPreviewDialogState();
}

class _CsvPreviewDialogState extends State<CsvPreviewDialog> {
  int? _selectedHeaderRowIndex; // 0-based index

  @override
  Widget build(BuildContext context) {
    // Generate row numbers for the header selection dropdown (1-based for display)
    final List<int> rowNumberOptions =
        List<int>.generate(widget.csvData.length, (i) => i + 1);

    // Determine max columns for DataTable structure
    final int maxColumns = widget.csvData
        .fold<int>(0, (max, row) => row.length > max ? row.length : max);

    return AlertDialog(
      title: const Text('CSV Preview & Header Selection'),
      // Use constraints to make dialog larger but not full screen
      insetPadding: const EdgeInsets.all(10.0), // Less padding around
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 8), // Adjust padding
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,   // 90% of screen width
        height: MediaQuery.of(context).size.height * 0.7, // 70% of screen height
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent column from expanding infinitely
          children: [
            // --- Header Row Selection Dropdown ---
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DropdownButtonFormField<int>(
                value: _selectedHeaderRowIndex != null
                    ? _selectedHeaderRowIndex! + 1 // Display 1-based
                    : null,
                hint: const Text('Select Header Row Number'),
                isExpanded: true,
                items: rowNumberOptions.map<DropdownMenuItem<int>>((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('Row $value is Header'),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedHeaderRowIndex = newValue - 1; // Store 0-based index
                    });
                  }
                },
                validator: (value) {
                  if (value == null) return 'Please select the header row';
                  return null;
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
              ),
            ),

            // --- Scrollable CSV Preview Table ---
            Expanded( // Make the table take available space
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView( // Vertical scroll
                  child: SingleChildScrollView( // Horizontal scroll
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowHeight: 0, // No header for the table itself
                      dataRowMinHeight: 30, dataRowMaxHeight: 40,
                      border: TableBorder.all(width: 0.5, color: Colors.grey.shade700), // Add cell borders
                      columns: [
                        const DataColumn(label: Text('#')), // Row number column
                        // Add dummy columns
                        for (int i = 0; i < maxColumns; i++)
                          DataColumn(label: Text('Col ${i + 1}')),
                      ],
                      rows: widget.csvData.asMap().entries.map((entry) {
                        int rowIndex = entry.key;
                        List<dynamic> row = entry.value;
                        // Highlight the selected header row
                        bool isSelected = rowIndex == _selectedHeaderRowIndex;
                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                              (Set<MaterialState> states) {
                            if (isSelected) {
                              return Theme.of(context).highlightColor;
                            }
                            return null; // Use default value for other states and rows.
                          }),
                          cells: [
                            DataCell(Text('${rowIndex + 1}',
                                style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
                            // Fill cells
                            for (int i = 0; i < maxColumns; i++)
                              DataCell(Text(i < row.length ? row[i].toString() : '',
                                  style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))),
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
            Navigator.of(context).pop(); // Return null
          },
        ),
        TextButton(
          child: const Text('Confirm Header'),
          onPressed: () {
            if (_selectedHeaderRowIndex != null) {
              Navigator.of(context).pop(_selectedHeaderRowIndex); // Return selected index
            } else {
              // Optionally show a small message if nothing selected
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Please select the header row first.'), duration: Duration(seconds: 2)),
               );
            }
          },
        ),
      ],
    );
  }
} 