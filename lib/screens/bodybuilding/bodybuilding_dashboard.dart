import 'package:flutter/material.dart';
import 'package:sportmaster_ai/services/agent_service.dart';
import 'package:sportmaster_ai/services/opensearch_service.dart';
import 'package:sportmaster_ai/services/embedding_service.dart';
import 'package:sportmaster_ai/services/image_analysis_service.dart';
import 'package:sportmaster_ai/services/social_media_service.dart';
import 'package:sportmaster_ai/screens/bodybuilding/virtual_coach_screen.dart';

class BodybuildingDashboard extends StatefulWidget {
  @override
  _BodybuildingDashboardState createState() => _BodybuildingDashboardState();
}

class _BodybuildingDashboardState extends State<BodybuildingDashboard> {
  late BodybuildingAgent _agent;
  bool _isLoading = false;
  Map<String, dynamic> _analysisResults = {};
  Map<String, dynamic> _recommendations = {};
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar serviços
    // Services now fetch their config from AppConfig directly.
    final openSearchService = OpenSearchService();
    final embeddingService = EmbeddingService();
    final imageAnalysisService = ImageAnalysisService();
    final socialMediaService = SocialMediaService();
    
    // BodybuildingAgent constructor might need to be updated if it directly took config,
    // but here it takes service instances which are now using AppConfig.
    // Assuming BodybuildingAgent itself doesn't directly take baseUrls/apiKeys.
    // TODO: Add Widget tests for BodybuildingDashboard:
    // - Verify that all services are initialized in initState.
    // - Mock BodybuildingAgent and its dependencies (OpenSearchService, etc.).
    // - Test UI changes based on _isLoading state.
    // - Test navigation to VirtualCoachScreen.
    // - If _analysisResults and _recommendations were used:
    //   - Mock _agent calls to return sample data.
    //   - Verify UI correctly displays these results/recommendations.
    _agent = BodybuildingAgent(
      openSearchService: openSearchService,
      embeddingService: embeddingService,
      imageAnalysisService: imageAnalysisService,
      socialMediaService: socialMediaService,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bodybuilding Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outras widgets do dashboard...
                  
                  SizedBox(height: 20),
                  
                  // Botão para acessar o coach virtual
                  ElevatedButton.icon(
                    icon: Icon(Icons.chat),
                    label: Text('Talk to Virtual Coach'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VirtualCoachScreen(
                            sportType: 'bodybuilding',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}