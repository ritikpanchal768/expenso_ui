import 'dart:math';

import 'package:expenso/read_sms.dart';
import 'package:expenso/screens/add_category/views/add_category.dart';
import 'package:expenso/screens/home/views/mainscreen.dart';
import 'package:expenso/screens/stats/stats.dart';
import 'package:expenso/transaction_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    loadTransactions();  // Call the async method to load transactions
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
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  int index = 0;
  late Color selectedItem = Colors.grey;
  Color unselectedItem = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(),
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BottomNavigationBar(
              onTap: (value) {
                loadTransactions();
                setState(() {
                  index = value;
                });
              },
              showSelectedLabels: false,
              showUnselectedLabels: false,
              elevation: 3,
              items: [
                BottomNavigationBarItem(
                    icon: Icon(
                      CupertinoIcons.home,
                      color: index == 1 ? selectedItem : unselectedItem,
                    ),
                    label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(
                      CupertinoIcons.graph_square_fill,
                      color: index == 0 ? selectedItem : unselectedItem,
                    ),
                    label: 'Stats')
              ]),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            loadTransactions();
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => AddCategory(),
              ),
            );
          },
          shape: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary
                  ],
                  transform: const GradientRotation(pi / 4),
                )),
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        body: index == 0 ? Mainscreen() : StatScreen());
  }
}
