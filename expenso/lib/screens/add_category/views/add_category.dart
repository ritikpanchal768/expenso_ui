import 'package:expenso/read_sms.dart';
import 'package:expenso/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      List<dynamic> fetchedTransactions = await TransactionService.fetchTransactions(mobileNumber!);
      setState(() {
        transactions = fetchedTransactions;  // Update state with fetched transactions
      });

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

  @override
  void dispose() {
    // Dispose of all TextEditingControllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitCategory(String id) async {
    final transaction = transactions.firstWhere((t) => t['id'] == id);
    final category = _controllers[id]?.text.trim() ?? '';

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a category for ${transaction['transferTo']}')),
      );
      return;
    }

    String url =
        "$baseUrl/expenso/api/v1/category/create/category";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };

    // API request payload
    final payload = {
      'transferTo': transaction['transferTo'],
      'category': category,
    };

    try {
       final response =
          await http.post(Uri.parse(url), headers: headers, body: json.encode(payload));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Category added successfully for ${transaction['transferTo']}')),
        );
        setState(() {
          transaction['category'] = category;
        });
        loadTransactions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add category for ${transaction['transferTo']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter transactions where category is null or empty
    final filteredTransactions = transactions
        .where((transaction) => transaction['category'] == null || transaction['category'] == '')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Categories'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: filteredTransactions.map((transaction) {
            final id = transaction['id']!;
            final transferTo = transaction['transferTo']!;
            return Card(
              margin: EdgeInsets.all(8.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transfer To: $transferTo',
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    TextFormField(
                      controller: _controllers[id],
                      decoration: const InputDecoration(
                        labelText: 'Enter Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    ElevatedButton(
                      onPressed: () => _submitCategory(id),
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
