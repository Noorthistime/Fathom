import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/message_model.dart';
import '../../../../core/constants/constants.dart';

class GeminiRemoteDataSource {
  GenerativeModel _getModel(String apiKey) {
    return GenerativeModel(
      model: AppConstants.defaultGeminiModel,
      apiKey: apiKey,
    );
  }

  Future<String> generateResponse({
    required String apiKey,
    required List<MessageModel> history,
    required String prompt,
  }) async {
    final model = _getModel(apiKey);
    
    // Map previous messages to Gemini's Content format
    final contents = history.map((msg) {
      if (msg.role == 'user') {
        return Content.text(msg.content);
      } else {
        return Content.model([TextPart(msg.content)]);
      }
    }).toList();
    
    contents.add(Content.text(prompt));
    
    final response = await model.generateContent(contents);
    if (response.text == null) {
      throw Exception("Gemini returned empty response.");
    }
    return response.text!;
  }

  Future<String> generateChatTitle({
    required String apiKey,
    required String firstPrompt,
  }) async {
    final model = _getModel(apiKey);
    final prompt = "Generate a very short, maximum 4-word title for a chat conversation that begins with the following prompt: \"$firstPrompt\". Return only the title text, nothing else, no quotes.";
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? firstPrompt;
  }
}
