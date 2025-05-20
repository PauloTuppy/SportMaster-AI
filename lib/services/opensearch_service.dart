import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aws_sigv4/aws_sigv4.dart';

class OpenSearchService {
  final String _endpoint;
  final String _region;
  final String _accessKey;
  final String _secretKey;
  
  OpenSearchService({
    required String endpoint,
    required String region,
    required String accessKey,
    required String secretKey,
  }) : 
    _endpoint = endpoint,
    _region = region,
    _accessKey = accessKey,
    _secretKey = secretKey;
  
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
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search OpenSearch: ${response.body}');
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
    
    if (response.statusCode != 201) {
      throw Exception('Failed to index document: ${response.body}');
    }
  }
}