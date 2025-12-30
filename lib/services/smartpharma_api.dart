import 'dart:convert';
import 'package:http/http.dart' as http;

/// Response wrapper for the Python SmartPharma backend.
class SmartPharmaResponse {
  final String question;
  final String answer;
  final double elapsedSeconds;

  SmartPharmaResponse({
    required this.question,
    required this.answer,
    required this.elapsedSeconds,
  });

  factory SmartPharmaResponse.fromJson(Map<String, dynamic> json) {
    return SmartPharmaResponse(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      elapsedSeconds: (json['elapsed_s'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Helper to interpret the "Verification:" line in the answer.
  bool get isVerified {
    final lines = answer.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.toLowerCase().startsWith('verification:')) {
        final value = trimmed.substring('verification:'.length).toLowerCase();
        return value.contains('verified');
      }
    }
    return false;
  }
}

/// Client that talks to the Python SmartPharma RAG backend (pharmachatbot.py).
class SmartPharmaApi {
  // For Windows desktop / Chrome web, localhost is fine.
  // If you later run on Android emulator, change to 'http://10.0.2.2:5009'.
  static const String _baseUrl = 'http://127.0.0.1:5009';

  Future<SmartPharmaResponse> verifyPrescription(String prompt) async {
    final uri = Uri.parse('$_baseUrl/ask');

    final res = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'question': prompt}),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'SmartPharma backend error (HTTP ${res.statusCode}): ${res.body}',
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(res.body) as Map<String, dynamic>;
    return SmartPharmaResponse.fromJson(json);
  }
}
