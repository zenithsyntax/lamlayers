class TemplateResponse {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<Template> results;

  TemplateResponse({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.results,
  });

  factory TemplateResponse.fromJson(Map<String, dynamic> json) {
    return TemplateResponse(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 1,
      results:
          (json['results'] as List<dynamic>?)
              ?.map((item) => Template.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class Template {
  final int id;
  final String category;
  final String imageUrl;
  final String templateFile;

  Template({
    required this.id,
    required this.category,
    required this.imageUrl,
    required this.templateFile,
  });

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'] ?? 0,
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      templateFile: json['template_file'] ?? '',
    );
  }
}
