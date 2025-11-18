import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/prompt.dart';

class PromptRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, String> _cache = {};
  bool _initialized = false;

  Future<void> init() async {
    try {
      await _loadPromptsFromSupabase();
      _initialized = true;
      debugPrint('PromptRepository: Initialized with ${_cache.length} prompts');
    } catch (e) {
      debugPrint('PromptRepository: Error loading prompts: $e');
      // Fallback a prompts por defecto si falla la carga
      _loadDefaultPrompts();
      _initialized = true;
    }
  }

  Future<void> _loadPromptsFromSupabase() async {
    final response = await _supabase
        .from('prompts')
        .select('key, template')
        .order('key');

    _cache.clear();
    for (final item in response) {
      _cache[item['key'] as String] = item['template'] as String;
    }
  }

  void _loadDefaultPrompts() {
    // Prompts de emergencia por si falla Supabase
    _cache = {
      'auto_decision': '''Eres un sistema de control automático IoT. Toma decisiones basadas en los sensores.

**Sensores:**
- light: 0 = mucha luz, 1 = poca luz
- temperature: en grados Celsius

**Reglas:**
- Si light = 1 → light_action = "ON" (encender bombillo)
- Si light = 0 → light_action = "OFF"
- Si temperature >= 22 → fan_action = "ON" (encender ventilador)
- Si temperature < 22 → fan_action = "OFF"

Responde estrictamente en formato JSON:
{"light_action": "ON/OFF", "fan_action": "ON/OFF", "reason": "explicación corta"}

Datos actuales: {{sensor_json}}''',
      'analysis': '''Analiza estos datos de sensores IoT y genera un resumen corto (menos de 100 palabras).
Menciona:
- Promedio, mínima y máxima de temperatura
- Estado de humedad
- Frecuencia de poca luz
- Recomendación simple

Datos JSON: {{recent_sensor_json}}''',
      'chat': '''{{sensor_context}}Eres un asistente IoT de hogar inteligente. Tu función es responder preguntas sobre sensores, bombillos y ventiladores.

**Instrucciones:**
- Responde siempre en español.
- Sé breve (máx. 80 palabras).
- Si el usuario pide una acción, responde solo con un JSON:
  {"response": "mensaje breve", "actions": ["turn_led_on", "turn_fan_off"]}
- Si es solo conversación o resumen, responde texto plano, sin formato JSON.

{{history}}
Usuario: "{{user_message}}"''',
      'voice_command': '''Eres un asistente de domótica. El usuario dijo: "{{command}}"

Datos actuales de los sensores:
- Temperatura: {{temperature}}°C
- Humedad: {{humidity}}%
- Luz: {{light}}

Interpreta el comando y responde en formato JSON:
{
  "light_action": "ON" o "OFF" o "NO_CHANGE",
  "fan_action": "ON" o "OFF" o "NO_CHANGE",
  "reason": "explicación breve de la acción"
}

Comandos válidos:
- Encender/apagar luz/bombillo/lámpara
- Encender/apagar ventilador/fan
- Encender/apagar todo
- Apagar todo

Responde SOLO con el JSON, sin texto adicional.''',
    };
  }

  String render(String key, Map<String, String> vars) {
    if (!_initialized) {
      throw StateError('PromptRepository no está inicializado');
    }

    String? template = _cache[key];
    if (template == null) {
      throw ArgumentError('Prompt "$key" no encontrado');
    }

    vars.forEach((placeholder, value) {
      template = template!.replaceAll('{{$placeholder}}', value);
    });

    return template!;
  }

  // Método para actualizar un prompt en Supabase
  Future<void> updatePrompt(String key, String template) async {
    await _supabase
        .from('prompts')
        .update({
          'template': template,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('key', key);

    // Actualizar cache local
    _cache[key] = template;
  }

  // Método para obtener todos los prompts
  Future<List<Prompt>> getAllPrompts() async {
    final response = await _supabase
        .from('prompts')
        .select()
        .order('key');

    return response.map((json) => Prompt.fromJson(json)).toList();
  }

  // Método para refrescar cache desde Supabase
  Future<void> refresh() async {
    await _loadPromptsFromSupabase();
  }

  // Obtener un prompt específico
  String? getPrompt(String key) {
    return _cache[key];
  }
}
