import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpelbudget/models/transaction.dart';
import 'package:simpelbudget/pages/transaction_list.dart';
import 'package:simpelbudget/services/database_helpeer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  int _cutoffDay = 1;
  DateTime _currentPeriodStart = DateTime.now();
  DateTime _currentPeriodEnd = DateTime.now();
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => _loadData());
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
      _currentPeriodStart = DateTime(_selectedYear, _selectedMonth, _cutoffDay);

      final nextMonth = _selectedMonth + 1;
      final year = nextMonth > 12 ? _selectedYear + 1 : _selectedYear;
      final month = nextMonth > 12 ? 1 : nextMonth;

      _currentPeriodEnd = DateTime(
        year,
        month,
        _cutoffDay,
      ).subtract(Duration(days: 1));
    } else {
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final stats = await DatabaseHelper.instance.getStatsByPeriod(
      _currentPeriodStart,
      _currentPeriodEnd,
    );

    _totalIncome = stats['income'] ?? 0.0;
    _totalExpense = stats['expense'] ?? 0.0;

    final allTransactions = await DatabaseHelper.instance.getTransactions();

    setState(() {
      _recentTransactions = allTransactions.take(5).toList();
      _isLoading = false;
    });
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
    _loadData();
  }

  void _nextPeriod() {
    final now = DateTime.now();
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
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Period Filter Section
                            Row(
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
                                      'Current Period',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${DateFormat('MMM d').format(_currentPeriodStart)} - ${DateFormat('MMM d').format(_currentPeriodEnd)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                  color:
                                      _selectedYear >= DateTime.now().year &&
                                              _selectedMonth >=
                                                  DateTime.now().month
                                          ? Colors.grey[400]
                                          : null,
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Summary Section
                            Text(
                              'Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Income',
                                    _totalIncome,
                                    Colors.green,
                                    Icons.arrow_upward,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Expense',
                                    _totalExpense,
                                    Colors.red,
                                    Icons.arrow_downward,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  NumberFormat.simpleCurrency(
                                    name: _currency,
                                  ).format(_totalIncome - _totalExpense),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        _totalIncome - _totalExpense >= 0
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    _recentTransactions.isEmpty
                        ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'No transactions yet. Tap + to add one!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                        : ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _recentTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _recentTransactions[index];
                            return TransactionListItem(
                              transaction: transaction,
                              currency: _currency,
                              onDelete: () async {
                                await DatabaseHelper.instance.deleteTransaction(
                                  transaction.id!,
                                );
                                _loadData();
                              },
                            );
                          },
                        ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          NumberFormat.simpleCurrency(name: _currency).format(amount),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
