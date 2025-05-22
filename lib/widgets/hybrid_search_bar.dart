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
  Set<String> _selectedFilters = {}; // State for selected filters
  
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
          _buildChip('Atacantes'),
          _buildChip('Meio-campistas'),
          // Add more football specific chips if needed
        ]);
        break;
      case 'mma':
        chips.addAll([
          _buildChip('Peso Leve'),
          _buildChip('Peso Médio'),
          // Add more MMA specific chips if needed
        ]);
        break;
      case 'bodybuilding':
        chips.addAll([
          _buildChip('Classic Physique'),
          _buildChip('Men\'s Physique'),
          // Add more bodybuilding specific chips if needed
            },
          ),
        ]);
        break;
    }
    // Add default case or handle unknown modalidade if necessary
    return chips;
  }

  Widget _buildChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilters.contains(label),
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            _selectedFilters.add(label);
          } else {
            _selectedFilters.remove(label);
          }
        });
        // TODO: Decide if selecting a filter should immediately trigger a search
        // e.g., _performSearch(_searchController.text);
        // This might require widget.onSearch to accept filter data.
      },
    );
  }
  
  Future<void> _performSearch(String query) async {
    // Consider also passing _selectedFilters to widget.onSearch
    // For now, it only passes the query.
    // if (query.isEmpty && _selectedFilters.isEmpty) return; // Or some other logic for empty search
    if (query.isEmpty && _selectedFilters.isEmpty && mounted) { // Check mounted before setState
       // If query and filters are empty, maybe clear results or do nothing
      return;
    }
    
    if (mounted) { // Check mounted before setState
      setState(() {
        _isSearching = true;
      });
    }
    
    try {
      // Modify widget.onSearch to accept filters: await widget.onSearch(query, _selectedFilters);
      await widget.onSearch(query); 
    } finally {
      if (mounted) { // Check mounted before setState
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
}