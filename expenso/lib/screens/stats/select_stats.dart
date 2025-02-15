import 'package:expenso/screens/stats/selected_stats.dart';
import 'package:flutter/material.dart';

class CardSelectionScreen extends StatefulWidget {
  @override
  _CardSelectionScreenState createState() => _CardSelectionScreenState();
}

class _CardSelectionScreenState extends State<CardSelectionScreen> {
  final List<String> cardTitles = [
    "Category Wise Expense",
    "Coming soon...",
    "Coming soon...",
    "Coming soon...",
    "Coming soon...",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select a Card")),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: cardTitles.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0), // Space between cards
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(title: cardTitles[index]),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    cardTitles[index],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios), // Right arrow icon
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
