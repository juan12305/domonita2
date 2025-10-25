# TODO: Integrate Google Gemini AI, Supabase, and New Features

## Completed Tasks
- [x] Analyze existing code and create plan
- [x] Get user approval for plan
- [x] Update pubspec.yaml: Add google_generative_ai: ^0.4.7 dependency

## Pending Tasks
- [x] Optimize Hive Storage in SensorRepository: Add _lastSaved, modify _saveToHive to save only if 1 min passed, limit to 200 records
- [x] Add FAN Controls: In SensorRepository add sendFanOn/sendFanOff, in SensorController add turnFanOn/turnFanOff
- [x] Implement Auto Mode: Add _isAutoMode in SensorController, toggleAutoMode, create GeminiService with auto decision method
- [x] Update ControlPage: Add Manual/Auto switch, FAN buttons (manual only), navigate to AI chat button, disable manual in auto
- [x] Create GeminiService: Initialize model, methods for auto, analysis, chat
- [x] Create AI Chat Page (ai_chat_page.dart): Scaffold, analysis card/button, chat UI, Supabase integration
- [x] Update Main.dart: Add '/ai_chat' route
- [x] Handle GEMINI_API_KEY in app (e.g., in constants or main.dart)

## Followup Steps
- [ ] Run flutter pub get
- [ ] Test FAN WebSocket commands
- [ ] Test Gemini API calls
- [ ] Test Supabase chat messages
- [ ] Verify Hive optimization
