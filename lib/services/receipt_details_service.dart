import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ReceiptDetailsService {
  Future<Map<String, dynamic>> getReceiptDetails(String receiptText) async {
    final provider = dotenv.env['PROVIDER'] ?? '';
    if (provider.isEmpty) {
      throw Exception('PROVIDER not found in .env file');
    }
    if (provider == 'openai') {
      return await _getReceiptDetailsOpenAI(receiptText);
    } else if (provider == 'mistral') {
      return await _getReceiptDetailsMistral(receiptText);
    } else {
      throw Exception('Unsupported AI provider: $provider');
    }
  }

  Future<Map<String, dynamic>> _getReceiptDetailsOpenAI(String receiptText) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API_KEY not found in .env file');
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
            'content': 'You are a helpful assistant that extracts structured details from receipts including items, quantity, price, and total.',
          },
          {
            'role': 'user',
            'content': '''
Extract structured details from this receipt text. Return the result in JSON format like this:
{
  "item": [
    {
      "name": "ITEM NAME",
      "quantity": 1,
      "price": 0.00
    }
  ],
  "subtotal": 0.00,
  "total": 0.00,
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
        throw Exception('Failed to parse OpenAI response as JSON: $content');
      }
    } else {
      throw Exception('OpenAI request failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getReceiptDetailsMistral(String receiptText) async {
    final apiKey = dotenv.env['API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API_KEY not found in .env file');
    }
    final url = Uri.parse('https://api.mistral.ai/v1/chat/completions');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'mistral-large-latest',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a helpful assistant that extracts structured details from receipts including items, quantity, price, and total., and you response shoulbe only json text without the code quotes',
          },
          {
            'role': 'user',
            'content': '''
Extract structured details from this receipt text. Return the result in JSON format like this:
{
  "item": [
    {
      "name": "ITEM NAME",
      "quantity": 1,
      "price": 0.00
    }
  ],
  "subtotal": 0.00,
  "total": 0.00,
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
        throw Exception('Failed to parse Mistral response as JSON: $content');
      }
    } else {
      throw Exception('Mistral request failed: ${response.body}');
    }
  }
}
