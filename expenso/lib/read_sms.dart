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
      print(response);
      if (response.statusCode == 200) {
        setState(() {
          apiResponse = response.body;
        });
      } else {
        print("Failed to create expense: ${response.statusCode}");
      }
    } catch (e) {
      print("Error making API call: $e");
    }
  }

  void startListening() {
    print("Listening to SMS");
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
            Text(
              "Message Received:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              textReceived,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              "API Response:",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
