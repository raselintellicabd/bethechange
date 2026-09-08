import 'blog_article.dart';

class BlogCatalog {
  const BlogCatalog({required this.articles});

  final List<BlogArticle> articles;

  BlogArticle? byId(String id) {
    for (final article in articles) {
      if (article.id == id) return article;
    }
    return null;
  }

  factory BlogCatalog.fromJson(Map<String, dynamic> json) {
    final articles = (json['articles'] as List<dynamic>? ?? const [])
        .map((item) => BlogArticle.fromJson(item as Map<String, dynamic>))
        .toList();
    return BlogCatalog(articles: articles);
  }
}
