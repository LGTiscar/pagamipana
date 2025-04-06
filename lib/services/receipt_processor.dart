import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class BillItem {
  final String name;
  final double price;
  final int quantity; // Added quantity field
  final double unitPrice; // Added unitPrice field

  BillItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.unitPrice,
  });

  factory BillItem.create({
    required String name,
    required double price,
    int quantity = 1, // Default quantity to 1
    double? unitPrice,
  }) {
    return BillItem(
      name: name,
      price: price,
      quantity: quantity,
      unitPrice: unitPrice ?? (price / quantity), // Calculate unitPrice if not provided
    );
  }
}

class ReceiptProcessor {
  final String apiKey = 'AIzaSyAbhQUHNviJ_zn7BQdUhucnZgUQzNAsp6c'; // Hardcoded API key
  final Logger logger = Logger(); // Initialize logger

  Future<List<BillItem>> processReceipt(Uint8List imageBytes) async {
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Define the prompt
      const prompt = '''
You are an expert at analyzing restaurant receipts. 
    
Please carefully examine this receipt image and extract:
1. All individual menu items with their exact names, quantities, unit prices, and total prices
2. The total amount of the bill

Format your response as a clean JSON object with this exact structure:
{
"items": [
  {"name": "Item Name 1", "quantity": 2, "unitPrice": 10.99, "totalPrice": 21.98},
  {"name": "Item Name 2", "quantity": 1, "unitPrice": 5.99, "totalPrice": 5.99}
],
"total": 27.97
}

Be precise with item names, quantities, and prices. If you can't read something clearly, make your best guess.
For quantities, if not explicitly stated, assume 1.
For unit prices, divide the total price by the quantity.
For total prices, multiply the unit price by the quantity.

IMPORTANT: Your response must ONLY contain this JSON object and nothing else.
''';

      // Prepare request to Google's Gemini API
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

      final payload = {
        "contents": [
          {
            "parts": [
              {
                "text": prompt,
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generation_config": {
          "temperature": 0.2,
          "max_output_tokens": 4000,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode(payload),
      );

      logger.i('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Check if the expected keys exist in the response
        if (!jsonResponse.containsKey('candidates') ||
            jsonResponse['candidates'].isEmpty ||
            !jsonResponse['candidates'][0].containsKey('content') ||
            !jsonResponse['candidates'][0]['content'].containsKey('parts') ||
            jsonResponse['candidates'][0]['content']['parts'].isEmpty) {
          throw Exception('Unexpected response structure from Gemini API');
        }

        final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from the response
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0);
          final Map<String, dynamic> parsedResponse = jsonDecode(jsonStr!);

          // Check if the parsed response contains the expected keys
          if (!parsedResponse.containsKey('items') || !parsedResponse.containsKey('total')) {
            throw Exception('Parsed response is missing required keys: items or total');
          }

          final List<dynamic> items = parsedResponse['items'];
          return items.map((item) {
            // Ensure all required keys exist in each item
            if (!item.containsKey('name') ||
                !item.containsKey('quantity') ||
                !item.containsKey('unitPrice') ||
                !item.containsKey('totalPrice')) {
              throw Exception('Item is missing required keys: name, quantity, unitPrice, or totalPrice');
            }

            return BillItem.create(
              name: item['name'],
              price: item['totalPrice'].toDouble(),
              quantity: item['quantity'],
              unitPrice: item['unitPrice'].toDouble(),
            );
          }).toList();
        } else {
          throw Exception('Failed to extract JSON object from response text');
        }
      }

      throw Exception('Failed to process receipt: ${response.statusCode}');
    } catch (e) {
      logger.e('Error processing receipt: $e');
      throw Exception('Error processing receipt: $e');
    }
  }
}
