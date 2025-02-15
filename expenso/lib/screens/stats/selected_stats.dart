import 'package:expenso/screens/stats/category_wise_expense.dart';
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String title;

  DetailScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // body: Center(
      //   child: Text(
      //     "You selected $title",
      //     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          
      //   ),
      // ),
      body:title == "Category Wish Expense"? CategoryWiseTransactions():CategoryWiseTransactions(),
    );
  }
}