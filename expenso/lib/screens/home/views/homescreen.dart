import 'dart:math';

import 'package:expenso/screens/add_cash_expense/view/add_cash_expense.dart';
import 'package:expenso/screens/add_category/views/add_category.dart';
import 'package:expenso/screens/home/views/mainscreen.dart';
import 'package:expenso/screens/stats/stats.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  bool isExpanded = false; // Controls FAB expansion
  late Color selectedItem = Colors.grey;
  Color unselectedItem = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BottomNavigationBar(
          onTap: (value) {
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
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.graph_square_fill,
                color: index == 0 ? selectedItem : unselectedItem,
              ),
              label: 'Stats',
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isExpanded) ...[
            // Add Expense Button
            FloatingActionButton.extended(
              heroTag: "add_expense",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => AddCashExpense(),
                  ),
                );
              },
              icon: Icon(Icons.money),
              label: Text("Add Cash Expense"),
            ),

            SizedBox(height: 10),

            // Add Category Button
            FloatingActionButton.extended(
              heroTag: "add_category",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => AddCategory(),
                  ),
                );
                setState(() => isExpanded = false);
              },
              icon: Icon(Icons.category),
              label: Text("Add Category"),
            ),
            SizedBox(height: 10),
          ],

          // Main Floating Action Button
          FloatingActionButton(
            onPressed: () => setState(() => isExpanded = !isExpanded),
            shape: const CircleBorder(),
            backgroundColor: isExpanded ? Colors.red : null, // Change color to red when expanded
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isExpanded
                    ? LinearGradient(
                        colors: [
                          Colors.red.shade400, // A bright reddish shade
                          Colors.red.shade600, // A deeper red
                          Colors.red.shade800, // A darker red
                        ],
                        transform: const GradientRotation(pi / 4),)
                    : LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                        transform: const GradientRotation(pi / 4),
                ),
              ),
              child: Icon(isExpanded ? Icons.close : CupertinoIcons.add),
            ),
          ),
        ],
      ),
      body: index == 0
          ? Mainscreen()
          : StatScreen(), // Switch between home and stats
    );
  }
}
