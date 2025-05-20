import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportmaster_ai/services/opensearch_service.dart';
import 'package:sportmaster_ai/services/monitoring_service.dart';

class MedicalDataService {
  final String _baseUrl;
  final String _apiKey;
  final OpenSearchService _openSearchService;
  final MonitoringService _monitoringService;
  
  MedicalDataService({
    required String baseUrl,
    required String apiKey,
    required OpenSearchService openSearchService,
    required MonitoringService monitoringService,
  }) : 
    _baseUrl = baseUrl,
    _apiKey = apiKey,
    _openSearchService = openSearchService,
    _monitoringService = monitoringService;
  
  // Processar imagem de exame usando OCR
  Future<Map<String, dynamic>> processLabReportImage(File imageFile) async {
    try {
      // Criar multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/medical/process-lab-report'),
      );
      
      // Adicionar headers
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
      });
      
      // Adicionar arquivo
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
      
      // Enviar request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final parsedData = jsonDecode(responseData);
        
        // Salvar dados no OpenSearch
        await _saveExamDataToOpenSearch(parsedData);
        
        return parsedData;
      } else {
        throw Exception('Failed to process lab report: ${response.statusCode}');
      }
    } catch (e) {
      _monitoringService.logError(
        'OCR_PROCESSING_ERROR',
        'Error processing lab report image: $e',
        StackTrace.current,
      );
      throw Exception('Failed to process lab report: $e');
    }
  }
  
  // Processar PDF de exame
  Future<Map<String, dynamic>> processLabReportPDF(File pdfFile) async {
    try {
      // Criar multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/medical/process-lab-report-pdf'),
      );
      
      // Adicionar headers
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
      });
      
      // Adicionar arquivo
      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf',
          pdfFile.path,
        ),
      );
      
      // Enviar request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final parsedData = jsonDecode(responseData);
        
        // Salvar dados no OpenSearch
        await _saveExamDataToOpenSearch(parsedData);
        
        return parsedData;
      } else {
        throw Exception('Failed to process lab report PDF: ${response.statusCode}');
      }
    } catch (e) {
      _monitoringService.logError(
        'PDF_PROCESSING_ERROR',
        'Error processing lab report PDF: $e',
        StackTrace.current,
      );
      throw Exception('Failed to process lab report PDF: $e');
    }
  }
  
  // Obter dados de saúde do HealthKit/Google Fit
  Future<Map<String, dynamic>> getHealthData() async {
    try {
      // Criar instância do plugin Health
      final HealthFactory health = HealthFactory();
      
      // Definir tipos de dados a serem lidos
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.WEIGHT,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
      
      // Solicitar permissão
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      final accessWasGranted = await health.requestAuthorization(types, permissions: permissions);
      
      if (accessWasGranted) {
        // Definir período de tempo (últimos 30 dias)
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(Duration(days: 30));
        
        // Obter dados
        final healthData = <String, dynamic>{};
        
        for (final type in types) {
          try {
            final data = await health.getHealthDataFromTypes(thirtyDaysAgo, now, [type]);
            
            if (data.isNotEmpty) {
              // Calcular média para métricas como frequência cardíaca
              if (type == HealthDataType.HEART_RATE || 
                  type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC || 
                  type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC || 
                  type == HealthDataType.BLOOD_GLUCOSE) {
                
                final values = data.map((e) => e.value).toList();
                final average = values.reduce((a, b) => a + b) / values.length;
                healthData[_healthTypeToString(type)] = average;
              } 
              // Usar valor mais recente para peso
              else if (type == HealthDataType.WEIGHT) {
                data.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
                healthData[_healthTypeToString(type)] = data.first.value;
              }
              // Somar valores para passos e calorias
              else if (type == HealthDataType.STEPS || type == HealthDataType.ACTIVE_ENERGY_BURNED) {
                final total = data.map((e) => e.value).reduce((a, b) => a + b);
                healthData[_healthTypeToString(type)] = total;
              }
            }
          } catch (e) {
            print('Error fetching $type: $e');
          }
        }
        
        // Salvar dados no OpenSearch
        await _saveHealthDataToOpenSearch(healthData);
        
        return healthData;
      } else {
        throw Exception('Authorization not granted');
      }
    } catch (e) {
      _monitoringService.logError(
        'HEALTH_DATA_ERROR',
        'Error fetching health data: $e',
        StackTrace.current,
      );
      throw Exception('Failed to get health data: $e');
    }
  }
  
  // Converter HealthDataType para string
  String _healthTypeToString(HealthDataType type) {
    switch (type) {
      case HealthDataType.HEART_RATE:
        return 'heart_rate';
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        return 'blood_pressure_systolic';
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return 'blood_pressure_diastolic';
      case HealthDataType.BLOOD_GLUCOSE:
        return 'blood_glucose';
      case HealthDataType.WEIGHT:
        return 'weight';
      case HealthDataType.STEPS:
        return 'steps';
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return 'calories_burned';
      default:
        return type.toString();
    }
  }
  
  // Salvar dados de exame no OpenSearch
  Future<void> _saveExamDataToOpenSearch(Map<String, dynamic> examData) async {
    try {
      // Obter ID do usuário
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous';
      
      // Formatar dados para OpenSearch
      final List<Map<String, dynamic>> exams = [];
      
      examData.forEach((key, value) {
        exams.add({
          'tipo': _categorizeExamType(key),
          'data': DateTime.now().toIso8601String(),
          'metrica': key,
          'valor': _parseExamValue(value),
        });
      });
      
      // Indexar no OpenSearch
      await _openSearchService.indexUserData(
        'saude_usuarios',
        {
          'user_id': userId,
          'exames': exams,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _monitoringService.logError(
        'OPENSEARCH_ERROR',
        'Error saving exam data to OpenSearch: $e',
        StackTrace.current,
      );
    }
  }
  
  // Salvar dados de saúde no OpenSearch
  Future<void> _saveHealthDataToOpenSearch(Map<String, dynamic> healthData) async {
    try {
      // Obter ID do usuário
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous';
      
      // Formatar dados para OpenSearch
      final List<Map<String, dynamic>> healthMetrics = [];
      
      healthData.forEach((key, value) {
        healthMetrics.add({
          'tipo': 'wearable',
          'data': DateTime.now().toIso8601String(),
          'metrica': key,
          'valor': value,
        });
      });
      
      // Indexar no OpenSearch
      await _openSearchService.indexUserData(
        'saude_usuarios',
        {
          'user_id': userId,
          'exames': healthMetrics,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _monitoringService.logError(
        'OPENSEARCH_ERROR',
        'Error saving health data to OpenSearch: $e',
        StackTrace.current,
      );
    }
  }
  
  // Categorizar tipo de exame
  String _categorizeExamType(String examName) {
    final examNameLower = examName.toLowerCase();
    
    if (examNameLower.contains('colesterol') || 
        examNameLower.contains('ldl') || 
        examNameLower.contains('hdl') ||
        examNameLower.contains('triglicerídeos')) {
      return 'Cardiológico';
    } else if (examNameLower.contains('tsh') || 
               examNameLower.contains('t4') || 
               examNameLower.contains('t3') ||
               examNameLower.contains('cortisol') ||
               examNameLower.contains('testosterona')) {
      return 'Endocrinológico';
    } else if (examNameLower.contains('vitamina') || 
               examNameLower.contains('ferritina') || 
               examNameLower.contains('ferro') ||
               examNameLower.contains('b12')) {
      return 'Nutricional';
    } else if (examNameLower.contains('hemoglobina') || 
               examNameLower.contains('hematócrito') || 
               examNameLower.contains('leucócitos')) {
      return 'Hematológico';
    } else {
      return 'Geral';
    }
  }
  
  // Extrair valor numérico de um resultado de exame
  double _parseExamValue(String valueStr) {
    try {
      // Remover unidades e caracteres não numéricos
      final numericStr = valueStr.replaceAll(RegExp(r'[^0-9\.]'), '');
      return double.parse(numericStr);
    } catch (e) {
      return 0.0;
    }
  }
  
  // Obter todos os exames do usuário
  Future<Map<String, dynamic>> getUserExams() async {
    try {
      // Obter ID do usuário
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? 'anonymous';
      
      // Buscar no OpenSearch
      final response = await _openSearchService.searchAthletes(
        sportType: 'medical',
        userData: {'user_id': userId},
        embeddingField: '',
      );
      
      if (response.containsKey('hits') && 
          response['hits'].containsKey('hits') && 
          response['hits']['hits'].isNotEmpty) {
        
        // Processar resultados
        final exams = <String, dynamic>{};
        
        for (final hit in response['hits']['hits']) {
          if (hit['_source'].containsKey('exames')) {
            for (final exam in hit['_source']['exames']) {
              exams[exam['metrica']] = exam['valor'];
            }
          }
        }
        
        return exams;
      }
      
      return {};
    } catch (e) {
      _monitoringService.logError(
        'EXAM_RETRIEVAL_ERROR',
        'Error retrieving user exams: $e',
        StackTrace.current,
      );
      return {};
    }
  }
}