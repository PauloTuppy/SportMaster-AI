import 'dart:convert';
import 'dart:async'; // For TimeoutException
import 'package:http/http.dart' as http;
// import 'package:sportmaster_ai/services/monitoring_service.dart'; // Предполагается, что MonitoringService будет внедрен
import 'package:sportmaster_ai/config/app_config.dart';

class LangGraphService {
  // final MonitoringService _monitoringService; // Предполагается, что MonitoringService будет внедрен
  final String _baseUrl = AppConfig.langgraphApiBaseUrl;
  // final String _apiKey = AppConfig.langgraphApiKey; // Or AppConfig.genericApiKey if intended

  // Constructor can be simplified.
  // LangGraphService();
  // Or if MonitoringService is injected:
  // LangGraphService(this._monitoringService);

  Future<Map<String, dynamic>> processDecisionFlow(
      Map<String, dynamic> userState, String flowType) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/process'), // _baseUrl now comes from AppConfig
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $_apiKey', // Uncomment if API key is needed and set from AppConfig
        },
        body: jsonEncode({
          'user_state': userState,
          'flow_type': flowType,
        }),
      ).timeout(const Duration(seconds: 30)); // Example timeout

      if (response.statusCode == 200) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          } else {
            // _monitoringService.logError('LangGraphService', 'Unexpected response type: ${decoded.runtimeType}, Body: ${response.body}', null);
            print('LangGraph unexpected response type: ${decoded.runtimeType}, Body: ${response.body}');
            throw Exception('LangGraph service returned an unexpected response format.');
          }
        } on FormatException catch (e, stackTrace) {
          // _monitoringService.logError('LangGraphService', 'Malformed JSON response for $flowType: ${response.body}', stackTrace);
          print('LangGraph malformed JSON response for $flowType: ${response.body}, Error: $e');
          throw Exception('LangGraph service returned an invalid response format.');
        }
      } else {
        // _monitoringService.logError('LangGraphService', 'LangGraph request failed for $flowType: ${response.statusCode}, Body: ${response.body}', null);
        print('LangGraph request failed for $flowType: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to process decision flow $flowType. Status: ${response.statusCode}');
      }
    } on TimeoutException catch (e, stackTrace) {
      // _monitoringService.logError('LangGraphService', 'Timeout processing decision flow $flowType: $e', stackTrace);
      print('Timeout processing decision flow $flowType: $e');
      throw Exception('The decision flow process for $flowType is taking too long.');
    } catch (e, stackTrace) {
      // _monitoringService.logError('LangGraphService', 'Generic error in processDecisionFlow for $flowType: $e', stackTrace);
      print('Generic error in processDecisionFlow for $flowType: $e');
      throw Exception('An unexpected error occurred while processing decision flow $flowType.');
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