import 'package:google_generative_ai/google_generative_ai.dart';

Future<void> testGemini() async {
  const apiKey = 'AIzaSyBPqumlytFcCalDClhQhJ5gAOjI3xkBWu8';
  
  // Create a Gemini model instance
  final model = GenerativeModel(
    model: 'gemini-2.5-flash-lite',
    apiKey: apiKey,
  );

  // Send a simple request
  final response = await model.generateContent([
    Content.text('Say hello from the Gemini model!')
  ]);

  print('Gemini reply: ${response.text}');
}
