import 'dart:math';

import 'package:expenso/logs.dart';
import 'package:expenso/read_sms.dart';
import 'package:expenso/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AddCategory extends StatefulWidget {
  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategory> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // Asynchronous method to fetch transactions
  Future<void> loadTransactions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');
    try {
      // Await the Future and assign the result to the transactions variable
      List<dynamic> fetchedTransactions =
          await TransactionService.fetchTransactions(mobileNumber!);
      setState(() {
        transactions =
            fetchedTransactions; // Update state with fetched transactions
      });
      // Fetch previously added categories
      await fetchCategories();
      // Now initialize TextEditingControllers only for transactions where category is null or empty
      for (var transaction in transactions) {
        if (transaction['category'] == null || transaction['category'] == '') {
          _controllers[transaction['id']!] = TextEditingController();
        }
      }
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }


  Map<String, String?> selectedCategories = {}; // Store category per transaction
  List<dynamic> categories = []; // List to store fetched categories

  // Fetch categories from the backend
  Future<void> fetchCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');
    String url = "$baseUrl/expenso/api/v1/category/list/$mobileNumber";
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
        response : response
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody.containsKey("responseObject") && responseBody["responseObject"] is List) {
          setState(() {
            categories = responseBody["responseObject"]; // Ensure it's a List
          });
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  @override
  void dispose() {
    // Dispose of all TextEditingControllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitCategory(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');
    final transaction = transactions.firstWhere((t) => t['id'] == id);
    final category = selectedCategories[id] ?? _controllers[id]?.text.trim() ?? '';

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter or select a category for ${transaction['transferTo'] ?? transaction['transferFrom']}',
          ),
        ),
      );
      return;
    }

    String url = "$baseUrl/expenso/api/v1/category/create/category";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };

    final payload = {
      'mobileNumber':mobileNumber,
      'transferTo': transaction['transferTo'],
      'tranferFrom': transaction['transferFrom'],
      'category': category,
    };

    try {
      final response = await http.post(Uri.parse(url),
          headers: headers, body: json.encode(payload));
      printRequestResponse(
          method: "POST",
          url: url,
          headers: headers,
          requestBody: payload,
          response: response);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Category added successfully for ${transaction['transferTo'] ?? transaction['transferFrom']}')),
        );
        setState(() {
          transaction['category'] = category;
        });
        loadTransactions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to add category for ${transaction['transferTo'] ?? transaction['transferFrom']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String formatTimestamp(String dateTimeString) {
    // Parse the string into a DateTime object
    DateTime dateTime = DateTime.parse(dateTimeString);

    // Format the DateTime to a readable format
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
    // Example Output: Feb 8, 2025 - 5:28 PM
  }

  // Function to get the gradient based on transaction type
  LinearGradient getTransactionGradient(bool isCredit) {
    return isCredit
        ? LinearGradient( // Green Gradient for Credit
            colors: [
              Colors.green.shade700,  // Dark Green
              Colors.greenAccent,     // Bright Green
              Colors.tealAccent,      // Teal Tint
            ],
            transform: GradientRotation(pi / 4),
          )
        : LinearGradient( // Red Gradient for Debit
            colors: [
              Colors.red.shade700,    // Dark Red
              Colors.redAccent,       // Bright Red
              Colors.orangeAccent,    // Slight Orange Tint
            ],
            transform: GradientRotation(pi / 4),
          );
  }


  @override
  Widget build(BuildContext context) {
    final filteredTransactions = transactions
        .where((transaction) =>
            transaction['category'] == null || transaction['category'] == '')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Add Categories')),
      body: SingleChildScrollView(
        child: Column(
          children: filteredTransactions.map((transaction) {
            final id = transaction['id']!;
            final transferTo = transaction['transferTo'];
            final transferFrom = transaction['transferFrom'];
            final time = transaction['createdOn'];
            final amount = transaction['amount'];

            return Card(
              margin: EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: getTransactionGradient(transaction['transactionType'] == 'CREDIT')
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${transferTo != null ? "Transfer To" : "Transfer From"}: ${transferTo ?? transferFrom}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // Text color for contrast
                        ),
                      ),
                      Text(
                        'Time: ${formatTimestamp(time)}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Amount: ${amount}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      DropdownButton<String>(
                        value: categories.any((category) => category['category'].toString() == selectedCategories[id])
                            ? selectedCategories[id]
                            : null, // Set to null if the selected value is not in the list
                        hint: Text("Select Category"),
                        items: categories.map<DropdownMenuItem<String>>((category) {
                          return DropdownMenuItem<String>(
                            value: category['category'].toString(),
                            child: Text(category['category'].toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategories[id] = value;
                            });
                          }
                        },
                      ),

                      SizedBox(height: 8.0),
                      TextFormField(
                        controller: _controllers[id] ??= TextEditingController(),
                        style: TextStyle(color: Colors.white), // Text color
                        decoration: InputDecoration(
                          labelText: 'Or Enter New Category',
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.0),
                      ElevatedButton(
                        onPressed: () {
                          _submitCategory(id); // Ensure this is correctly calling the function
                        },
                        child: Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Button background
                          foregroundColor: Theme.of(context).colorScheme.primary, // Button text color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
