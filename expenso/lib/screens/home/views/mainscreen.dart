import 'dart:math';

import 'package:expenso/read_sms.dart';
import 'package:expenso/transaction_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => _MainscreenState();
}

double expense = 0;

class _MainscreenState extends State<Mainscreen> {
  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> _refresh() async {
    await Future.delayed(
        const Duration(seconds: 2)); // Simulating a network call
    setState(() {
      loadTransactions();
    });
  }

  // Asynchronous method to fetch transactions
  Future<void> loadTransactions() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? mobileNumber = prefs.getString('mobileNumber');
    print('TRANSACTION FETCH IN MAIN SCREEN.....');
    try {
      // Await the Future and assign the result to the transactions variable
      List<dynamic> fetchedTransactions =
          await TransactionService.fetchTransactions(mobileNumber!);
      double debit = 0;
      for (var transaction in fetchedTransactions) {
        if (transaction['transactionType'] == 'DEBIT') {
          debit = debit + transaction['amount'];
        }
      } // Call the async method to load transactions
      setState(() {
        transactions =
            fetchedTransactions; // Update state with fetched transactions
        expense = debit;
      });
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 246, 162, 52)),
                          ),
                          const Icon(
                            CupertinoIcons.person_fill,
                            color: Color.fromARGB(255, 246, 124, 9),
                          )
                        ],
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome!",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.outline),
                            ),
                            Text(
                              "Ritik Panchal",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ]),
                    ],
                  ),
                  IconButton(
                      onPressed: _refresh,
                      icon: const Icon(CupertinoIcons.refresh))
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width / 2,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.tertiary
                      ],
                      transform: const GradientRotation(pi / 4),
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 4,
                          color: Colors.grey.shade300,
                          offset: const Offset(5, 5))
                    ]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    // SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.currency_rupee,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(
                            width:
                                2), // Optional: Adds space between the icon and the amount
                        Text(
                          (0 - expense).toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),

                    // const Text(
                    //   '\$ 4800.00',
                    //   style: TextStyle(
                    //       fontSize: 40,
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.bold),
                    // ),
                    SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    color: Colors.white30,
                                    shape: BoxShape.circle),
                                child: const Center(
                                    child: Icon(
                                  CupertinoIcons.arrow_down,
                                  size: 12,
                                  color: Colors.green,
                                )),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Income',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      const SizedBox(
                                          width:
                                              2), // Optional: Adds space between the icon and the amount
                                      Text(
                                        '00.0',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    color: Colors.white30,
                                    shape: BoxShape.circle),
                                child: const Center(
                                    child: Icon(
                                  CupertinoIcons.arrow_up,
                                  size: 12,
                                  color: Colors.red,
                                )),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Expense',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      const SizedBox(
                                          width:
                                              2), // Optional: Adds space between the icon and the amount
                                      Text(
                                        expense.toStringAsFixed(1),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, int i) {
                      var transaction = transactions[i];
                      if (transaction['category'] == null) {
                        transaction['category'] = 'Not Added';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: const BoxDecoration(
                                              color: Color.fromARGB(
                                                  255, 236, 165, 22),
                                              shape: BoxShape.circle),
                                        ),
                                        const Icon(
                                          Icons.food_bank,
                                          color: Colors.white,
                                          size: 40,
                                        )
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      transaction['category'],
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.currency_rupee,
                                          color: Colors.red,
                                          size: 13,
                                        ),
                                        const SizedBox(
                                            width:
                                                3), // Optional: Adds space between the icon and the amount
                                        Text(
                                          transaction['amount']
                                              .toStringAsFixed(2),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      getFormattedDate(
                                          transaction['transactionDate']),
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Function to format the date based on the transaction timestamp.
String getFormattedDate(String transactionDate) {
  // Parse the ISO 8601 string to a DateTime object.
  DateTime parsedDate = DateTime.parse(transactionDate);
  // Add 1 day to the transaction date
  DateTime newTransactionDate = parsedDate.add(Duration(days: 1));

  // Get the current date.
  DateTime currentDate = DateTime.now();

  // Compare the transaction date with the current date.
  if (isSameDay(newTransactionDate, currentDate)) {
    return 'Today';
  } else if (isSameDay(
      newTransactionDate, currentDate.subtract(Duration(days: 1)))) {
    return 'Yesterday';
  } else {
    // Format the date as desired (e.g., "MM/dd/yyyy").
    return DateFormat('dd/MM/yyyy').format(newTransactionDate);
  }
}

// Helper function to check if two DateTime objects represent the same day.
bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}
