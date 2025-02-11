import 'dart:convert';
import 'package:http/http.dart' as http;

void printRequestResponse({
  required String method,
  required String url,
  required Map<String, String> headers,
  required Map<String, dynamic> requestBody,
  required http.Response response,
}) {
  // Pretty-print request body
  String formattedRequestBody = JsonEncoder.withIndent('  ').convert(requestBody);

  // Format request headers
  String formattedRequestHeaders = headers.entries
      .map((entry) => '║ ${entry.key}: ${entry.value}')
      .join('\n');

  print("\n════════════════════════════════════ REQUEST ════════════════════════════════════");
  print("╔╣ Request ║ $method");
  print("║  $url");
  print("╚═════════════════════════════════════════════════════════════════════════════════");
  print("╔ Headers");
  print(formattedRequestHeaders);
  print("╚═════════════════════════════════════════════════════════════════════════════════");
  print("╔ Body");
  print(formattedRequestBody);
  print("╚═════════════════════════════════════════════════════════════════════════════════");

  // Pretty-print response body
  String formattedResponseBody;
  try {
    formattedResponseBody = JsonEncoder.withIndent('  ').convert(jsonDecode(response.body));
  } catch (e) {
    formattedResponseBody = response.body; // In case response is not JSON
  }

  // Format response headers
  String formattedResponseHeaders = response.headers.entries
      .map((entry) => '║ ${entry.key}: ${entry.value}')
      .join('\n');

  print("\n════════════════════════════════════ RESPONSE ═══════════════════════════════════");
  print("╔╣ Status Code: ${response.statusCode}");
  print("║  ${response.request?.url}");
  print("╚═════════════════════════════════════════════════════════════════════════════════");
  print("╔ Response Body");
  print(formattedResponseBody);
  print("╚═════════════════════════════════════════════════════════════════════════════════");
}
