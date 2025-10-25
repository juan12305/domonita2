import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'data/repositories/sensor_repository.dart';
import 'domain/sensor_data.dart';
import 'domain/actuator.dart';
import 'presentation/controllers/sensor_controller.dart';
import 'presentation/pages/control_page.dart';
import 'presentation/pages/register_page.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/history_page.dart';
import 'presentation/pages/ai_chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://ujlssaucwnaunizxqphg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqbHNzYXVjd25hdW5penhxcGhnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNjk3OTEsImV4cCI6MjA3NTk0NTc5MX0.j9j-evd2nvdCApNCAfiUZnXIEq7hi6WmqjviZawxttg',
  );

  // Inicializar Hive
  await Hive.initFlutter();
  Hive.registerAdapter(SensorDataAdapter());
  Hive.registerAdapter(ActuatorAdapter());

  // ✅ Inicializar el repositorio *antes* del runApp
  final repository = SensorRepository(websocketUrl: 'wss://domotica-ws.onrender.com');
  await repository.init(); // 👈 Esperar a que la conexión WebSocket esté lista

  // Gemini API Key (consider using environment variables or secure storage)
  const String geminiApiKey = 'AIzaSyBgeAP1A2L8y7JUHnjw8-GQDPAnD_ilyJE';

  runApp(MyApp(repository: repository, geminiApiKey: geminiApiKey));
}

class MyApp extends StatelessWidget {
  final SensorRepository repository;
  final String geminiApiKey;

  const MyApp({super.key, required this.repository, required this.geminiApiKey});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositorio principal
        ChangeNotifierProvider.value(value: repository),

        // Controlador dependiente del repositorio
        ChangeNotifierProvider(
          create: (_) => SensorController(repository: repository, geminiApiKey: geminiApiKey),
        ),
      ],
      child: MaterialApp(
        title: 'Domótica App',
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
        },
      ),
    );
  }
}
