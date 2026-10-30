import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const ploneBaseUrl = 'http://10.163.138.218:8081/Plone/';

void main() {
  runApp(const MaterialApp(home: NewsPage()));
}

Future<List<dynamic>> fetchNews() async {
  final searchUri = Uri.parse(
    '${ploneBaseUrl}@search'
    '?portal_type=News%20Item'
    '&review_state=published'
    '&fullobjects=1'
    '&sort_on=created'
    '&sort_order=reverse',
  );

  final response = await http.get(
    searchUri,
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode != 200) {
    throw Exception('Could not load news: ${response.statusCode}');
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data['items'] as List<dynamic>? ?? [];
}

String? imageUrlFor(Map<String, dynamic> article) {
  final image = article['image'];

  String? path;
  if (image is String) {
    path = image;
  } else if (image is Map<String, dynamic>) {
    path = image['download'] as String? ?? image['url'] as String?;
  }

  if (path == null || path.isEmpty) return null;
  return Uri.parse(ploneBaseUrl).resolve(path).toString();
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
                leading: ArticleThumbnail(url: imageUrlFor(article)),
                title: Text(article['title'] as String? ?? 'Untitled'),
                subtitle: Text(
                  article['description'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticlePage(article: article),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ArticleThumbnail extends StatelessWidget {
  const ArticleThumbnail({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return const SizedBox(
        width: 72,
        height: 56,
        child: Icon(Icons.article_outlined),
      );
    }

    return Image.network(
      url!,
      width: 72,
      height: 56,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          width: 72,
          height: 56,
          child: Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}

class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key, required this.article});

  final Map<String, dynamic> article;

  @override
  Widget build(BuildContext context) {
    final title = article['title'] as String? ?? 'Untitled';
    final description = article['description'] as String? ?? '';
    final imageUrl = imageUrlFor(article);

    return Scaffold(
      appBar: AppBar(title: const Text('News')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.network(
                imageUrl,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(description),
          ],
        ),
      ),
    );
  }
}
