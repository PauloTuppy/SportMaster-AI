import 'package:flutter/material.dart';
import 'package:sportmaster_ai/services/agent_service.dart';
import 'package:sportmaster_ai/services/agent_integration_service.dart';
import 'package:sportmaster_ai/services/opensearch_service.dart';
import 'package:sportmaster_ai/services/embedding_service.dart';
import 'package:sportmaster_ai/services/image_analysis_service.dart';
import 'package:sportmaster_ai/services/social_media_service.dart';
import 'package:sportmaster_ai/services/monitoring_service.dart';

class IntegratedRecommendationScreen extends StatefulWidget {
  @override
  _IntegratedRecommendationScreenState createState() => _IntegratedRecommendationScreenState();
}

class _IntegratedRecommendationScreenState extends State<IntegratedRecommendationScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic> _combinedRecommendations = {};
  
  // Serviços
  late FootballAgent _footballAgent;
  late MMAAgent _mmaAgent;
  late BodybuildingAgent _bodybuildingAgent;
  late AgentIntegration