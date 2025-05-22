import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportmaster_ai/config/app_config.dart';

class EmbeddingService {
  final String _baseUrl = AppConfig.genericApiBaseUrl; // Assuming embedding service uses the generic API
  final String _apiKey = AppConfig.genericApiKey;
  
  // Constructor can be simplified
  // EmbeddingService();

  // Gera embeddings para texto usando modelo sentence-transformers
  Future<List<double>> generateEmbedding(String text) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/embeddings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'text': text,
        'model': 'sentence-transformers/all-MiniLM-L6-v2'
      }),
    );
    
    // Add .timeout(Duration(seconds: 15)) here for production
    // Add general try-catch here to log to MonitoringService for any other exception
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('embedding') && data['embedding'] is List) {
          return List<double>.from(data['embedding'].map((e) => (e as num).toDouble()));
        } else {
          // Consider logging this error to MonitoringService
          print('Unexpected embedding response structure: ${response.body}');
          throw Exception('Unexpected embedding response structure');
        }
      } on FormatException catch (e, stackTrace) {
        // Consider logging this error to MonitoringService
        print('Malformed JSON for embedding response: ${response.body}, Error: $e');
        throw Exception('Malformed JSON for embedding response');
      }
    } else {
      // Consider logging this error to MonitoringService, including text, response.statusCode, response.body
      print('Failed to generate embedding for text "$text": ${response.statusCode} ${response.body}');
      throw Exception('Failed to generate embedding. Status: ${response.statusCode}');
    }
  }
  
  // Cache de embeddings frequentes
  final Map<String, List<double>> _embeddingCache = {};
  
  Future<List<double>> getCachedEmbedding(String text) async {
    if (_embeddingCache.containsKey(text)) {
      return _embeddingCache[text]!;
    }
    
    final embedding = await generateEmbedding(text);
    _embeddingCache[text] = embedding;
    return embedding;
  }
  
  // Gera embedding para descrição física do usuário
  Future<List<double>> generatePhysicalEmbedding(Map<String, dynamic> physicalData) async {
    // Converter dados físicos em texto descritivo
    final description = _buildPhysicalDescription(physicalData);
    return getCachedEmbedding(description); // Use cache for physical embeddings
  }
  
  String _buildPhysicalDescription(Map<String, dynamic> physicalData) {
    final List<String> descriptions = [];
    
    if (physicalData.containsKey('height')) {
      descriptions.add('Altura: ${physicalData['height']}cm');
    }
    
    if (physicalData.containsKey('weight')) {
      descriptions.add('Peso: ${physicalData['weight']}kg');
    }
    
    if (physicalData.containsKey('body_fat')) {
      descriptions.add('Gordura corporal: ${physicalData['body_fat']}%');
    }
    
    // Adicionar outras métricas específicas por esporte
    if (physicalData.containsKey('sport_type')) {
      switch (physicalData['sport_type']) {
        case 'football':
          if (physicalData.containsKey('speed')) {
            descriptions.add('Velocidade: ${physicalData['speed']}km/h');
          }
          break;
        case 'bodybuilding':
          if (physicalData.containsKey('chest')) {
            descriptions.add('Peitoral: ${physicalData['chest']}cm');
          }
          break;
      }
    }
    
    return descriptions.join(', ');
  }
}