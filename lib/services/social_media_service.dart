import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportmaster_ai/config/app_config.dart';

class SocialMediaService {
  final String _baseUrl = AppConfig.genericApiBaseUrl; // Assuming social media service uses the generic API
  final String _apiKey = AppConfig.genericApiKey;
  
  // Constructor can be simplified
  // SocialMediaService();

  Future<Map<String, dynamic>> getAthleteDiet(String athleteId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/social/athlete-diet/$athleteId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      // Add .timeout(Duration(seconds: 15)) to http.get call for production
      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } on FormatException catch (fe, stackTrace) {
          // Consider logging this error to MonitoringService
          print('Malformed JSON response for getAthleteDiet $athleteId: ${response.body}, Error: $fe');
          throw Exception('Failed to parse athlete diet response.');
        }
      } else {
        // Consider logging this error to MonitoringService, including athleteId, response.statusCode, response.body
        print('Failed to getAthleteDiet for $athleteId: ${response.statusCode} ${response.body}');
        throw Exception('Failed to get athlete diet for $athleteId. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) { // Catching stackTrace here
      // Consider logging this error to MonitoringService
      print('Erro ao obter dieta do atleta $athleteId: $e, StackTrace: $stackTrace');
      // Retornar dieta padrão em caso de falha
      return {
        'error': 'Failed to fetch diet, showing sample diet.', // Indicate error
        'meals': [
          {
            'name': 'Café da manhã',
            'foods': [
              {'name': 'Ovos', 'quantity': '6 claras, 2 gemas'},
              {'name': 'Aveia', 'quantity': '100g'},
              {'name': 'Frutas', 'quantity': '1 porção'},
            ],
          },
          {
            'name': 'Lanche da manhã',
            'foods': [
              {'name': 'Whey Protein', 'quantity': '30g'},
              {'name': 'Banana', 'quantity': '1 unidade'},
            ],
          },
          {
            'name': 'Almoço',
            'foods': [
              {'name': 'Frango', 'quantity': '200g'},
              {'name': 'Arroz', 'quantity': '150g'},
              {'name': 'Vegetais', 'quantity': '100g'},
            ],
          },
          {
            'name': 'Lanche da tarde',
            'foods': [
              {'name': 'Batata doce', 'quantity': '150g'},
              {'name': 'Atum', 'quantity': '100g'},
            ],
          },
          {
            'name': 'Jantar',
            'foods': [
              {'name': 'Carne', 'quantity': '200g'},
              {'name': 'Arroz', 'quantity': '100g'},
              {'name': 'Vegetais', 'quantity': '100g'},
            ],
          },
          {
            'name': 'Ceia',
            'foods': [
              {'name': 'Caseína', 'quantity': '30g'},
              {'name': 'Pasta de amendoim', 'quantity': '15g'},
            ],
          },
        ],
        'macros': {
          'protein': 220,
          'carbs': 300,
          'fats': 70,
          'calories': 2710,
        },
        'supplements': [
          {'name': 'Whey Protein', 'dosage': '30g 2x ao dia'},
          {'name': 'Creatina', 'dosage': '5g por dia'},
          {'name': 'Multivitamínico', 'dosage': '1 cápsula por dia'},
        ],
      };
    }
  }
  
  Future<List<Map<String, dynamic>>> getAthleteWorkouts(String athleteId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/social/athlete-workouts/$athleteId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15)); // Example timeout
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('workouts') && data['workouts'] is List) {
            return List<Map<String, dynamic>>.from(data['workouts']);
          } else {
            // _monitoringService.logError('SocialMediaService', 'Unexpected workouts response structure for $athleteId: ${response.body}', null);
            print('Unexpected workouts response structure for $athleteId: ${response.body}');
            throw Exception('Unexpected athlete workouts response structure.');
          }
        } on FormatException catch (e, stackTrace) {
          // _monitoringService.logError('SocialMediaService', 'Malformed JSON for workouts $athleteId: ${response.body}', stackTrace);
          print('Malformed JSON for workouts $athleteId: ${response.body}, Error: $e');
          throw Exception('Malformed JSON for athlete workouts response.');
        }
      } else {
        // _monitoringService.logError('SocialMediaService', 'Failed to getAthleteWorkouts for $athleteId: ${response.statusCode}, Body: ${response.body}', null);
        print('Failed to getAthleteWorkouts for $athleteId: ${response.statusCode} ${response.body}');
        // Depending on desired behavior, either throw or return empty list with error indication
        // For now, throwing:
        throw Exception('Failed to get athlete workouts for $athleteId. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
       // _monitoringService.logError('SocialMediaService', 'Error getting athlete workouts for $athleteId: $e', stackTrace);
      print('Error getting athlete workouts for $athleteId: $e, StackTrace: $stackTrace');
      // Return empty list or a list with an error object, or rethrow
      return [{'error':'Failed to fetch workouts, please try again later.'}]; // Example of returning error in data
    }
    // The original file was truncated here. Assuming the rest of the method was missing.
  }