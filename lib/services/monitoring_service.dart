import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MonitoringService {
  final String _baseUrl;
  final String _apiKey;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  MonitoringService({
    required String baseUrl,
    required String apiKey,
  }) : 
    _baseUrl = baseUrl,
    _apiKey = apiKey;
  
  // Inicializar serviço de notificações
  Future<void> initialize() async {
    // Configurar notificações locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
    );
    
    // Configurar Firebase Messaging
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Lidar com mensagens recebidas quando o app está em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'Alerta',
        body: message.notification?.body ?? 'Novo alerta do sistema',
      );
    });
    
    // Registrar para tópicos de alertas
    await _firebaseMessaging.subscribeToTopic('system_alerts');
    await _firebaseMessaging.subscribeToTopic('performance_alerts');
  }
  
  // Mostrar notificação local
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'system_alerts_channel',
      'System Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
  
  // Enviar métricas de desempenho para o sistema de monitoramento
  Future<void> sendPerformanceMetrics(Map<String, dynamic> metrics) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/monitoring/metrics'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(metrics),
      );
    } catch (e) {
      print('Erro ao enviar métricas: $e');
    }
  }
  
  // Registrar erro no sistema
  Future<void> logError(String errorType, String errorMessage, StackTrace? stackTrace) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/monitoring/error'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'error_type': errorType,
          'error_message': errorMessage,
          'stack_trace': stackTrace?.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Erro ao registrar erro: $e');
    }
  }
  
  // Verificar status do sistema
  Future<Map<String, dynamic>> checkSystemStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/monitoring/status'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check system status');
      }
    } catch (e) {
      print('Erro ao verificar status do sistema: $e');
      return {
        'status': 'error',
        'message': 'Não foi possível verificar o status do sistema',
      };
    }
  }
}