import 'dart:convert';
import 'package:http/http.dart' as http;

class SocialMediaService {
  final String _baseUrl;
  final String _apiKey;
  
  SocialMediaService({
    required String baseUrl,
    required String apiKey,
  }) : 
    _baseUrl = baseUrl,
    _apiKey = apiKey;
  
  Future<Map<String, dynamic>> getAthleteDiet(String athleteId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/social/athlete-diet/$athleteId'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao obter dieta do atleta: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao obter dieta do atleta: $e');
      // Retornar dieta padrão em caso de falha
      return {
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
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['workouts']);
      } else {
        throw Exception('Falha ao obter treinos do