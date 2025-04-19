import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpelbudget/models/transaction.dart';
import 'package:simpelbudget/pages/transaction_detail.dart';
import 'package:simpelbudget/services/database_helpeer.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Transaction> _transactions = [];
  String _filter = 'all'; // 'all', 'income', 'expense'
  bool _isLoading = true;
  int _cutoffDay = 1;
  bool _filterByPeriod = false;
  DateTime _currentPeriodStart = DateTime.now();
  DateTime _currentPeriodEnd = DateTime.now();
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => _loadTransactions());
  }

  Future<void> _loadSettings() async {
    final settings = await DatabaseHelper.instance.getSettings();
    setState(() {
      _cutoffDay = int.tryParse(settings['cutoff_day'] ?? '1') ?? 1;
      _currency = settings['currency'] ?? 'USD';
    });
    _calculatePeriodDates();
  }

  void _calculatePeriodDates() {
    final now = DateTime.now();
    final currentDay = now.day;

    if (currentDay >= _cutoffDay) {
      // We're after the cutoff day in the current month
      _currentPeriodStart = DateTime(_selectedYear, _selectedMonth, _cutoffDay);

      // Calculate end date (cutoff day of next month - 1)
      final nextMonth = _selectedMonth + 1;
      final year = nextMonth > 12 ? _selectedYear + 1 : _selectedYear;
      final month = nextMonth > 12 ? 1 : nextMonth;

      // Last day before the next cutoff
      _currentPeriodEnd = DateTime(
        year,
        month,
        _cutoffDay,
      ).subtract(Duration(days: 1));
    } else {
      // We're before the cutoff day in the current month
      // Start from previous month's cutoff day
      final prevMonth = _selectedMonth - 1;
      final year = prevMonth < 1 ? _selectedYear - 1 : _selectedYear;
      final month = prevMonth < 1 ? 12 : prevMonth;

      _currentPeriodStart = DateTime(year, month, _cutoffDay);
      // End on this month's cutoff day - 1
      _currentPeriodEnd = DateTime(
        _selectedYear,
        _selectedMonth,
        _cutoffDay,
      ).subtract(Duration(days: 1));
    }
  }

  void _previousPeriod() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedYear--;
        _selectedMonth = 12;
      } else {
        _selectedMonth--;
      }
      _calculatePeriodDates();
    });
    _loadTransactions();
  }

  void _nextPeriod() {
    final now = DateTime.now();
    // Don't allow going past current month
    if (_selectedYear >= now.year && _selectedMonth >= now.month) {
      return;
    }

    setState(() {
      if (_selectedMonth == 12) {
        _selectedYear++;
        _selectedMonth = 1;
      } else {
        _selectedMonth++;
      }
      _calculatePeriodDates();
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    List<Transaction> transactions;

    if (_filterByPeriod) {
      // Get transactions for current period
      final db = await DatabaseHelper.instance.database;
      final formattedStartDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_currentPeriodStart);
      final formattedEndDate = DateFormat(
        'yyyy-MM-dd',
      ).format(_currentPeriodEnd);

      if (_filter == 'all') {
        final results = await db.query(
          'transactions',
          where: 'date >= ? AND date <= ?',
          whereArgs: [formattedStartDate, formattedEndDate],
          orderBy: 'date DESC',
        );
        transactions = results.map((t) => Transaction.fromMap(t)).toList();
      } else {
        final results = await db.query(
          'transactions',
          where: 'type = ? AND date >= ? AND date <= ?',
          whereArgs: [_filter, formattedStartDate, formattedEndDate],
          orderBy: 'date DESC',
        );
        transactions = results.map((t) => Transaction.fromMap(t)).toList();
      }
    } else {
      // Get all transactions filtered only by type
      if (_filter == 'all') {
        transactions = await DatabaseHelper.instance.getTransactions();
      } else {
        transactions = await DatabaseHelper.instance.getTransactionsByType(
          _filter,
        );
      }
    }

    setState(() {
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Type filter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFilterChip('All', 'all'),
                  SizedBox(width: 8),
                  _buildFilterChip('Income', 'income'),
                  SizedBox(width: 8),
                  _buildFilterChip('Expense', 'expense'),
                ],
              ),
              SizedBox(height: 12),
              // Period filter toggle
              SwitchListTile(
                title: Text('Filter by Cutoff Period'),
                value: _filterByPeriod,
                onChanged: (value) {
                  setState(() {
                    _filterByPeriod = value;
                  });
                  _loadTransactions();
                },
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),

              // Period selector (only show if filtering by period)
              if (_filterByPeriod)
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: _previousPeriod,
                          tooltip: 'Previous Period',
                        ),
                        Column(
                          children: [
                            Text(
                              '${DateFormat('MMM d').format(_currentPeriodStart)} - '
                              '${DateFormat('MMM d').format(_currentPeriodEnd)}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Cutoff: Day $_cutoffDay',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          onPressed: _nextPeriod,
                          tooltip: 'Next Period',
                          // Disable if we're at current month
                          color:
                              _selectedYear >= DateTime.now().year &&
                                      _selectedMonth >= DateTime.now().month
                                  ? Colors.grey[400]
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                    onRefresh: () async {
                      await _loadTransactions();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child:
                          _transactions.isEmpty
                              ? Center(
                                child: Text(
                                  'No transactions found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                itemCount: _transactions.length,
                                itemBuilder: (context, index) {
                                  return TransactionListItem(
                                    transaction: _transactions[index],
                                    currency: _currency,
                                    onDelete: () async {
                                      await DatabaseHelper.instance
                                          .deleteTransaction(
                                            _transactions[index].id!,
                                          );
                                      _loadTransactions();
                                    },
                                  );
                                },
                              ),
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
          _loadTransactions();
        }
      },
    );
  }
}

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final String currency;
  final VoidCallback onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    return Card(
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isIncome
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.title),
        subtitle: Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              (isIncome ? '+' : '-') +
                  NumberFormat.simpleCurrency(
                    name: currency,
                  ).format(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(width: 8),
            transaction.receiptPath != null
                ? IconButton(
                  icon: Icon(Icons.receipt, size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ReceiptViewPage(
                              imagePath: transaction.receiptPath!,
                            ),
                      ),
                    );
                  },
                )
                : SizedBox.shrink(),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red[300], size: 20),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Delete Transaction'),
                        content: Text(
                          'Are you sure you want to delete this transaction?',
                        ),
                        actions: [
                          TextButton(
                            child: Text('Cancel'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: Text('Delete'),
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => TransactionDetailPage(
                    transaction: transaction,
                    currency: currency,
                  ),
            ),
          );
        },
      ),
    );
  }
}

class ReceiptViewPage extends StatelessWidget {
  final String imagePath;

  const ReceiptViewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Receipt Image')),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}
