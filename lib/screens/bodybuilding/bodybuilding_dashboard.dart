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
    final openSearchService = OpenSearchService(
      endpoint: 'https://search-sportmaster-xyz.us-east-1.es.amazonaws.com',
      region: 'us-east-1',
      accessKey: 'AKIAXXXXXXXXXXXXXXXX',
      secretKey: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    );
    
    final embeddingService = EmbeddingService(
      baseUrl: 'https://api.sportmaster.ai',
      apiKey: 'sk-XXXXXXXXXXXXXXXXXXXXXXXX',
    );
    
    final imageAnalysisService = ImageAnalysisService(
      baseUrl: 'https://api.sportmaster.ai',
      apiKey: 'sk-XXXXXXXXXXXXXXXXXXXXXXXX',
    );
    
    final socialMediaService = SocialMediaService(
      baseUrl: 'https://api.sportmaster.ai',
      apiKey: 'sk-XXXXXXXXXXXXXXXXXXXXXXXX',
    );
    
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