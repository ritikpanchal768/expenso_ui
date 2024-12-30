import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String textReceived = "";
  String apiResponse = "";
  String transferTo = "";
  String referenceNumber = "";

  final TextEditingController categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    requestPermissionsAndStartListening();
  }

  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
    );
  }

  void handleNotificationResponse(NotificationResponse response) async {
    if (response.payload != null) {
      final Map<String, dynamic> payloadData = jsonDecode(response.payload!);
      setState(() {
        referenceNumber = payloadData["refNumber"];
        transferTo = payloadData["transferTo"];
      });
      _showCategoryInputDialog();
    }
  }

  Future<void> showCategoryNotification(String refNumber) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'expenso_channel',
      'Expenso',
      channelDescription: 'Expenso notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    final payload = jsonEncode({"refNumber": refNumber, "transferTo": transferTo});

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Transaction',
      'Tap to add a category for your transaction.',
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> requestPermissionsAndStartListening() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted == true) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          setState(() {
            textReceived = message.body ?? '';
          });
          createExpense("8700002896", textReceived);
        },
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );
    }
  }

  static Future<void> backgroundMessageHandler(SmsMessage message) async {
    if (message.body != null) {
      final String smsBody = message.body!;
      const String url =
          "http://192.168.1.3:9001/expenso/api/v1/expense/create/expense";
      const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': authorization
      };
      final body =
          jsonEncode({"mobileNumber": "8700002896", "sms": smsBody});

      try {
        // Create expense
        final response =
            await http.post(Uri.parse(url), headers: headers, body: body);
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final String refNumber =
              responseData['responseObject']['referenceNumber'] ?? '';

          if (refNumber.isNotEmpty) {
            await fetchTransactionDetailsInBackground(refNumber);
          }
        }
      } catch (e) {
        print("Error in background expense creation: $e");
      }
    }
  }

  static Future<void> fetchTransactionDetailsInBackground(
      String refNumber) async {
    const String urlBase =
        "http://192.168.1.3:9001/expenso/api/v1/transaction/view/";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final String url = "$urlBase$refNumber";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String transferTo =
            responseData['responseObject']['transferTo'] ?? 'Unknown';

        // Show notification for adding category with transferTo in payload
        await showCategoryNotificationInBackground(refNumber, transferTo);
      }
    } catch (e) {
      print("Error fetching transaction details in background: $e");
    }
  }

  static Future<void> showCategoryNotificationInBackground(
      String refNumber, String transferTo) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'expenso_channel',
      'Expenso',
      channelDescription: 'Expenso notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    final payload = jsonEncode({"refNumber": refNumber, "transferTo": transferTo});

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Transaction - $transferTo',
      'Tap to add a category for your transaction.',
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> createExpense(String mobileNumber, String sms) async {
    const String url =
        "http://192.168.1.3:9001/expenso/api/v1/expense/create/expense";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final body = jsonEncode({"mobileNumber": mobileNumber, "sms": sms});

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String refNumber =
            responseData['responseObject']['referenceNumber'] ?? '';

        setState(() {
          referenceNumber = refNumber;
        });

        if (refNumber.isNotEmpty) {
          fetchTransactionDetails(refNumber);
        }
      }
    } catch (e) {
      print("Error creating expense: $e");
    }
  }

  Future<void> fetchTransactionDetails(String refNumber) async {
    const String urlBase =
        "http://192.168.1.3:9001/expenso/api/v1/transaction/view/";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final String url = "$urlBase$refNumber";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          transferTo = responseData['responseObject']['transferTo'] ?? 'Unknown';
        });
        showCategoryNotification(refNumber);
      }
    } catch (e) {
      print("Error fetching transaction details: $e");
    }
  }

  void _showCategoryInputDialog() {
    // Clear the category input field
    categoryController.clear();
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
              decoration:
                  const InputDecoration(labelText: "Enter Category"),
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

  Future<void> createCategory(String transferTo, String category) async {
    const String url =
        "http://192.168.1.3:9001/expenso/api/v1/category/create/category";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final body =
        jsonEncode({"transferTo": transferTo, "category": category});

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        print("Category added successfully.");
      }
    } catch (e) {
      print("Error creating category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expenso")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Latest SMS Received:"),
            const SizedBox(height: 8.0),
            Text(textReceived.isEmpty ? "No SMS received yet." : textReceived),
            const Divider(height: 20.0),
            const Text("Transaction Details:"),
            const SizedBox(height: 8.0),
            Text("Reference Number: $referenceNumber"),
            Text("Transfer To: $transferTo"),
          ],
        ),
      ),
    );
  }
}
