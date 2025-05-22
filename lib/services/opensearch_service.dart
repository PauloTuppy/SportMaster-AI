import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aws_sigv4/aws_sigv4.dart';
import 'package:sportmaster_ai/config/app_config.dart';

class OpenSearchService {
  final String _endpoint = AppConfig.opensearchEndpoint;
  final String _region = AppConfig.opensearchRegion;
  final String _accessKey = AppConfig.opensearchAccessKey;
  final String _secretKey = AppConfig.opensearchSecretKey;
  
  // Constructor can be simplified
  // OpenSearchService();

  // TODO: Add unit tests for OpenSearchService:
  // - Test constructor uses AppConfig correctly (mock AppConfig or use test values).
  // - Test _getIndexName for all sportTypes.
  // - Test _buildHybridQuery with and without embeddings, and with different userData.
  // - Mock http.post for _executeSearch and indexUserData to test:
  //   - Successful search and index operations.
  //   - Different HTTP error codes and error response bodies.
  //   - JSON parsing errors.
  //   - SigV4 client request signing (more of an integration test concern).
  
  Future<Map<String, dynamic>> searchAthletes({
    required String sportType,
    required Map<String, dynamic> userData,
    required String embeddingField,
    List<double>? embedding,
  }) async {
    final String indexName = _getIndexName(sportType);
    
    // Construir query híbrida
    final Map<String, dynamic> query = _buildHybridQuery(
      userData: userData,
      embeddingField: embeddingField,
      embedding: embedding,
    );
    
    // Executar busca
    final response = await _executeSearch(indexName, query);
    return response;
  }
  
  String _getIndexName(String sportType) {
    switch (sportType) {
      case 'football': return 'atletas_futebol';
      case 'mma': return 'lutadores_mma';
      case 'bodybuilding': return 'fisiculturistas';
      default: return 'atletas';
    }
  }
  
  Map<String, dynamic> _buildHybridQuery({
    required Map<String, dynamic> userData,
    required String embeddingField,
    List<double>? embedding,
  }) {
    // Construir componente BM25
    final List<Map<String, dynamic>> mustClauses = [];
    
    // Adicionar filtros baseados em userData
    if (userData.containsKey('weight_class')) {
      mustClauses.add({
        'term': {'peso': userData['weight_class']}
      });
    }
    
    // Construir query completa
    final Map<String, dynamic> query = {
      'query': {
        'bool': {
          'must': mustClauses,
        }
      }
    };
    
    // Adicionar componente KNN se embedding for fornecido
    if (embedding != null) {
      query['knn'] = {
        embeddingField: {
          'vector': embedding,
          'k': 5
        }
      };
    }
    
    return query;
  }
  
  Future<Map<String, dynamic>> _executeSearch(
    String indexName, 
    Map<String, dynamic> query
  ) async {
    final String endpoint = '$_endpoint/$indexName/_search';
    
    // Assinar requisição com AWS SigV4
    final AWSSigV4Client sigv4 = AWSSigV4Client(
      _accessKey,
      _secretKey,
      _endpoint,
      region: _region,
      serviceName: 'es',
    );
    
    final AWSSigV4Request signedRequest = sigv4.request(
      endpoint,
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(query),
    );
    
    final response = await http.post(
      Uri.parse(endpoint),
      headers: signedRequest.headers,
      body: signedRequest.body,
    );
    
    // Add .timeout(Duration(seconds: 10)) to http.post call for production
    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body);
      } on FormatException catch (e, stackTrace) {
        // Consider logging this error to MonitoringService
        print('Malformed JSON response from OpenSearch search: ${response.body}, Error: $e');
        throw Exception('Failed to parse OpenSearch search response.');
      }
    } else {
      // Consider logging this error to MonitoringService, including indexName, query, response.statusCode, response.body
      print('Failed to search OpenSearch index $indexName: ${response.statusCode} ${response.body}');
      throw Exception('Failed to search OpenSearch. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
  
  // Método para indexar novos dados (usado para feedback do usuário)
  Future<void> indexUserData(
    String indexName, 
    Map<String, dynamic> document
  ) async {
    final String endpoint = '$_endpoint/$indexName/_doc';
    
    final AWSSigV4Client sigv4 = AWSSigV4Client(
      _accessKey,
      _secretKey,
      _endpoint,
      region: _region,
      serviceName: 'es',
    );
    
    final AWSSigV4Request signedRequest = sigv4.request(
      endpoint,
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(document),
    );
    
    final response = await http.post(
      Uri.parse(endpoint),
      headers: signedRequest.headers,
      body: signedRequest.body,
    );
    
    // Add .timeout(Duration(seconds: 10)) to http.post call for production
    if (response.statusCode != 201) {
      // Consider logging this error to MonitoringService, including indexName, document, response.statusCode, response.body
      print('Failed to index document in $indexName: ${response.statusCode} ${response.body}');
      throw Exception('Failed to index document. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }
}