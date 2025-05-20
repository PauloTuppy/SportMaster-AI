import 'package:flutter/material.dart';
import 'package:sportmaster_ai/screens/football_screen.dart';
import 'package:sportmaster_ai/screens/mma_screen.dart';
import 'package:sportmaster_ai/screens/bodybuilding_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SportMaster AI'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16.0),
        children: [
          _buildSportCard(context, 'Futebol', Icons.sports_soccer, 
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => FootballScreen()))),
          _buildSportCard(context, 'MMA', Icons.sports_mma, 
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => MMAScreen()))),
          _buildSportCard(context, 'Fisiculturismo', Icons.fitness_center, 
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => BodybuildingScreen()))),
        ],
      ),
    );
  }
  
  Widget _buildSportCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0),
            SizedBox(height: 8.0),
            Text(title, style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}