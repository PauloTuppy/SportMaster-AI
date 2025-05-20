import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportmaster_ai/services/opensearch_service.dart';
import 'package:sportmaster_ai/services/medical_data_service.dart';
import 'package:sportmaster_ai/services/monitoring_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthAgentService {
  final String _baseUrl;
  final String _apiKey;
  final OpenSearchService _openSearchService;
  final MedicalDataService _medicalDataService;
  final MonitoringService _monitoringService;
  
  HealthAgentService({
    required String baseUrl,
    required String apiKey,
    required OpenSearchService openSearchService,
    required MedicalDataService medicalDataService,
    required MonitoringService monitoringService,
  }) : 
    _baseUrl = baseUrl,
    _apiKey = apiKey,
    _openSearchService = openSearchService,
    _medicalDataService = medicalDataService,
    _monitoringService = monitoringService;
  
  // Analisar exames e gerar recomendações
  Future<Map<String, dynamic>> analyzeExamsAndRecommend() async {
    try {
      // Obter exames do usuário
      final exams = await _medicalDataService.getUserExams();
      
      if (exams.isEmpty) {
        return {
          'status': 'no_data',
          'message': 'Nenhum exame encontrado. Por favor, adicione seus exames para receber recomendações personalizadas.',
        };
      }
      
      // Enviar para API de análise
      final response = await http.post(
        Uri.parse('$_baseUrl/health/analyze'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'exams': exams,
        }),
      );
      
      if (response.statusCode == 200) {
        final recommendations = jsonDecode(response.body);
        
        // Verificar interações medicamentosas e contraindicações
        final safetyChecks = await _checkSafetyAndInteractions(
          recommendations['suplementos'] ?? {},
          exams,
        );
        
        // Adicionar alertas de segurança
        if (safetyChecks.containsKey('alertas')) {
          if (recommendations.containsKey('alertas')) {
            if (recommendations['alertas'] is List) {
              recommendations['alertas'].addAll(safetyChecks['alertas']);
            } else {
              recommendations['alertas'] = [recommendations['alertas'], ...safetyChecks['alertas']];
            }
          } else {
            recommendations['alertas'] = safetyChecks['alertas'];
          }
        }
        
        return recommendations;
      } else {
        throw Exception('Failed to analyze exams: ${response.statusCode}');
      }
    } catch (e) {
      _monitoringService.logError(
        'HEALTH_ANALYSIS_ERROR',
        'Error analyzing exams: $e',
        StackTrace.current,
      );
      
      // Fallback: análise local básica
      return _localBasicAnalysis(await _medicalDataService.getUserExams());
    }
  }
  
  // Verificar interações medicamentosas e contraindicações
  Future<Map<String, dynamic>> _checkSafetyAndInteractions(
    Map<String, dynamic> supplements,
    Map<String, dynamic> exams,
  ) async {
    try {
      // Buscar informações de suplementos no OpenSearch
      final supplementNames = supplements.keys.toList();
      final List<Map<String, dynamic>> supplementData = [];
      
      for (final name in supplementNames) {
        final response = await _openSearchService.searchAthletes(
          sportType: 'supplements',
          userData: {'nome': name},
          embeddingField: '',
        );
        
        if (response.containsKey('hits') && 
            response['hits'].containsKey('hits') && 
            response['hits']['hits'].isNotEmpty) {
          supplementData.add(response['hits']['hits'][0]['_source']);
        }
      }
      
      // Verificar contraindicações
      final List<String> alerts = [];
      
      for (final supplement in supplementData) {
        if (supplement.containsKey('contraindicacoes')) {
          final contraindicacoes = supplement['contraindicacoes'];
          
          // Verificar hipotireoidismo
          if (contraindicacoes.contains('Hipotireoidismo') && 
              exams.containsKey('TSH') && 
              exams['TSH'] > 4.5) {
            alerts.add('Evitar ${supplement['nome']}: contraindicado para hipotireoidismo!');
          }
          
          // Verificar hipertensão
          if (contraindicacoes.contains('Hipertensão') && 
              exams.containsKey('blood_pressure_systolic') && 
              exams['blood_pressure_systolic'] > 140) {
            alerts.add('Evitar ${supplement['nome']}: contraindicado para hipertensão!');
          }
        }
      }
      
      return alerts.isEmpty ? {} : {'alertas': alerts};
    } catch (e) {
      _monitoringService.logError(
        'SAFETY_CHECK_ERROR',
        'Error checking supplement safety: $e',
        StackTrace.current,
      );
      return {};
    }
  }
  
  // Análise local básica (fallback)
  Map<String, dynamic> _localBasicAnalysis(Map<String, dynamic> exams) {
    final Map<String, dynamic> recommendations = {};
    final List<String> alerts = [];
    final Map<String, dynamic> supplements = {};
    
    // Verificar vitamina D
    if (exams.containsKey('Vitamina D') && exams['Vitamina D'] < 30) {
      supplements['Vitamina D3'] = {
        'dose': '2000 UI',
        'frequencia': 'Diária',
        'motivo': 'Níveis baixos de Vitamina D (${exams['Vit