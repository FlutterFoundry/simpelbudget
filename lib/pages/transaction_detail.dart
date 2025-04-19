import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpelbudget/models/transaction.dart';
import 'package:simpelbudget/pages/transaction_list.dart';

class TransactionDetailPage extends StatelessWidget {
  final Transaction transaction;
  final String currency;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction Details')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        transaction.type == 'income'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    transaction.type.toUpperCase(),
                    style: TextStyle(
                      color:
                          transaction.type == 'income'
                              ? Colors.green
                              : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 4),
                Text(DateFormat('MMM dd, yyyy').format(transaction.date)),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Amount:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Text(
                  NumberFormat.simpleCurrency(
                    name: currency,
                  ).format(transaction.amount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        transaction.type == 'income'
                            ? Colors.green
                            : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            if (transaction.receiptPath != null) ...[
              Text(
                'Receipt:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onTap: () {
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
                  child: Image.file(
                    File(transaction.receiptPath!),
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


