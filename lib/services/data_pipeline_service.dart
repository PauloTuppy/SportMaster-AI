import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sportmaster_ai/config/app_config.dart';

class DataPipelineService {
  final String _baseUrl = AppConfig.genericApiBaseUrl; // Assuming data pipeline uses the generic API
  final String _apiKey = AppConfig.genericApiKey;
  
  // Constructor can be simplified
  // DataPipelineService();

  // Normalização de dados
  double normalizeSpeed(double speedMph) {
    return speedMph * 1.60934; // Conversão de mph para km/h
  }
  
  double normalizeWeight(double weightLbs) {
    return weightLbs * 0.453592; // Conversão de lbs para kg
  }
  
  double normalizeHeight(double heightInches) {
    return heightInches * 2.54; // Conversão de polegadas para cm
  }
  
  // Cache local para consultas frequentes
  Future<T?> getCachedData<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString(key);
    
    if (jsonData != null) {
      try {
        return json.decode(jsonData) as T;
      } catch (e, stackTrace) {
        // Consider logging this error to MonitoringService
        print('Error decoding cached data for key $key: $e');
        // Optionally, remove the corrupted cache entry
        // await prefs.remove(key);
        // await prefs.remove('${key}_expiry');
        return null;
      }
    }
    
    return null;
  }
  
  Future<void> setCachedData<T>(String key, T data, {int expiryInSeconds = 86400}) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonData = json.encode(data);
    
    await prefs.setString(key, jsonData);
    
    // Definir timestamp de expiração
    final int expiryTime = DateTime.now().millisecondsSinceEpoch + (expiryInSeconds * 1000);
    await prefs.setInt('${key}_expiry', expiryTime);
  }
  
  Future<bool> isCacheValid(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final int? expiryTime = prefs.getInt('${key}_expiry');
    
    if (expiryTime == null) return false;
    
    return DateTime.now().millisecondsSinceEpoch < expiryTime;
  }
  
  // Coleta de dados de futebol
  Future<Map<String, dynamic>> getFootballPlayerData(String playerId) async {
    // Verificar cache primeiro
    final cacheKey = 'football_player_$playerId';
    
    if (await isCacheValid(cacheKey)) {
      final cachedData = await getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    // Se não estiver em cache, buscar da API
    final response = await http.get(
      Uri.parse('$_baseUrl/data/football/player/$playerId'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Normalizar dados
      if (data.containsKey('speed_mph')) {
        data['speed'] = normalizeSpeed(data['speed_mph']);
      }
      
      // Armazenar em cache
      await setCachedData(cacheKey, data, expiryInSeconds: 3600); // 1 hora
      
      return data;
    } else {
      // Consider logging this error to MonitoringService, including playerId, response.statusCode, response.body
      print('Failed to load football player data for $playerId: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load football player data for $playerId. Status: ${response.statusCode}');
    }
  }
  // Add .timeout(Duration(seconds: 10)) to http.get call for production
  // Coleta de dados de MMA
  Future<Map<String, dynamic>> getMMAFighterData(String fighterId) async {
    // Verificar cache primeiro
    final cacheKey = 'mma_fighter_$fighterId';
    
    if (await isCacheValid(cacheKey)) {
      final cachedData = await getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    // Se não estiver em cache, buscar da API
    final response = await http.get(
      Uri.parse('$_baseUrl/data/mma/fighter/$fighterId'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Normalizar dados
      if (data.containsKey('weight_lbs')) {
        data['weight'] = normalizeWeight(data['weight_lbs']);
      }
      
      if (data.containsKey('height_inches')) {
        data['height'] = normalizeHeight(data['height_inches']);
      }
      
      // Armazenar em cache
      await setCachedData(cacheKey, data, expiryInSeconds: 3600); // 1 hora
      
      return data;
    } else {
      // Consider logging this error to MonitoringService, including fighterId, response.statusCode, response.body
      print('Failed to load MMA fighter data for $fighterId: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load MMA fighter data for $fighterId. Status: ${response.statusCode}');
    }
  }
  // Add .timeout(Duration(seconds: 10)) to http.get call for production
  // Coleta de dados de fisiculturismo
  Future<Map<String, dynamic>> getBodybuilderData(String bodybuilderId) async {
    // Verificar cache primeiro
    final cacheKey = 'bodybuilder_$bodybuilderId';
    
    if (await isCacheValid(cacheKey)) {
      final cachedData = await getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    // Se não estiver em cache, buscar da API
    final response = await http.get(
      Uri.parse('$_baseUrl/data/bodybuilding/athlete/$bodybuilderId'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Normalizar dados
      if (data.containsKey('weight_lbs')) {
        data['weight'] = normalizeWeight(data['weight_lbs']);
      }
      
      if (data.containsKey('height_inches')) {
        data['height'] = normalizeHeight(data['height_inches']);
      }
      
      // Armazenar em cache
      await setCachedData(cacheKey, data, expiryInSeconds: 3600); // 1 hora
      
      return data;
    } else {
      // Consider logging this error to MonitoringService, including bodybuilderId, response.statusCode, response.body
      print('Failed to load bodybuilder data for $bodybuilderId: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load bodybuilder data for $bodybuilderId. Status: ${response.statusCode}');
    }
  }
  // Add .timeout(Duration(seconds: 10)) to http.get call for production
}