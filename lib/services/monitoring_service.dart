import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sportmaster_ai/config/app_config.dart';

class MonitoringService {
  final String _baseUrl = AppConfig.monitoringApiBaseUrl;
  final String _apiKey = AppConfig.monitoringApiKey; // Or AppConfig.genericApiKey if intended
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Constructor can be simplified
  // MonitoringService();

  // Inicializar serviço de notificações
  Future<void> initialize() async {
    // Configurar notificações locais
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
      );
    } catch (e, stackTrace) {
      print('Error initializing local notifications: $e, StackTrace: $stackTrace');
      // Optionally, rethrow or handle if critical
    }
    
    // Configurar Firebase Messaging
    try {
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
    } catch (e, stackTrace) {
      print('Error setting up Firebase Messaging: $e, StackTrace: $stackTrace');
      // Optionally, rethrow or handle if critical
    }
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
      ).timeout(const Duration(seconds: 10)); // Example timeout
    } catch (e, stackTrace) {
      // Consider more robust local fallback or retry mechanism if metrics are critical
      print('Erro ao enviar métricas: $e, StackTrace: $stackTrace');
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
      ).timeout(const Duration(seconds: 10)); // Example timeout
    } catch (e, sTrace) { // Renamed stackTrace to sTrace to avoid conflict with parameter
      // This is tricky: if logError itself fails, where do you log that?
      // Printing to console is often the last resort.
      // Avoid calling logError recursively here.
      print('CRITICAL: Failed to send error to monitoring service. Original Error: $errorMessage. Logging Error: $e, StackTrace: $sTrace');
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
      
      // Add .timeout(Duration(seconds: 15)) to http.get call for production
      if (response.statusCode == 200) {
        try {
          return jsonDecode(response.body);
        } on FormatException catch (fe, stackTrace) {
          print('Malformed JSON response for system status: ${response.body}, Error: $fe, StackTrace: $stackTrace');
          // logError('MonitoringService', 'Malformed JSON for system status: ${response.body}', fe.stackTrace); // Careful with recursion
          throw Exception('Failed to parse system status response.');
        }
      } else {
        print('Failed to check system status: ${response.statusCode} ${response.body}');
        // logError('MonitoringService', 'Failed to check system status: ${response.statusCode} ${response.body}', StackTrace.current); // Careful with recursion
        throw Exception('Failed to check system status. Status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      // Avoid calling logError if e is from logError itself to prevent loops.
      // Check if (e is! Exception || !e.toString().contains("CRITICAL")) before logging.
      print('Erro ao verificar status do sistema: $e, StackTrace: $stackTrace');
      return {
        'status': 'error',
        'message': 'Não foi possível verificar o status do sistema: $e',
      };
    }
  }
}