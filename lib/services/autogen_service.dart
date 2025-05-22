import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
// import 'package:sportmaster_ai/services/monitoring_service.dart'; // Предполагается, что MonitoringService будет внедрен
import 'package:sportmaster_ai/config/app_config.dart';

class AutoGenService {
  // final MonitoringService _monitoringService; // Предполагается, что MonitoringService будет внедрен
  final String _baseUrl = AppConfig.autogenApiBaseUrl;
  // final String _apiKey = AppConfig.autogenApiKey; // Or AppConfig.genericApiKey if that's intended

  // Constructor can be simplified.
  // AutoGenService();
  // Or if MonitoringService is injected:
  // AutoGenService(this._monitoringService);

  // TODO: Add unit tests for AutoGenService:
  // - Test constructor uses AppConfig correctly for _baseUrl (and _apiKey if used).
  // - Mock http.post for getChatbotResponse to test:
  //   - Successful response parsing.
  //   - Different HTTP error codes and error response bodies.
  //   - JSON parsing errors.
  //   - TimeoutException.
  // - Test getCoachAdvice calls getChatbotResponse with correct agentType.
  
  Future<String> getChatbotResponse(String userInput, String agentType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'), // _baseUrl now comes from AppConfig
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $_apiKey', // Uncomment if API key is needed and set from AppConfig
        },
        body: jsonEncode({
          'user_input': userInput,
          'agent_type': agentType,
        }),
      ).timeout(const Duration(seconds: 20)); // Example timeout

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('response') && data['response'] is String) {
            return data['response'];
          } else {
            // _monitoringService.logError('AutoGenService', 'Unexpected response structure: ${response.body}', null);
            print('Unexpected response structure from AutoGen: ${response.body}');
            throw Exception('Received an unexpected response from the coach.');
          }
        } on FormatException catch (e, stackTrace) {
          // _monitoringService.logError('AutoGenService', 'Malformed JSON response: ${response.body}', stackTrace);
          print('Malformed JSON response from AutoGen: ${response.body}, Error: $e');
          throw Exception('The coach provided an invalid response format.');
        }
      } else {
        // _monitoringService.logError('AutoGenService', 'AutoGen request failed: ${response.statusCode}, Body: ${response.body}', null);
        print('AutoGen request failed: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to get chatbot response. Status: ${response.statusCode}');
      }
    } on TimeoutException catch (e, stackTrace) {
      // _monitoringService.logError('AutoGenService', 'Timeout getting chatbot response for $userInput, $agentType: $e', stackTrace);
      print('Timeout getting chatbot response for $userInput, $agentType: $e');
      throw Exception('The coach is taking too long to respond. Please try again later.');
    } catch (e, stackTrace) {
      // _monitoringService.logError('AutoGenService', 'Generic error in getChatbotResponse for $userInput, $agentType: $e', stackTrace);
      print('Generic error in getChatbotResponse for $userInput, $agentType: $e');
      throw Exception('An unexpected error occurred while talking to the coach.');
    }
  }
  
  // Exemplo de uso do chatbot de treinador
  Future<String> getCoachAdvice(String question, String sportType) async {
    return getChatbotResponse(question, 'coach_$sportType');
  }
}