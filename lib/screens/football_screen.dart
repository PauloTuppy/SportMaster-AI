import 'package:flutter/material.dart';
import 'package:sportmaster_ai/services/agent_service.dart';
import 'package:sportmaster_ai/services/langgraph_service.dart';
import 'package:sportmaster_ai/services/autogen_service.dart';

class FootballScreen extends StatefulWidget {
  @override
  _FootballScreenState createState() => _FootballScreenState();
}

class _FootballScreenState extends State<FootballScreen> {
  final FootballAgent _agent = FootballAgent();
  final LangGraphService _langGraph = LangGraphService();
  final AutoGenService _autoGen = AutoGenService();
  
  Map<String, dynamic> _analysisResults = {};
  Map<String, dynamic> _recommendations = {};
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Análise de Futebol'),
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserDataForm(),
                  SizedBox(height: 20),
                  if (_analysisResults.isNotEmpty) _buildAnalysisResults(),
                  SizedBox(height: 20),
                  if (_recommendations.isNotEmpty) _buildRecommendations(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildUserDataForm() {
    // Form para entrada de dados do usuário
    // Implementação simplificada
    return ElevatedButton(
      onPressed: _analyzePerformance,
      child: Text('Analisar Desempenho'),
    );
  }
  
  Widget _buildAnalysisResults() {
    // Exibição dos resultados da análise
    // Implementação simplificada
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultados da Análise', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Exibir dados da análise
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendations() {
    // Exibição das recomendações
    // Implementação simplificada
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recomendações', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Exibir recomendações
          ],
        ),
      ),
    );
  }
  
  Future<void> _analyzePerformance() async {
    setState(() => _isLoading = true);
    
    try {
      // Dados de exemplo do usuário
      final userData = {
        'speed': 25.0, // km/h
        'distance': 8.5, // km por jogo
        'pass_accuracy': 0.75, // 75%
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