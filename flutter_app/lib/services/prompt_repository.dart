import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class PromptRepository {
  Map<String, String> _cache = {};

  Future<void> init() async {
    final raw = await rootBundle.loadString('assets/prompts/prompts.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _cache = map.map((key, value) => MapEntry(key, value.toString()));
  }

  String render(String key, Map<String, String> vars) {
    String? template = _cache[key];
    if (template == null) {
      throw ArgumentError('Prompt "$key" no encontrado');
    }

    vars.forEach((placeholder, value) {
      template = template!.replaceAll('{{$placeholder}}', value);
    });

    return template!;
  }
}
