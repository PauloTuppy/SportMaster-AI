import 'dart:convert';
import 'package:http/http.dart' as http;

class AutoGenService {
  final String _baseUrl = 'https://api.sportmaster.ai/autogen';
  
  Future<String> getChatbotResponse(String userInput, String agentType) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_input': userInput,
        'agent_type': agentType,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      throw Exception('Failed to get chatbot response');
    }
  }
  
  // Exemplo de uso do chatbot de treinador
  Future<String> getCoachAdvice(String question, String sportType) async {
    return getChatbotResponse(question, 'coach_$sportType');
  }
}