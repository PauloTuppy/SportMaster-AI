import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportmaster_ai/services/agent_service.dart';

class AgentIntegrationService {
  final String _baseUrl;
  final String _apiKey;
  
  AgentIntegrationService({
    required String baseUrl,
    required String apiKey,
  }) : 
    _baseUrl = baseUrl,
    _apiKey = apiKey;
  
  // Combinar recomendações de múltiplos agentes com sistema de votação ponderada
  Future<Map<String, dynamic>> combineRecommendations({
    Map<String, dynamic>? footballRecommendations,
    Map<String, dynamic>? mmaRecommendations,
    Map<String, dynamic>? bodybuildingRecommendations,
    Map<String, double>? weights,
  }) async {
    // Pesos padrão se não forem fornecidos
    final Map<String, double> agentWeights = weights ?? {
      'football': 0.33,
      'mma': 0.33,
      'bodybuilding': 0.34,
    };
    
    // Verificar quais recomendações estão disponíveis
    final Map<String, Map<String, dynamic>> availableRecommendations = {};
    
    if (footballRecommendations != null) {
      availableRecommendations['football'] = footballRecommendations;
    }
    
    if (mmaRecommendations != null) {
      availableRecommendations['mma'] = mmaRecommendations;
    }
    
    if (bodybuildingRecommendations != null) {
      availableRecommendations['bodybuilding'] = bodybuildingRecommendations;
    }
    
    // Se houver apenas um tipo de recomendação, retorná-lo diretamente
    if (availableRecommendations.length == 1) {
      return availableRecommendations.values.first;
    }
    
    // Normalizar pesos para as recomendações disponíveis
    double totalWeight = 0;
    final Map<String, double> normalizedWeights = {};
    
    for (final entry in availableRecommendations.entries) {
      final weight = agentWeights[entry.key] ?? 0.0;
      normalizedWeights[entry.key] = weight;
      totalWeight += weight;
    }
    
    for (final key in normalizedWeights.keys) {
      normalizedWeights[key] = normalizedWeights[key]! / totalWeight;
    }
    
    // Usar API para combinar recomendações com pesos normalizados
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/agents/combine-recommendations'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recommendations': availableRecommendations,
          'weights': normalizedWeights,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to combine recommendations');
      }
    } catch (e) {
      print('Erro ao combinar recomendações: $e');
      
      // Fallback: combinar localmente de forma simples
      return _localCombineRecommendations(
        availableRecommendations,
        normalizedWeights,
      );
    }
  }
  
  // Método de fallback para combinar recomendações localmente
  Map<String, dynamic> _localCombineRecommendations(
    Map<String, Map<String, dynamic>> recommendations,
    Map<String, double> weights,
  ) {
    final Map<String, dynamic> combined = {};
    
    // Combinar treinos
    final List<String> trainingPlans = [];
    for (final entry in recommendations.entries) {
      if (entry.value.containsKey('training_plan')) {
        trainingPlans.add('${entry.value['training_plan']} (${(weights[entry.key]! * 100).toStringAsFixed(0)}%)');
      }
    }
    combined['training_plan'] = trainingPlans.join(' + ');
    
    // Combinar dietas
    final List<String> dietPlans = [];
    for (final entry in recommendations.entries) {
      if (entry.value.containsKey('diet_plan')) {
        dietPlans.add('${entry.value['diet_plan']} (${(weights[entry.key]! * 100).toStringAsFixed(0)}%)');
      }
    }
    if (dietPlans.isNotEmpty) {
      combined['diet_plan'] = dietPlans.join(' + ');
    }
    
    // Adicionar alertas de todos os agentes
    final List<String> alerts = [];
    for (final entry in recommendations.entries) {
      if (entry.value.containsKey('alerts')) {
        if (entry.value['alerts'] is List) {
          for (final alert in entry.value['alerts']) {
            alerts.add('$alert (${entry.key})');
          }
        } else if (entry.value['alerts'] is String) {
          alerts.add('${entry.value['alerts']} (${entry.key})');
        }
      }
    }
    if (alerts.isNotEmpty) {
      combined['alerts'] = alerts;
    }
    
    // Adicionar fonte das recomendações
    combined['sources'] = weights.map((key, value) => 
      MapEntry(key, '${(value * 100).toStringAsFixed(0)}%'));
    
    return combined;
  }
  
  // Processar entrada do usuário e determinar quais agentes devem ser consultados
  Future<Map<String, dynamic>> processUserInput(String userInput) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/agents/process-input'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_input': userInput,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to process user input');
      }
    } catch (e) {
      print('Erro ao processar entrada do usuário: $e');
      
      // Fallback: análise local simples
      final Map<String, double> agentWeights = {};
      
      if (userInput.toLowerCase().contains('futebol') || 
          userInput.toLowerCase().contains('soccer') ||
          userInput.toLowerCase().contains('jogador')) {
        agentWeights['football'] = 0.7;
      }
      
      if (userInput.toLowerCase().contains('mma') || 
          userInput.toLowerCase().contains('luta') ||
          userInput.toLowerCase().contains('ufc')) {
        agentWeights['mma'] = 0.7;
      }
      
      if (userInput.toLowerCase().contains('musculação') || 
          userInput.toLowerCase().contains('bodybuilding') ||
          userInput.toLowerCase().contains('academia')) {
        agentWeights['bodybuilding'] = 0.7;
      }
      
      // Se nenhum agente específico foi identificado, usar todos igualmente
      if (agentWeights.isEmpty) {
        agentWeights['football'] = 0.33;
        agentWeights['mma'] = 0.33;
        agentWeights['bodybuilding'] = 0.34;
      }
      
      return {
        'agent_weights': agentWeights,
        'query': userInput,
      };
    }
  }
}