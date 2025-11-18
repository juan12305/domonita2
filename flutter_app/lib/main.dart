import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/repositories/sensor_repository.dart';
import 'data/services/gemini_service.dart';
import 'data/services/voice_command_service.dart';
import 'domain/actuator.dart';
import 'domain/sensor_data.dart';
import 'l10n/app_localizations.dart';
import 'presentation/controllers/language_controller.dart';
import 'presentation/controllers/sensor_controller.dart';
import 'presentation/pages/ai_chat_page.dart';
import 'presentation/pages/control_page.dart';
import 'presentation/pages/history_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/register_page.dart';
import 'presentation/pages/voice_control_page.dart';
import 'presentation/pages/admin_prompts_page.dart';
import 'services/prompt_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Inicializar Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SensorDataAdapter());
  Hive.registerAdapter(ActuatorAdapter());

  // Inicializar el repositorio
  final repository = SensorRepository(
    websocketUrl: dotenv.env['WEBSOCKET_URL']!,
  );
  await repository.init();

  // Gemini API Key from environment
  final String geminiApiKey = dotenv.env['GEMINI_API_KEY']!;

  final prompts = PromptRepository();
  await prompts.init();
  final geminiService = GeminiService(geminiApiKey, prompts);
  final voiceService = VoiceCommandService(geminiApiKey, prompts);

  runApp(MyApp(
    repository: repository,
    geminiService: geminiService,
    voiceService: voiceService,
  ));
}

class MyApp extends StatelessWidget {
  final SensorRepository repository;
  final GeminiService geminiService;
  final VoiceCommandService voiceService;

  const MyApp({
    super.key,
    required this.repository,
    required this.geminiService,
    required this.voiceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositorio principal
        ChangeNotifierProvider.value(value: repository),

        // Controlador dependiente del repositorio
        ChangeNotifierProvider(
          create: (_) => SensorController(
            repository: repository,
            geminiService: geminiService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LanguageController(),
        ),
      ],
      child: Consumer<LanguageController>(
        builder: (context, languageController, _) {
          return MaterialApp(
            locale: languageController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateTitle: (context) =>
                AppLocalizations.of(context).t('app_title'),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            debugShowCheckedModeBanner: false,
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginPage(),
              '/register': (context) => const RegisterPage(),
              '/control': (context) => const ControlPage(),
              '/history': (context) => const HistoryPage(),
              '/ai_chat': (context) => const AiChatPage(),
              '/voice_control': (context) =>
                  VoiceControlPage(voiceService: voiceService),
              '/admin_prompts': (context) => const AdminPromptsPage(),
            },
          );
        },
      ),
    );
  }
}
