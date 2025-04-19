import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:simpelbudget/models/transaction.dart';
import 'package:simpelbudget/services/database_helpeer.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isExpense = true;
  File? _receiptImage;
  bool _isProcessingReceipt = false;
  bool _isDetectingTotal = false;
  String _extractedText = '';
  double _extractedAmount = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickReceiptImage() async {
    setState(() {
      _isProcessingReceipt = true;
    });

    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage == null) {
      setState(() {
        _isProcessingReceipt = false;
      });
      return;
    }

    setState(() {
      _receiptImage = File(pickedImage.path);
    });

    // Process the receipt
    await _processReceiptImage(pickedImage.path);
  }

  Future<void> _processReceiptImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();

      // Preprocess the text
      final processedText = _preprocessText(recognizedText.text);
      setState(() {
        _extractedText = processedText;
        _isProcessingReceipt = false;
        _isDetectingTotal = true;
      });

      // Get receipt details from API
      try {
        final receiptDetails = await _getReceiptDetails(processedText);
        if (receiptDetails.containsKey('total')) {
          setState(() {
            _extractedAmount = receiptDetails['total'];
            _amountController.text = _extractedAmount.toString();
            _isDetectingTotal = false;
          });
        } else {
          setState(() {
            _isDetectingTotal = false;
          });
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('Could not extract total amount from receipt'),
          //   ),
          // );
        }
      } catch (e) {
        setState(() {
          _isDetectingTotal = false;
        });
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Error extracting details: $e')));
      }
    } catch (e) {
      setState(() {
        _isProcessingReceipt = false;
        _isDetectingTotal = false;
      });
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('Error reading text: $e')));
    }
  }

  String _preprocessText(String extractedText) {
    // Replace unwanted characters
    String cleanText =
        extractedText
            .replaceAll(RegExp(r'[_\n]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    // Format for better readability
    cleanText = cleanText.replaceAllMapped(
      RegExp(r'(\d+)\s?IDR'),
      (match) => 'IDR ${match.group(1)}',
    );

    return cleanText;
  }

  Future<Map<String, dynamic>> _getReceiptDetails(String receiptText) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY not found in .env file');
    }
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful assistant that extracts structured details from receipts including items, quantity, price, and total.',
          },
          {
            'role': 'user',
            'content': '''
Extract structured details from this receipt text. Return the result in JSON format like this:
{
  "item": [
    {
      "name": "ES TEH GEPREK",
      "quantity": 1,
      "price": 25000.00
    }
  ],
  "subtotal": 25000.00,
  "total": 25000.00,
  "tax": 0.00
}
Receipt Text:
$receiptText
          ''',
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      try {
        final jsonData = jsonDecode(content);
        return jsonData;
      } catch (e) {
        throw Exception('Failed to parse response as JSON: $content');
      }
    } else {
      throw Exception('Failed to get response: ${response.body}');
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        title: _titleController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _isExpense ? 'expense' : 'income',
        receiptPath: _receiptImage?.path,
      );
      print("BOSKUH");
      print(transaction.amount);

      await DatabaseHelper.instance.insertTransaction(transaction);
      // Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {_isExpense},
                      onSelectionChanged: (Set<bool> selection) {
                        setState(() {
                          _isExpense = selection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Receipt Image (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (_isProcessingReceipt)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Processing receipt...'),
                    ],
                  ),
                )
              else if (_isDetectingTotal)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Detecting total amount...'),
                    ],
                  ),
                )
              else if (_receiptImage != null)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _receiptImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_extractedAmount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Detected amount: ${NumberFormat.currency(symbol: 'Rp. ', decimalDigits: 2).format(_extractedAmount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: Icon(Icons.refresh),
                      label: Text('Choose Another Receipt'),
                      onPressed: _pickReceiptImage,
                    ),
                  ],
                )
              else
                Center(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.add_a_photo),
                    label: Text('Add Receipt Image'),
                    onPressed: _pickReceiptImage,
                  ),
                ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Save Transaction'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
