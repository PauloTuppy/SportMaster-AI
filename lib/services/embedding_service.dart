import 'dart:convert';
import 'package:http/http.dart' as http;

class EmbeddingService {
  final String _baseUrl;
  final String _apiKey;
  
  EmbeddingService({
    required String baseUrl,
    required String apiKey,
  }) : 
    _baseUrl = baseUrl,
    _apiKey = apiKey;
  
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
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<double>.from(data['embedding']);
    } else {
      throw Exception('Failed to generate embedding: ${response.body}');
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
    return generateEmbedding(description);
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