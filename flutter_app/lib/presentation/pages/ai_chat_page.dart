import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/repositories/sensor_repository.dart';
import '../../data/services/gemini_service.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/particle_field.dart';
import '../theme/color_utils.dart';
import '../../l10n/l10n_extensions.dart';
import '../widgets/ai_chat/chat_helpers.dart';
import '../widgets/ai_chat/quick_actions_bar.dart';
import '../widgets/ai_chat/message_input_bar.dart';
import '../widgets/ai_chat/chat_message_bubble.dart';
import '../widgets/ai_chat/chat_empty_state.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isChatLoading = false;
  bool _isAnalysisLoading = false;
  int _currentChatId = 1;

  late GeminiService _geminiService;
  
  @override
  void initState() {
    super.initState();
    final controller = Provider.of<SensorController>(context, listen: false);
    _geminiService = controller.geminiService;
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('chat_history')
          .select('message, response, created_at, chat_id')
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      if (response.isNotEmpty) {
        // Find the latest chat_id
        final maxChatId = response.map((r) => r['chat_id'] as int? ?? 0).reduce((a, b) => a > b ? a : b);
        _currentChatId = maxChatId + 1;

        // Load only messages from the latest chat
        final latestChatMessages = response.where((r) => r['chat_id'] == maxChatId).toList();

        setState(() {
          _messages.clear();
          for (final row in latestChatMessages) {
            _messages.add({'user': row['message'], 'ai': row['response']});
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading chat history from Supabase: $e');
      // Continue without loading history
    }
  }

  Future<void> _startNewChat() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Buscar el maximo chat_id actual del usuario
      final response = await Supabase.instance.client
          .from('chat_history')
          .select('chat_id')
          .eq('user_id', userId);

      int newChatId = 1;
      if (response.isNotEmpty) {
        final ids = response.map((r) => r['chat_id'] as int? ?? 0);
        newChatId = (ids.reduce((a, b) => a > b ? a : b)) + 1;
      }

      setState(() {
        _messages.clear();
        _currentChatId = newChatId;
      });

      debugPrint('Nuevo chat creado con chat_id=$_currentChatId');

    } catch (e) {
      debugPrint('Error al crear nuevo chat: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final l10n = context.l10n;
    debugPrint('AiChatPage: Sending message: "$message"');
    setState(() => _isChatLoading = true);
    _messageController.clear();

    // ✅ Obtener los datos mas recientes de los sensores
    final repository = Provider.of<SensorRepository>(context, listen: false);
    final data = repository.allSensorData.take(50).toList(); // puedes ajustar el numero
    debugPrint('AiChatPage: Loaded ${data.length} sensor readings');

    // Construir historial del chat
    final history = _messages.map((m) => '${m['user']}: ${m['ai']}').toList();

    // ✅ Pasar los datos del sensor al servicio de Gemini
    final responseData = await _geminiService.chatResponse(
      message,
      history,
      sensorData: data, // 🔥 Nuevo parametro con datos reales
    );

    debugPrint('AiChatPage: Received response data: $responseData');
    if (!mounted) return;

    String aiResponse = l10n.literal(
      es: 'Error: No se pudo obtener respuesta de la IA',
      en: 'Error: Could not obtain a response from the AI',
    );
    if (responseData != null) {
      final rawResponse = responseData['response'];
      if (rawResponse is String) {
        aiResponse = rawResponse;
      } else if (rawResponse is Map) {
        aiResponse = rawResponse['response'] ?? aiResponse;
      }

      final actions = responseData['actions'] as List<dynamic>? ?? [];
      final controller = Provider.of<SensorController>(context, listen: false);
      final normalizedMessage = stripDiacritics(message.toLowerCase());
      final AutoIntent autoIntent = detectAutoIntent(normalizedMessage);
      final bool userForcedAutoOn = autoIntent == AutoIntent.on;
      final bool userForcedAutoOff = autoIntent == AutoIntent.off;
      var userMentionsFan = containsAny(normalizedMessage, ['ventilador', 'fan']);
      var userMentionsLight =
          containsAny(normalizedMessage, ['bombillo', 'luz', 'light']);
      final bool restrictToAutoOnly =
          autoIntent != AutoIntent.none && !userMentionsFan && !userMentionsLight;

      var executedAction = false;
      final executedMessages = <String>[];

      void addExecutedMessage(String text) {
        if (!executedMessages.contains(text)) {
          executedMessages.add(text);
        }
      }

      final autoOnText = l10n.literal(
        es: 'Modo automático activado.',
        en: 'Auto mode enabled.',
      );
      final autoOffText = l10n.literal(
        es: 'Modo automático desactivado.',
        en: 'Auto mode disabled.',
      );
      final lightOnText = l10n.literal(
        es: 'Bombillo encendido.',
        en: 'Light turned on.',
      );
      final lightOffText = l10n.literal(
        es: 'Bombillo apagado.',
        en: 'Light turned off.',
      );
      final fanOnText = l10n.literal(
        es: 'Ventilador encendido.',
        en: 'Fan turned on.',
      );
      final fanOffText = l10n.literal(
        es: 'Ventilador apagado.',
        en: 'Fan turned off.',
      );

      if (autoIntent == AutoIntent.on) {
        controller.setAutoMode(true);
        addExecutedMessage(autoOnText);
        executedAction = true;
      } else if (autoIntent == AutoIntent.off) {
        controller.setAutoMode(false);
        addExecutedMessage(autoOffText);
        executedAction = true;
      }

      final userHandledMessages = handleNaturalLanguageIntent(
        message,
        controller,
        l10n,
      );
      if (userHandledMessages.isNotEmpty) {
        for (final handled in userHandledMessages) {
          addExecutedMessage(handled.text);
          if (handled.affectedLight) userMentionsLight = true;
          if (handled.affectedFan) userMentionsFan = true;
        }
        executedAction = true;
      }

      for (final dynamic rawAction in actions) {
        final actionValue = normalizeAction(rawAction);
        if (actionValue == null) {
          debugPrint('AiChatPage: Ignoring invalid action $rawAction');
          continue;
        }

        final action = actionValue.toUpperCase();
        if (restrictToAutoOnly &&
            (action.contains('LIGHT') || action.contains('LED') || action.contains('FAN'))) {
          debugPrint(
            'AiChatPage: Skipping $action because user requested only auto mode change',
          );
          continue;
        }

        if (looksLikeAutoModeOnAction(action)) {
          if (userForcedAutoOff) {
            debugPrint('AiChatPage: Skipping $action because user requested AUTO OFF');
            continue;
          }
          controller.setAutoMode(true);
          addExecutedMessage(autoOnText);
          executedAction = true;
          continue;
        }
        if (looksLikeAutoModeOffAction(action)) {
          if (userForcedAutoOn) {
            debugPrint('AiChatPage: Skipping $action because user requested AUTO ON');
            continue;
          }
          controller.setAutoMode(false);
          addExecutedMessage(autoOffText);
          executedAction = true;
          continue;
        }

        debugPrint('AiChatPage: Executing action $action');
        switch (action) {
          case 'TURN_LED_ON':
          case 'TURN_LIGHT_ON':
          case 'LED_ON':
          case 'LIGHT_ON':
            controller.turnLedOn();
            addExecutedMessage(lightOnText);
            userMentionsLight = true;
            executedAction = true;
            break;
          case 'TURN_LED_OFF':
          case 'TURN_LIGHT_OFF':
          case 'LED_OFF':
          case 'LIGHT_OFF':
          case 'TURN OFF LIGHT':
          case 'APAGAR LUZ':
          case 'APAGAR BOMBILLO':
          case 'TURN OFF THE LIGHT':
            controller.turnLedOff();
            addExecutedMessage(lightOffText);
            userMentionsLight = true;
            executedAction = true;
            break;
          case 'TURN_FAN_ON':
          case 'FAN_ON':
          case 'TURN_ON_FAN':
            controller.turnFanOn();
            addExecutedMessage(fanOnText);
            userMentionsFan = true;
            executedAction = true;
            break;
          case 'TURN_FAN_OFF':
          case 'FAN_OFF':
          case 'TURN_OFF_FAN':
          case 'TURN OFF FAN':
          case 'TURN_OFF_THE_FAN':
          case 'APAGAR VENTILADOR':
            controller.turnFanOff();
            addExecutedMessage(fanOffText);
            userMentionsFan = true;
            executedAction = true;
            break;
          default:
            debugPrint('AiChatPage: Unknown action $rawAction');
        }
      }

      if (!executedAction) {
        final combinedText = '$message $aiResponse';
        final handledMessages = handleNaturalLanguageIntent(
          combinedText,
          controller,
          l10n,
        );
        if (handledMessages.isEmpty) {
          debugPrint('AiChatPage: No actionable command detected.');
        } else {
          for (final handled in handledMessages) {
            addExecutedMessage(handled.text);
          }
          executedAction = true;
        }
      }

      if (executedMessages.isNotEmpty) {
        aiResponse = executedMessages.join('\n');
      }
    }

    setState(() {
      _messages.add({'user': message, 'ai': aiResponse});
      _isChatLoading = false;
    });

    // Scroll automatico
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Guardar en Supabase
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client.from('chat_history').insert({
          'user_id': userId,
          'message': message,
          'response': aiResponse,
          'chat_id': _currentChatId,
          'analysis_data': data.map((d) => d.toJson()).toList(), // ✅ guardar tambien los datos
        });
      } catch (e) {
        debugPrint('Error saving message to Supabase: $e');
      }
    }
  }

  void _showAnalysisDialog(BuildContext context) async {
    setState(() => _isAnalysisLoading = true);
    final repository = Provider.of<SensorRepository>(context, listen: false);
    final data = repository.allSensorData.take(100).toList();
    final l10n = context.l10n;

    final analysis = await _geminiService.generateAnalysis(data);
    if (!context.mounted) return;
    setState(() => _isAnalysisLoading = false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: adjustOpacity(Colors.tealAccent, 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.tealAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.literal(
                          es: 'Análisis de Datos del Sistema',
                          en: 'System Data Analysis',
                        ),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Text(
                      analysis,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.literal(es: 'Cerrar', en: 'Close'),
                        style: GoogleFonts.poppins(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    // Save analysis to Supabase
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client.from('chat_history').insert({
          'user_id': userId,
          'message': l10n.literal(
            es: 'Generar análisis',
            en: 'Generate analysis',
          ),
          'response': analysis,
          'analysis_data': data.map((d) => d.toJson()).toList(),
        });
      } catch (e) {
        debugPrint('Error saving analysis to Supabase: $e');
        // Continue without saving to DB
      }
    }
  }

  void _showChatHistory(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.literal(
              es: 'Usuario no autenticado',
              en: 'User not authenticated',
            ),
          ),
        ),
      );
      return;
    }
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF16213E),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        color: Colors.tealAccent,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.literal(
                          es: 'Historial de Chats',
                          en: 'Chat History',
                        ),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: Supabase.instance.client
                        .from('chat_history')
                        .select('message, response, created_at, chat_id')
                        .eq('user_id', userId)
                        .order('created_at', ascending: false)
                        .limit(50),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.tealAccent),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            l10n.literal(
                              es: 'Error al cargar el historial',
                              en: 'Error loading history',
                            ),
                            style: GoogleFonts.poppins(color: Colors.redAccent),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history_toggle_off,
                                color: Colors.white38,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.literal(
                                  es: 'No hay chats en el historial',
                                  en: 'No chats in history',
                                ),
                                style: GoogleFonts.poppins(
                                  color: Colors.white38,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Group messages into chats based on time gaps (e.g., 30 minutes)
                      // Use messages in ascending order (oldest first) for proper grouping
                      final chats = _groupMessagesIntoChats(messages);

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final firstMessage = chat.first;
                          final startTime = DateTime.parse(firstMessage['created_at']).toLocal();

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              _loadChat(chat);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F23),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: adjustOpacity(Colors.white, 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.chat,
                                        color: Colors.tealAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${l10n.literal(es: 'Chat', en: 'Chat')} ${index + 1}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${startTime.day}/${startTime.month} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${chat.length} mensajes',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    chat.first['message'] ?? 'Mensaje vacio',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<List<Map<String, dynamic>>> _groupMessagesIntoChats(List<Map<String, dynamic>> messages) {
    final Map<int, List<Map<String, dynamic>>> grouped = {};

    for (final message in messages) {
      final chatId = message['chat_id'] as int? ?? 0;
      grouped.putIfAbsent(chatId, () => []).add(message);
    }

    // Ordenar los chats por chat_id descendente (ultimo chat primero)
    final sortedChats = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return sortedChats.map((e) => e.value).toList();
  }

  void _loadChat(List<Map<String, dynamic>> chatMessages) {
    setState(() {
      _messages.clear();
      for (final msg in chatMessages.reversed) { // Reverse to chronological order
        _messages.add({'user': msg['message'], 'ai': msg['response']});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sensorData = context.watch<SensorController>().sensorData;
    final l10n = context.l10n;
    final gradient = (sensorData?.light == 0)
        ? AppColors.dayGradient
        : AppColors.nightGradient;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isTablet = width >= 720;
        final bool isVeryCompact = width < 360;
        final bool isCompact = width < 480;
        final bool isLandscape = mediaQuery.orientation == Orientation.landscape;
        final double contentMargin = isTablet ? 28.0 : isVeryCompact ? 12.0 : 16.0;
        final double listHorizontalPadding = isTablet ? 24.0 : isVeryCompact ? 12.0 : 16.0;
        final double listVerticalPadding = isTablet ? 24.0 : 16.0;
        final double innerWidth = width - (contentMargin * 2);
        final double listContentWidth = innerWidth - (listHorizontalPadding * 2);
        final double safeListWidth = listContentWidth > 0 ? listContentWidth : innerWidth;
        final double bubbleSideInset = isTablet
            ? math.min(safeListWidth * 0.2, 120.0)
            : (safeListWidth < 320 ? 12.0 : 20.0);
        final double rawBubbleWidth = safeListWidth - bubbleSideInset;
        final double safeBubbleWidth = rawBubbleWidth > 0
            ? rawBubbleWidth
            : (safeListWidth > 0 ? safeListWidth : width * 0.9);
        final double bubbleMaxWidth = isTablet
            ? math.min(safeBubbleWidth, 540.0)
            : safeBubbleWidth;
        final double titleFontSize = isTablet ? 20.0 : isCompact ? 17.0 : 18.5;
        final double titleIconPadding = isCompact ? 6.0 : 8.0;
        final double titleIconSize = isCompact ? 20.0 : 24.0;
        final double titleSpacing = isCompact ? 8.0 : 12.0;
        final EdgeInsets inputOuterMargin = EdgeInsets.symmetric(
          horizontal: contentMargin,
          vertical: isTablet ? 24.0 : 12.0,
        );
        final EdgeInsets inputInnerPadding = EdgeInsets.symmetric(
          horizontal: isTablet ? 24.0 : isVeryCompact ? 16.0 : 20.0,
          vertical: isTablet ? 16.0 : isVeryCompact ? 10.0 : 12.0,
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(gradient: gradient),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(titleIconPadding),
                  decoration: BoxDecoration(
                    color: adjustOpacity(Colors.tealAccent, 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.tealAccent,
                    size: titleIconSize,
                  ),
                ),
                SizedBox(width: titleSpacing),
                Flexible(
                  child: Text(
                    l10n.literal(es: 'Asistente IA', en: 'AI assistant'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.tealAccent),
                onPressed: _startNewChat,
                tooltip: l10n.literal(es: 'Nuevo chat', en: 'New chat'),
              ),
              IconButton(
                icon: const Icon(Icons.history, color: Colors.tealAccent),
                onPressed: () => _showChatHistory(context),
                tooltip: l10n.literal(
                  es: 'Ver historial completo',
                  en: 'View full history',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.tealAccent),
                onPressed: _loadChatHistory,
                tooltip: l10n.literal(
                  es: 'Recargar historial',
                  en: 'Refresh history',
                ),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const ParticleField(),
              AnimatedContainer(
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(gradient: gradient),
              ),
              SafeArea(
                child: Column(
                  children: [
                    QuickActionsBar(
                      isLoading: _isAnalysisLoading,
                      isTablet: isTablet,
                      messageCount: _messages.length,
                      onGenerateAnalysis: () => _showAnalysisDialog(context),
                      horizontalPadding: contentMargin,
                    ),
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: contentMargin),
                        decoration: BoxDecoration(
                          color: adjustOpacity(Colors.black, 0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: adjustOpacity(Colors.white, 0.1)),
                        ),
                        child: _messages.isEmpty
                            ? const ChatEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.symmetric(
                                  horizontal: listHorizontalPadding,
                                  vertical: listVerticalPadding,
                                ),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final msg = _messages[index];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ChatMessageBubble(
                                        message: msg['user']!,
                                        isUser: true,
                                        isTablet: isTablet,
                                        maxBubbleWidth: bubbleMaxWidth,
                                        horizontalInset: bubbleSideInset,
                                      ),
                                      const SizedBox(height: 8),
                                      ChatMessageBubble(
                                        message: msg['ai']!,
                                        isUser: false,
                                        isTablet: isTablet,
                                        maxBubbleWidth: bubbleMaxWidth,
                                        horizontalInset: bubbleSideInset,
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ),
                    MessageInputBar(
                      controller: _messageController,
                      isLandscape: isLandscape,
                      isLoading: _isChatLoading,
                      isTablet: isTablet,
                      outerMargin: inputOuterMargin,
                      innerPadding: inputInnerPadding,
                      onSend: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

