import 'package:flutter/material.dart';
import 'package:sportmaster_ai/services/agent_service.dart';
import 'package:sportmaster_ai/services/opensearch_service.dart';
import 'package:sportmaster_ai/services/embedding_service.dart';
import 'package:sportmaster_ai/widgets/three_d_model_viewer.dart';

class PhysiqueComparison extends StatefulWidget {
  @override
  _PhysiqueComparisonState createState() => _PhysiqueComparisonState();
}

class _PhysiqueComparisonState extends State<PhysiqueComparison> {
  late final BodybuildingAgent _agent;
  bool _isLoading = false;
  Map<String, dynamic> _selectedAthlete = {};
  Map<String, dynamic> _userMeasurements = {
    'height': 175,
    'weight': 80,
    'chest': 100,
    'waist': 80,
    'arms': 38,
    'legs': 60,
    'body_fat': 12.0,
  };
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar serviços
    // Services now fetch their config from AppConfig directly.
    final openSearchService = OpenSearchService();
    final embeddingService = EmbeddingService();
    
    // Assuming BodybuildingAgent itself doesn't directly take baseUrls/apiKeys.
    _agent = BodybuildingAgent(
      openSearchService: openSearchService,
      embeddingService: embeddingService,
    );
    
    _loadDefaultAthlete();
  }
  
  Future<void> _loadDefaultAthlete() async {
    setState(() => _isLoading = true);
    
    try {
      // Simulação de busca
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _selectedAthlete = {
          'name': 'Chris Bumstead',
          'height': 185,
          'weight': 98,
          'chest': 130,
          'waist': 85,
          'arms': 50,
          'legs': 75,
          'body_fat': 5.0,
          'image_url': 'https://example.com/cbum.jpg',
          'model_url': 'assets/cbum_model.glb',
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar atleta: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comparação Física'),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildModelComparison(),
                ),
                Expanded(
                  flex: 2,
                  child: _buildMeasurementsComparison(),
                ),
              ],
            ),
    );
  }
  
  Widget _buildModelComparison() {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparação 3D', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(
              child: ThreeDModelViewer(
                userModel: 'assets/user_model.glb',
                athleteModel: _selectedAthlete['model_url'] ?? 'assets/default_model.glb',
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMeasurementsComparison() {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparação de Medidas', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: [
                  _buildMeasurementRow('Altura (cm)', 
                      _userMeasurements['height'], _selectedAthlete['height']),
                  _buildMeasurementRow('Peso (kg)', 
                      _userMeasurements['weight'], _selectedAthlete['weight']),
                  _buildMeasurementRow('Peitoral (cm)', 
                      _userMeasurements['chest'], _selectedAthlete['chest']),
                  _buildMeasurementRow('Cintura (cm)', 
                      _userMeasurements['waist'], _selectedAthlete['waist']),
                  _buildMeasurementRow('Braços (cm)', 
                      _userMeasurements['arms'], _selectedAthlete['arms']),
                  _buildMeasurementRow('Pernas (cm)', 
                      _userMeasurements['legs'], _selectedAthlete['legs']),
                  _buildMeasurementRow('Gordura Corporal (%)', 
                      _userMeasurements['body_fat'], _selectedAthlete['body_fat']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMeasurementRow(String label, dynamic userValue, dynamic athleteValue) {
    final difference = (userValue - athleteValue).abs();
    final percentDiff = athleteValue != 0 ? (difference / athleteValue * 100).toStringAsFixed(1) : 'N/A';
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Você', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('$userValue', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedAthlete['name'] ?? 'Atleta', 
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('$athleteValue', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diferença', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('$difference ($percentDiff%)', 
                        style: TextStyle(fontSize: 16, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}