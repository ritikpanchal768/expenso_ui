import 'dart:convert';
import 'package:expenso/screens/add_cash_expense/api_intigration/add_cash_expense_api_integration.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCashExpense extends StatefulWidget {
  @override
  _AddCashExpenseState createState() => _AddCashExpenseState();
}

class _AddCashExpenseState extends State<AddCashExpense> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isCustomCategory = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Others ( New Custom Field )'
  ];

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveExpense() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? mobileNumber = prefs.getString('mobileNumber');
      String amount = _amountController.text.trim();
      String category = _isCustomCategory
          ? _customCategoryController.text.trim()
          : _selectedCategory ?? '';

      if (amount.isEmpty || category.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter amount and select a category")),
        );
        return;
      }
      if (double.tryParse(amount) == null || double.parse(amount) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Enter a valid amount")),
        );
        return;
      }
      if (_isCustomCategory && category.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a custom category")),
        );
        return;
      }

      String formattedDate =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

      final response = await AddCashExpenseApiIntegration.addCashExpense(
          mobileNumber!, amount, category, formattedDate);
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense added successfully for $category')),
        );
      }

      // Clear fields after saving
      _amountController.clear();
      _customCategoryController.clear();
      setState(() {
        _selectedCategory = null;
        _isCustomCategory = false;
        _selectedDate = DateTime.now();
      });

      Navigator.pop(context);
    } catch (e) {
      print("Error while saving expense: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Cash Expense")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount",
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // Dropdown for categories
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _isCustomCategory = value == "Others ( New Custom Field )";
                });
              },
              decoration: InputDecoration(
                labelText: "Select Category",
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),

            // Show custom category text field when "Others ( New Custom Field )" is selected
            if (_isCustomCategory)
              TextField(
                controller: _customCategoryController,
                decoration: InputDecoration(
                  labelText: "Enter Custom Category",
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
              ),
            SizedBox(height: 15),

            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Date",
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  "${_selectedDate.toLocal()}".split(' ')[0],
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _saveExpense,
                child: Text("Save Expense"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
