import 'package:flutter/material.dart';
import 'package:sportmaster_ai/services/autogen_service.dart';

class VirtualCoachScreen extends StatefulWidget {
  final String sportType;
  
  const VirtualCoachScreen({
    Key? key,
    required this.sportType,
  }) : super(key: key);
  
  @override
  _VirtualCoachScreenState createState() => _VirtualCoachScreenState();
}

class _VirtualCoachScreenState extends State<VirtualCoachScreen> {
  final AutoGenService _autoGenService = AutoGenService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getSportTitle(widget.sportType)} Coach'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildChatList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
  
  String _getSportTitle(String sportType) {
    switch (sportType) {
      case 'bodybuilding':
        return 'Bodybuilding';
      case 'football':
        return 'Football';
      case 'mma':
        return 'MMA';
      default:
        return 'Personal';
    }
  }
  
  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        final message = _chatMessages[index];
        final isUser = message['sender'] == 'user';
        
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(message['text']!),
          ),
        );
      },
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Ask your coach...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          _isLoading
              ? const CircularProgressIndicator()
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
        ],
      ),
    );
  }
  
  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _chatMessages.add({
        'sender': 'user',
        'text': message,
      });
      _isLoading = true;
      _messageController.clear();
    });
    
    try {
      final response = await _autoGenService.getCoachAdvice(
        message,
        widget.sportType,
      );
      
      setState(() {
        _chatMessages.add({
          'sender': 'coach',
          'text': response,
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({
          'sender': 'coach',
          'text': 'Sorry, I had trouble processing that. Please try again.',
        });
        _isLoading = false;
      });
    }
  }
}