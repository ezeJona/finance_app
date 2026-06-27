import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'mentor_provider.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<Map<String, String>>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<List<Map<String, String>>> {
  final Ref _ref;
  static const String _boxName = 'chat_history';

  ChatNotifier(this._ref) : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final box = await Hive.openBox(_boxName);
    final history = box.get('messages');
    if (history != null) {
      final List<dynamic> decoded = jsonDecode(history);
      state = decoded.map((e) => Map<String, String>.from(e)).toList();
    } else {
      _initializeChat();
    }
  }

  void _initializeChat() {
    final systemPrompt = _ref.read(mentorSystemPromptProvider);
    state = [
      {"role": "system", "content": systemPrompt},
      {
        "role": "assistant",
        "content": "¡Hola! Soy **Atlas**, tu Mentor Financiero IA. He analizado las estadísticas actuales de tu negocio en tiempo real y estoy listo para ayudarte a llevarlo al siguiente nivel. 📈\n\n¿En qué podemos enfocarnos hoy?"
      }
    ];
    _saveHistory();
  }

  void addMessage(String role, String content) {
    state = [...state, {"role": role, "content": content}];
    _saveHistory();
  }

  void clearHistory() {
    _initializeChat();
  }

  Future<void> _saveHistory() async {
    final box = Hive.box(_boxName);
    await box.put('messages', jsonEncode(state));
  }
}
