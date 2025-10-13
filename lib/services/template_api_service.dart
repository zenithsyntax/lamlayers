import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/template_models.dart';

class TemplateApiService {
  static const String baseUrl =
      'https://autumn-heart-6d34.zenithsyntax.workers.dev';

  static Future<TemplateResponse> getTemplates({
    int page = 1,
    int limit = 10,
    String? category,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse(
        '$baseUrl/templates',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return TemplateResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load templates: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching templates: $e');
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      // For now, we'll return a static list since the API doesn't provide categories endpoint
      // In a real scenario, you might have a separate endpoint for categories
      return ['All', 'test', 'business', 'personal', 'creative'];
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }
}
