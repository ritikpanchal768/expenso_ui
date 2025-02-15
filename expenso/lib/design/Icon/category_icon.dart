import 'package:flutter/material.dart';

class CategoryIcons {
  static IconData getIcon(String category) {
    // Replace spaces with underscores
    String formattedCategory = category.replaceAll(" ", "_");
    // return Icons.formattedCategory;
    switch (formattedCategory) {
      case "Food":
        return Icons.food_bank;
      case "Transport":
        return Icons.directions_car;
      case "Entertainment":
        return Icons.movie;
      case "Health":
        return Icons.fitness_center;
      case "Utilities":
        return Icons.lightbulb;
      case "Online_Shopping":
        return Icons.shopping_cart;
      case "Dining_Out":
        return Icons.restaurant;
      case "Medical_Bills":
        return Icons.local_hospital;
      default:
        return Icons.category; // Default icon
    }
  }
}
