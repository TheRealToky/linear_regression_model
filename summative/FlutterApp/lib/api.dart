import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fields.dart';

const predictUrl = 'https://power-draw-api.onrender.com/predict';

/// An error message that is ready to show to the user.
class PredictionError implements Exception {
  const PredictionError(this.message);
  final String message;
}

/// Sends the inputs to the API and returns the predicted power in watts.
/// Throws [PredictionError] with a readable message when anything goes wrong.
Future<double> predictPower(Map<String, Object> body) async {
  final http.Response response;
  try {
    response = await http
        .post(
          Uri.parse(predictUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        // Render's free plan sleeps when idle and can take ~1 minute to wake up
        .timeout(const Duration(seconds: 90));
  } on TimeoutException {
    throw const PredictionError(
      'The server took too long to answer. Please try again.',
    );
  } on Exception {
    throw const PredictionError(
      'Could not reach the server. Check your internet connection.',
    );
  }

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return (json['predicted_power_w'] as num).toDouble();
  }

  // 422 = the API rejected some inputs: one line per field, e.g.
  // "Payload (g): Input should be less than or equal to 750"
  if (response.statusCode == 422) {
    final json = jsonDecode(response.body);
    final labels = {for (final field in inputFields) field.key: field.label};
    final lines = [
      for (final error in json['detail'] as List)
        '${labels[(error['loc'] as List).last] ?? 'Input'}: ${error['msg']}',
    ];
    throw PredictionError(lines.join('\n'));
  }

  throw PredictionError(
    'The server returned an error (${response.statusCode}). Please try again.',
  );
}
