import 'dart:convert';
import 'package:http/http.dart' as http;

class LangGraphService {
  final String _baseUrl = 'https://api.sportmaster.ai/langgraph';
  
  Future<Map<String, dynamic>> processDecisionFlow(
      Map<String, dynamic> userState, String flowType) async {
    
    final response = await http.post(
      Uri.parse('$_baseUrl/process'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_state': userState,
        'flow_type': flowType,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to process decision flow');
    }
  }
  
  // Exemplo de fluxo de decisão para recomendação de treino
  Future<Map<String, dynamic>> getTrainingRecommendation(
      double strength, double endurance) async {
    
    return processDecisionFlow({
      'strength': strength,
      'endurance': endurance,
    }, 'training_recommendation');
  }
}