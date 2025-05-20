import 'package:flutter/material.dart';
import 'package:sportmaster_ai/services/agent_service.dart';
import 'package:sportmaster_ai/services/opensearch_service.dart';
import 'package:sportmaster_ai/services/embedding_service.dart';
import 'package:sportmaster_ai/widgets/hybrid_search_bar.dart';
import 'package:sportmaster_ai/widgets/performance_radar_chart.dart';
import 'package:sportmaster_ai/widgets/agent_recommendation_widget.dart';

class MMADashboard extends StatefulWidget {
  @override
  _MMADashboardState createState() => _MMADashboardState();
}

class _MMADashboardState extends State<MMADashboard> {
  late final MMAAgent _agent;
  bool _isLoading = false;
  Map<String, dynamic> _selectedFighter = {};
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
    
    _agent = MMAAgent(
      openSearchService: openSearchService,
      embeddingService: embeddingService,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Análise de MMA'),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HybridSearchBar(
                    modalidade: 'mma',
                    onSearch: _searchFighter,
                  ),
                  SizedBox(height: 20),
                  if (_selectedFighter.isNotEmpty) _buildFighterProfile(),
                  SizedBox(height: 20),
                  if (_analysisResults.isNotEmpty) _buildAnalysisResults(),
                  SizedBox(height: 20),
                  if (_recommendations.isNotEmpty) 
                    AgentRecommendationWidget(
                      agentType: AgentType.MMA,
                      recommendations: _recommendations,
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildFighterProfile() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perfil do Lutador', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(_selectedFighter['image_url'] ?? 
                      'https://via.placeholder.com/80'),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedFighter['name'] ?? 'Nome não disponível', 
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Categoria: ${_selectedFighter['weight_class'] ?? 'N/A'}'),
                      Text('Cartel: ${_selectedFighter['record'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            PerformanceRadarChart(
              metrics: ['Striking', 'Grappling', 'Cardio', 'Defense', 'Power'],
              values: [
                _selectedFighter['striking'] ?? 0.0,
                _selectedFighter['grappling'] ?? 0.0,
                _selectedFighter['cardio'] ?? 0.0,
                _selectedFighter['defense'] ?? 0.0,
                _selectedFighter['power'] ?? 0.0,
              ],
            ),
            
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _analyzePerformance,
              child: Text('Comparar com Meu Perfil'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisResults() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparação de Desempenho', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            // Implementar visualização de comparação
          ],
        ),
      ),
    );
  }
  
  Future<void> _searchFighter(String query) async {
    setState(() => _isLoading = true);
    
    try {
      // Simulação de busca
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _selectedFighter = {
          'name': 'Khabib Nurmagomedov',
          'weight_class': 'Peso Leve',
          'record': '29-0-0',
          'image_url': 'https://example.com/khabib.jpg',
          'striking': 0.75,
          'grappling': 0.95,
          'cardio': 0.90,
          'defense': 0.85,
          'power': 0.80,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na busca: $e')),
      );
    }
  }
  
  Future<void> _analyzePerformance() async {
    setState(() => _isLoading = true);
    
    try {
      // Dados de exemplo do usuário
      final userData = {
        'striking': 0.65,
        'grappling': 0.70,
        'cardio': 0.80,
        'defense': 0.60,
        'power': 0.75,
      };
      
      final analysisResults = await _agent.analyzePerformance(userData);
      final recommendations = await _agent.getRecommendations(analysisResults);
      
      setState(() {
        _analysisResults = analysisResults;
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na análise: $e')),
      );
    }
  }
}