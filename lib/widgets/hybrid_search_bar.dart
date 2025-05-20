import 'package:flutter/material.dart';

class HybridSearchBar extends StatefulWidget {
  final String modalidade;
  final Function(String) onSearch;
  
  const HybridSearchBar({
    Key? key,
    required this.modalidade,
    required this.onSearch,
  }) : super(key: key);
  
  @override
  _HybridSearchBarState createState() => _HybridSearchBarState();
}

class _HybridSearchBarState extends State<HybridSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _getHintText(),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _isSearching 
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: EdgeInsets.all(6.0),
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
              ),
              onSubmitted: (value) {
                _performSearch(value);
              },
            ),
            SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: _buildFilterChips(),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getHintText() {
    switch (widget.modalidade) {
      case 'football':
        return 'Buscar jogadores (ex: Cristiano Ronaldo)';
      case 'mma':
        return 'Buscar lutadores (ex: Khabib Nurmagomedov)';
      case 'bodybuilding':
        return 'Buscar fisiculturistas (ex: Chris Bumstead)';
      default:
        return 'Buscar atletas';
    }
  }
  
  List<Widget> _buildFilterChips() {
    final List<Widget> chips = [];
    
    switch (widget.modalidade) {
      case 'football':
        chips.addAll([
          FilterChip(
            label: Text('Atacantes'),
            onSelected: (selected) {
              // Aplicar filtro
            },
          ),
          FilterChip(
            label: Text('Meio-campistas'),
            onSelected: (selected) {
              // Aplicar filtro
            },
          ),
        ]);
        break;
      case 'mma':
        chips.addAll([
          FilterChip(
            label: Text('Peso Leve'),
            onSelected: (selected) {
              // Aplicar filtro
            },
          ),
          FilterChip(
            label: Text('Peso Médio'),
            onSelected: (selected) {
              // Aplicar filtro
            },
          ),
        ]);
        break;
      case 'bodybuilding':
        chips.addAll([
          FilterChip(
            label: Text('Classic Physique'),
            onSelected: (selected) {
              // Aplicar filtro
            },
          ),
          FilterChip(
            label: Text('Men\'s Physique'),
            onSelected: (selected) {
              // Aplicar filtro
            },
          ),
        ]);
        break;
    }
    
    return chips;
  }
  
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      await widget.onSearch(query);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }
}