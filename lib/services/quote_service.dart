import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteModel {
  final String content;
  final String author;

  QuoteModel({required this.content, required this.author});
}

class QuoteService {
  // ZenQuotes API - https://zenquotes.io/
  static const String _url = 'https://zenquotes.io/api/random';

  Future<QuoteModel> getRandomQuote() async {
    final response = await http.get(Uri.parse(_url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      final quote = data.first;
      return QuoteModel(
        content: quote['q'] as String,
        author: quote['a'] as String,
      );
    } else {
      throw Exception('Gagal mengambil kutipan motivasi');
    }
  }
}
