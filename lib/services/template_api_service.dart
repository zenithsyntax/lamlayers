import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
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

  static Future<String> downloadTemplate(String templateFileUrl) async {
    try {
      final response = await http.get(Uri.parse(templateFileUrl));
      
      if (response.statusCode == 200) {
        // Get temporary directory
        final Directory tempDir = await getTemporaryDirectory();
        
        // Generate unique filename
        final String fileName = 'template_${DateTime.now().millisecondsSinceEpoch}.lamlayers';
        final String filePath = '${tempDir.path}/$fileName';
        
        // Write file to temporary directory
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        return filePath;
      } else {
        throw Exception('Failed to download template: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading template: $e');
    }
  }
}
