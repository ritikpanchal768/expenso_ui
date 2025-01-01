import 'package:fl_chart/fl_chart.dart';
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
  List<dynamic> transactions = [];

  final TextEditingController categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeNotifications();
    requestPermissionsAndStartListening();
    // Fetch transactions when the app opens
    fetchTransactions();
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
    print("Fetching TransactionDetails...");
    const String url =
        "http://192.168.1.3:9001/expenso/api/v1/transaction/viewByMobileNumber/8700002896";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
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
    if (permissionsGranted == true) {
      print("Started Listening....");
      fetchTransactions();
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          setState(() {
            textReceived = message.body ?? '';
          });

          createExpense("8700002896", textReceived);
          fetchTransactions();
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
      final body = jsonEncode({"mobileNumber": "8700002896", "sms": smsBody});

      try {
        // Create expense
        final response =
            await http.post(Uri.parse(url), headers: headers, body: body);
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
    const String urlBase =
        "http://192.168.1.3:9001/expenso/api/v1/transaction/viewByReferenceNumber/";
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
        final String category =
            responseData['responseObject']['category'] ?? '';

        setState(() {
          referenceNumber = refNumber;
        });

        if (refNumber.isNotEmpty && category.isEmpty) {
          fetchTransactionDetails(refNumber);
        } else {
          fetchTransactions();
        }
      }
    } catch (e) {
      print("Error creating expense: $e");
    }
  }

  Future<void> fetchTransactionDetails(String refNumber) async {
    const String urlBase =
        "http://192.168.1.3:9001/expenso/api/v1/transaction/viewByReferenceNumber/";
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
    const String url =
        "http://192.168.1.3:9001/expenso/api/v1/category/create/category";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final body = jsonEncode({"transferTo": transferTo, "category": category});

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        print("Category added successfully.");
        fetchTransactions();
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
  return Scaffold(
    appBar: AppBar(title: const Text("Expenso")),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Transaction Charts:"),
            const SizedBox(height: 16.0),
            // Pie Chart
            transactions.isNotEmpty
                ? SizedBox(
                    height: 200, // Adjust height as needed
                    child: PieChart(
                      PieChartData(
                        sections: _getPieChartSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  )
                : const Text("No transactions for pie chart."),
            const SizedBox(height: 16.0),
            // Bar Graph
            transactions.isNotEmpty
                ? SizedBox(
                    height: 300, // Adjust height as needed
                    child: BarChart(
                      BarChartData(
                        barGroups: _getBarChartGroups(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) => Text(value.toString()),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index >= 0 && index < categories.length) {
                                  return Text(categories[index]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                      ),
                    ),
                  )
                : const Text("No transactions for bar chart."),
            const Divider(height: 20.0),
            const Text("Transaction List:"),
            const SizedBox(height: 8.0),
            transactions.isNotEmpty
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Transfer To')),
                      ],
                      rows: transactions
                          .map(
                            (transaction) => DataRow(cells: [
                              DataCell(
                                  Text(transaction['transactionDate'] ?? '')),
                              DataCell(Text(
                                  transaction['amount']?.toString() ?? '')),
                              DataCell(Text(transaction['category'] ?? '')),
                              DataCell(Text(transaction['transferTo'] ?? '')),
                            ]))
                          .toList(),
                    ),
                  )
                : const Text("No transactions found."),
          ],
        ),
      ),
    ),
  );
}




// Helper Functions for Charts
  List<PieChartSectionData> _getPieChartSections() {
    Map<String, double> categoryAmounts = {};

    // Aggregate transaction amounts by category
    for (var transaction in transactions) {
      String category = transaction['category'] ?? 'Unknown';
      double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      categoryAmounts[category] = (categoryAmounts[category] ?? 0) + amount;
    }

    return categoryAmounts.entries
        .map((entry) => PieChartSectionData(
              value: entry.value,
              title: entry.key,
              color: Colors
                  .primaries[entry.key.hashCode % Colors.primaries.length],
              radius: 50,
            ))
        .toList();
  }

  List<BarChartGroupData> _getBarChartGroups() {
    Map<String, double> categoryAmounts = {};

    // Aggregate transaction amounts by category
    for (var transaction in transactions) {
      String category = transaction['category'] ?? 'Unknown';
      double amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
      categoryAmounts[category] = (categoryAmounts[category] ?? 0) + amount;
    }

    // Sort by category name
    List<String> categories = categoryAmounts.keys.toList();
    categories.sort();

    return List.generate(categories.length, (index) {
      String category = categories[index];
      double amount = categoryAmounts[category]!;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            width: 15,
            color: Colors.blueAccent,
          ),
        ],
      );
    });
  }
}
