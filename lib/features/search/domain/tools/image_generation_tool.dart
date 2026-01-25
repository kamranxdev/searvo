import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class ImageGenerationTool extends AgentTool {
  ImageGenerationTool()
    : super(
        id: 'image_generator',
        name: 'Image Generator',
        description: 'Generates images based on a text prompt.',
      );

  @override
  Future<bool> get isAvailable async {
    // Currently disabled until OpenRouter image generation added
    return false;
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
    throw UnimplementedError(
      'Image generation via OpenRouter not yet implemented',
    );
  }
}
