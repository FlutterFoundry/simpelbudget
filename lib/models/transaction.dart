import 'package:intl/intl.dart';

class Transaction {
  int? id;
  String title;
  double amount;
  DateTime date;
  String type; // 'income' or 'expense'
  String? receiptPath;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.receiptPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'type': type,
      'receiptPath': receiptPath,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      type: map['type'],
      receiptPath: map['receiptPath'],
    );
  }
}
