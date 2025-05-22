import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sportmaster_ai/config/app_config.dart';

class ImageAnalysisService {
  final String _baseUrl = AppConfig.genericApiBaseUrl; // Assuming image analysis uses the generic API
  final String _apiKey = AppConfig.genericApiKey; 
  // Or, if ImageAnalysisService has a specific key:
  // final String _apiKey = AppConfig.imageAnalysisApiKey; // Requires adding imageAnalysisApiKey to AppConfig

  // Constructor can be simplified
  // ImageAnalysisService();
  
  Future<Map<String, dynamic>> analyzeBodyComposition(List<File> images) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze/body-composition'),
      );
      
      // Adicionar cabeçalhos
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
      });
      
      // Adicionar imagens
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        
        final multipartFile = http.MultipartFile(
          'image_$i',
          stream,
          length,
          filename: 'image_$i.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        
        request.files.add(multipartFile);
      }
      
      // Enviar requisição
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      // Add .timeout(Duration(seconds: 60)) to request.send() for production
      if (response.statusCode == 200) {
        try {
          return jsonDecode(responseBody);
        } on FormatException catch (fe, stackTrace) {
          // Consider logging this error to MonitoringService
          print('Malformed JSON response for analyzeBodyComposition: $responseBody, Error: $fe');
          throw Exception('Failed to parse body composition response.');
        }
      } else {
        // Consider logging this error to MonitoringService, including response.statusCode, responseBody
        print('Failed to analyzeBodyComposition: ${response.statusCode} $responseBody');
        throw Exception('Failed to analyze body composition. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) { // Catching stackTrace here
      // Consider logging this error to MonitoringService
      print('Erro na análise de imagem: $e, StackTrace: $stackTrace');
      // Retornar estimativas padrão em caso de falha
      return {
        'error': 'Analysis failed, showing default estimates.', // Indicate error
        'body_fat': 15.0, // Estimativa padrão
        'symmetry_score': 0.8, // Estimativa padrão
        'muscle_groups': {
          'chest': 0.7,
          'back': 0.7,
          'shoulders': 0.7,
          'arms': 0.7,
          'legs': 0.7,
          'calves': 0.7,
        },
      };
    }
  }
  
  Future<Map<String, dynamic>> estimateBodyFatFromImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/analyze/body-fat'),
      );
      
      // Adicionar cabeçalhos
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
      });
      
      // Adicionar imagem
      final stream = http.ByteStream(image.openRead());
      final length = await image.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: 'body_image.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      
      request.files.add(multipartFile);
      
      // Enviar requisição
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      // Add .timeout(Duration(seconds: 30)) to request.send() for production
      if (response.statusCode == 200) {
        try {
          return jsonDecode(responseBody);
        } on FormatException catch (fe, stackTrace) {
          // Consider logging this error to MonitoringService
          print('Malformed JSON response for estimateBodyFatFromImage: $responseBody, Error: $fe');
          throw Exception('Failed to parse body fat estimation response.');
        }
      } else {
        // Consider logging this error to MonitoringService, including response.statusCode, responseBody
        print('Failed to estimateBodyFatFromImage: ${response.statusCode} $responseBody');
        throw Exception('Failed to estimate body fat. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) { // Catching stackTrace here
      // Consider logging this error to MonitoringService
      print('Erro na estimativa de gordura corporal: $e, StackTrace: $stackTrace');
      return {
        'error': 'Estimation failed, showing default estimate.', // Indicate error
        'body_fat': 15.0, // Estimativa padrão
      };
    }
  }
}