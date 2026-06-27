import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../utilities/openai.dart';
import 'mentor_provider.dart';

final aiStatisticsAnalysisProvider = FutureProvider.autoDispose<String?>((ref) async {
  final systemPrompt = ref.watch(mentorSystemPromptProvider);
  
  final messages = [
    {"role": "system", "content": systemPrompt},
    {
      "role": "user", 
      "content": "Analiza mi situación y dame 2-3 recomendaciones accionables y breves. NO repitas cifras que ya están en los gráficos (ventas, utilidad, etc.). Sé directo y conciso, máximo 3 oraciones cortas."
    }
  ];

  return await requestOpenAiResponse(messages);
});
