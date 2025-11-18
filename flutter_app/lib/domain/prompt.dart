class Prompt {
  final String id;
  final String key;
  final String template;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Prompt({
    required this.id,
    required this.key,
    required this.template,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      key: json['key'] as String,
      template: json['template'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'template': template,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
