import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(home: NewsPage()));
}

Future<List<dynamic>> fetchNews() async {
  final uri = Uri.parse(
    'http://10.163.138.218:8081/Plone/@search'
    '?portal_type=News%20Item&review_state=published',
  );

  final response = await http.get(
    uri,
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw Exception('Could not load news: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data['items'] as List<dynamic>;
}

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Latest News')),
      body: FutureBuilder<List<dynamic>>(
        future: fetchNews(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final articles = snapshot.data!;
          if (articles.isEmpty) {
            return const Center(child: Text('No published articles yet.'));
          }

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index] as Map<String, dynamic>;
              return ListTile(
                title: Text(article['title'] ?? 'Untitled'),
                subtitle: Text(article['description'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
