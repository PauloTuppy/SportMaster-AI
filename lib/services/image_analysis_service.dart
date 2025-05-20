import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ImageAnalysisService {
  final String _baseUrl;
  final String _apiKey;
  
  ImageAnalysisService({
    required String baseUrl,
    required String apiKey,
  }) : 
    _baseUrl = baseUrl,
    _apiKey = apiKey;
  
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
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Falha na análise de imagem: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro na análise de imagem: $e');
      // Retornar estimativas padrão em caso de falha
      return {
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
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Falha na estimativa de gordura corporal: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro na estimativa de gordura corporal: $e');
      return {
        'body_fat': 15.0, // Estimativa padrão
      };
    }
  }
}