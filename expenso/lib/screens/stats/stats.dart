import 'package:expenso/screens/home/views/mainscreen.dart';
import 'package:expenso/transaction_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chart.dart';

class StatScreen extends StatefulWidget {
  const StatScreen({super.key});

  @override
  State<StatScreen> createState() => _StatScreenState();
}

List<dynamic> statTransactions = [];



class _StatScreenState extends State<StatScreen> {
  @override
  void initState() {
    super.initState();
    loadTransactions();
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
      
      setState(() {
        statTransactions =
            fetchedTransactions; // Update state with fetched transactions
      });
    } catch (e) {
      print("Error loading transactions: $e");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)
              ),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: MyChart(),
              )
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
                    itemCount: statTransactions.length,
                    itemBuilder: (context, int i) {
                      var statTransaction = statTransactions[i];
                      if (statTransaction['category'] == null) {
                        statTransaction['category'] = 'Not Added';
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
                                      statTransaction['category'],
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
                                          statTransaction['amount']
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
                                          statTransaction['transactionDate']),
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
    );
  }
}