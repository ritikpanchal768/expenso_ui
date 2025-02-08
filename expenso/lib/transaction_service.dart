import 'package:expenso/logs.dart';
import 'package:expenso/read_sms.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class TransactionService {
  static String apiUrl =
      "$baseUrl/expenso/api/v1/transaction/viewByMobileNumber/";

  static Future<List<dynamic>> fetchTransactions(String mobileNumber) async {
    print("Transaction fetching .......");
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
        response : response
      );
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
}
