import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReadSmsScreen extends StatefulWidget {
  const ReadSmsScreen({super.key});

  @override
  State<ReadSmsScreen> createState() => _ReadSmsScreenState();
}

class _ReadSmsScreenState extends State<ReadSmsScreen> {
  final Telephony telephony = Telephony.instance;
  String textReceived = "";
  String apiResponse = "";
  String transferTo = "";
  final TextEditingController categoryController = TextEditingController();

  Future<void> createExpense(String mobileNumber, String sms) async {
    const String url =
        "http://10.0.2.2:9001/expenso/api/v1/expense/create/expense";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization,
    };

    final body = jsonEncode({
      "mobileNumber": mobileNumber,
      "sms": sms,
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String responseMessage = responseData['responseMessage'] ?? '';
        final responseObject = responseData['responseObject'] ?? {};
        final String referenceNumber = responseObject['referenceNumber'] ?? '';

        setState(() {
          apiResponse = responseMessage;
        });

        if (responseMessage ==
            "Expense Added Successfully But this is a new Category") {
          if (referenceNumber.isNotEmpty) {
            fetchTransactionDetails(referenceNumber);
          }
        }
      } else {
        print("Failed to create expense: ${response.statusCode}");
      }
    } catch (e) {
      print("Error making API call: $e");
    }
  }

  Future<void> fetchTransactionDetails(String referenceNumber) async {
    const String urlBase = "http://10.0.2.2:9001/expenso/api/v1/transaction/view/";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization,
    };

    final String url = "$urlBase$referenceNumber";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final responseObject = responseData['responseObject'] ?? {};
        setState(() {
          transferTo = responseObject['transferTo'] ?? 'Unknown';
        });
        _showCategoryInputDialog();
      } else {
        print("Failed to fetch transaction details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error making API call: $e");
    }
  }

  Future<void> createCategory(String transferTo, String category) async {
    const String url =
        "http://10.0.2.2:9001/expenso/api/v1/category/create/category";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization,
    };

    final body = jsonEncode({
      "transferTo": transferTo,
      "category": category,
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        print("Category added successfully.");
      } else {
        print("Failed to add category: ${response.statusCode}");
      }
    } catch (e) {
      print("Error making API call: $e");
    }
  }

  void _showCategoryInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Transfer To: $transferTo"),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Enter Category",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final category = categoryController.text.trim();
              if (category.isNotEmpty) {
                createCategory(transferTo, category);
                Navigator.pop(context);
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void startListening() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        setState(() {
          textReceived = message.body!;
        });
        createExpense("8700002896", message.body!);
      },
      listenInBackground: false,
    );
  }

  @override
  void initState() {
    super.initState();
    startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenso"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Message Received:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              textReceived,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "API Response:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              apiResponse,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
