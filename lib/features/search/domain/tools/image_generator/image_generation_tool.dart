import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import '../../entities/agent/agent_tool.dart';

class ImageGenerationTool extends AgentTool {
  ImageGenerationTool()
    : super(
        id: 'image_generator',
        name: 'Image Generator',
        description: 'Generates images based on a text prompt.',
      );

  @override
  Future<bool> get isAvailable async {
    final apiKey = await LLMProviderManager.getOpenAIApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'prompt': {
        'type': 'string',
        'description': 'Description of the image to generate',
      },
    },
    'required': ['prompt'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final prompt = input['prompt'] as String;
    final apiKey = await LLMProviderManager.getOpenAIApiKey();

    if (apiKey == null) throw Exception("OpenAI API Key not found");

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({'prompt': prompt, 'n': 1, 'size': '1024x1024'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'imageUrl': data['data'][0]['url'], 'prompt': prompt};
      } else {
        throw Exception('Failed to generate image: ${response.body}');
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
