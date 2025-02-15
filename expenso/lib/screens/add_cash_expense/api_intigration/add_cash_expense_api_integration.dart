import 'package:expenso/logs.dart';
import 'package:expenso/read_sms.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AddCashExpenseApiIntegration {
  static Future<dynamic> addCashExpense(
      String mobileNumber, String amount, String category, String date) async {
    String url = "$baseUrl/expenso/api/v1/expense/create/cashExpense";
    const String authorization = "Basic cm9vdDpyaXRpazc2OA==";

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authorization
    };
    final body = jsonEncode({
      "mobileNumber": mobileNumber,
      "amount": amount,
      "category": category,
      "transactionDate": date
    });

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      printRequestResponse(
          method: "POST",
          url: url,
          headers: headers,
          requestBody: ({
            "mobileNumber": mobileNumber,
            "amount": amount,
            "category": category,
            "transactionDate": date
          }),
          response: response);
      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception('Failed to Add Cash Expense');
      }
    } catch (e) {
      print("Error Add Cash Expense: $e");
      return [];
    }
  }

  static Future<List<dynamic>> fetchCategoryWiseTransactions(
      String mobileNumber) async {
    String apiUrl = "$baseUrl/expenso/api/v1/transaction/viewCategoryWise/";
    final String url = "$apiUrl$mobileNumber";
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
          response: response);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['responseObject'] ?? [];
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print("Error fetching transactions: $e");
      return [];
    }
  }

  // Fetch categories from the backend
  static Future<List<String>> fetchCategories() async {
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
          response: response);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        if (responseBody.containsKey("responseObject") &&
            responseBody["responseObject"] is List) {
          // setState(() {
          //   categories = responseBody["responseObject"]; // Ensure it's a List
          // });

          // Extract categories
          List<String> categories = (responseBody['responseObject'] as List)
              .map((item) => item['category'] as String)
              .toList();

          return categories;
        }
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
    return [];
  }
}
