import 'package:expenso/app.dart';
import 'package:expenso/logs.dart';
import 'package:expenso/screens/home/views/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

// final String baseUrl = "https://expenso-latest.onrender.com";
// final String baseUrl = "http://192.168.1.193:9001";
final String baseUrl = "https://ritikpanchal.xyz";

List<dynamic> transactions = [];
final GlobalKey<_ReadSmsScreenState> readSmsScreenKey =
    GlobalKey<_ReadSmsScreenState>();

class ReadSmsScreen extends StatefulWidget {
  const ReadSmsScreen({Key? key}) : super(key: key);

  @override
  State<ReadSmsScreen> createState() => _ReadSmsScreenState();
}

List<String> categories = [];
Map<String, double> categoryAmounts = {};

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
    readAllSmsOnAppStart(); // Read all SMS when app starts
  }

  static const platform = MethodChannel('sms_limited');

  Future<List<Map<String, dynamic>>> fetchLimitedSMS() async {
    try {
      final List<dynamic> smsList =
          await platform.invokeMethod('getLimitedSMS');
      // return smsList.cast<Map<String, dynamic>>();
      return smsList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      print("Failed to get SMS: '${e.message}'.");
      return [];
    }
  }

  Future<void> readAllSmsOnAppStart() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');

    if (permissionsGranted == true && mobileNumber != null) {
      List<Map<String, dynamic>> messages =
          await fetchLimitedSMS(); // 300 LATEST SMS

      bool shouldStopProcessing = false;
      for (var rawMessage in messages) {
        try {
          Map<String, dynamic> message = rawMessage;

          // Extract SMS body safely
          String? sms = message['body'] as String?;
          String? timeStamp = message['date'] as String?;
          if (sms != null &&
              (sms!.contains("credited") || sms!.contains("debited")) &&
              sms!.contains('SBI')) {
            shouldStopProcessing =
                await createExpense(mobileNumber, timeStamp!, sms!);

            if (shouldStopProcessing) {
              print(
                  "Stopping SMS processing as we already updated transactions");
              break; // Stop looping immediately
            }
          }
        } catch (e) {
          print("Skipping invalid message format: $rawMessage. Error: $e");
        }
      }
    }
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
      // _showCategoryInputDialog();
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

    final payload =
        jsonEncode({"refNumber": refNumber, "transferTo": transferTo});

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Transaction',
      'Tap to add a category for your transaction.',
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> fetchTransactions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');
    String url = "$baseUrl/expenso/api/v1/transaction/viewByMobileNumber/";
    url = "$url$mobileNumber";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      printRequestResponse(
          method: "GET",
          url: url,
          headers: headers,
          requestBody: ({}),
          response: response);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          transactions = (responseData['responseObject'] ?? [])
              .map((transaction) => {
                    ...transaction,
                    'transactionDate': transaction['transactionDate'] ?? ''
                  })
              .toList();
          transactions.sort(
              (a, b) => b['transactionDate'].compareTo(a['transactionDate']));
        });

        // Calculate categories and amounts
        categoryAmounts.clear();
        for (var transaction in transactions) {
          String category = transaction['category'] ?? 'Uncategorized';
          double amount = transaction['amount']?.toDouble() ?? 0.0;

          if (categoryAmounts.containsKey(category)) {
            categoryAmounts[category] = categoryAmounts[category]! + amount;
          } else {
            categoryAmounts[category] = amount;
          }
        }

        categories = categoryAmounts.keys.toList();
        categories.sort();
      }
    } catch (e) {
      print("Error fetching transactions: $e");
    }
  }

  Future<void> requestPermissionsAndStartListening() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');
    if (permissionsGranted == true) {
      print("Started Listening....");
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          if (message.body!.contains("credited") ||
              message.body!.contains("debited")) {
            setState(() {
              textReceived = message.body ?? '';
            });
            createExpense(mobileNumber!, '', textReceived);
          }
        },
        onBackgroundMessage: backgroundMessageHandler,
        listenInBackground: true,
      );
    }
  }

  static Future<void> backgroundMessageHandler(SmsMessage message) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');
    if (message.body != null) {
      final String smsBody = message.body!;
      String url = "$baseUrl/expenso/api/v1/expense/create/expense";
      const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': authorization
      };
      final body = jsonEncode({"mobileNumber": mobileNumber, "sms": smsBody});

      try {
        // Create expense
        final response =
            await http.post(Uri.parse(url), headers: headers, body: body);
        //logs
        printRequestResponse(
            method: "POST",
            url: url,
            headers: headers,
            requestBody: ({"mobileNumber": mobileNumber, "sms": smsBody}),
            response: response);
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final String refNumber =
              responseData['responseObject']['referenceNumber'] ?? '';
          final String category =
              responseData['responseObject']['category'] ?? '';
          if (refNumber.isNotEmpty && category.isEmpty) {
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
    String urlBase =
        "$baseUrl/expenso/api/v1/transaction/viewByReferenceNumber/";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final String url = "$urlBase$refNumber";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      printRequestResponse(
          method: "GET",
          url: url,
          headers: headers,
          requestBody: ({}),
          response: response);
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

    final payload =
        jsonEncode({"refNumber": refNumber, "transferTo": transferTo});

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Transaction - $transferTo',
      'Tap to add a category for your transaction.',
      notificationDetails,
      payload: payload,
    );
  }

  Future<bool> createExpense(
      String mobileNumber, String timeStamp, String sms) async {
    String url = "$baseUrl/expenso/api/v1/expense/create/expense";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final body = jsonEncode(
        {"mobileNumber": mobileNumber, "sms": sms, "timeStamp": timeStamp});

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      //logs
      printRequestResponse(
          method: "POST",
          url: url,
          headers: headers,
          requestBody: ({
            "mobileNumber": mobileNumber,
            "sms": sms,
            "timeStamp": timeStamp
          }),
          response: response);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Check for stop condition
        bool repeat = responseData['responseObject']['repeat'];
        if (repeat) {
          print("Stop response received. Halting SMS processing.");
          return true; // Indicating to stop processing
        }
        final String refNumber =
            responseData['responseObject']['referenceNumber'] ?? '';
        final String category =
            responseData['responseObject']['category'] ?? '';

        setState(() {
          referenceNumber = refNumber;
        });

        if (refNumber.isNotEmpty && category.isEmpty) {
          fetchTransactionDetails(refNumber);
        }
      }
    } catch (e) {
      print("Error creating expense: $e");
    }
    return false; // continue processing..
  }

  Future<void> fetchTransactionDetails(String refNumber) async {
    String urlBase =
        "$baseUrl/expenso/api/v1/transaction/viewByReferenceNumber/";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final String url = "$urlBase$refNumber";

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      printRequestResponse(
          method: "GET",
          url: url,
          headers: headers,
          requestBody: ({}),
          response: response);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          transferTo =
              responseData['responseObject']['transferTo'] ?? 'Unknown';
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
              decoration: const InputDecoration(labelText: "Enter Category"),
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
    String url = "$baseUrl/expenso/api/v1/category/create/category";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final body = jsonEncode({"transferTo": transferTo, "category": category});

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      printRequestResponse(
          method: "GET",
          url: url,
          headers: headers,
          requestBody: ({"transferTo": transferTo, "category": category}),
          response: response);
      if (response.statusCode == 200) {
        print("Category added successfully.");
        await flutterLocalNotificationsPlugin.show(
          0,
          'Category Added',
          'Your category has been mapped successfully.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'expenso_channel',
              'Expenso',
              channelDescription: 'Expenso notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error creating category: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
