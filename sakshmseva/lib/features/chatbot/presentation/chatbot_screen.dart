import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

/// Ask Sakshm – connected to the sgp RAG backend via /ask endpoint.
///
/// To start the backend, open a NEW terminal and run:
///   cd r:\DEGREE\Mad
///   python run_server.py
///
/// The server listens on port 8000.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  // Web/Chrome: localhost. Real Realme 8: change to PC's LAN IP
  static const _baseUrl = 'http://localhost:8000';

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Namaste! I am Sakshm, your AI assistant for Gujarat government schemes.\n\nAsk me anything about schemes, eligibility, or how to apply!',
      isBot: true,
      time: _now(),
    ),
  ];

  static const _quickReplies = [
    'How to apply for PM-Kisan?',
    'Am I eligible for scholarships?',
    'Documents required for Aadhaar?',
    'Agriculture schemes in Gujarat',
    'Women empowerment schemes',
  ];

  static String _now() {
    final t = DateTime.now();
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final question = text.trim();
    _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: question, isBot: false, time: _now()));
      _messages.add(_ChatMessage(text: '...', isBot: true, time: '', isTyping: true));
    });
    _scrollToBottom();

    String answer;
    try {
      // sgp api.py uses query param: POST /ask?query=...
      final uri = Uri.parse('$_baseUrl/ask').replace(queryParameters: {'query': question});
      final response = await http.post(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        answer = (data['answer'] as String? ?? '').trim();
        if (answer.isEmpty) answer = 'I could not find a specific answer. Please try rephrasing your question.';
      } else {
        answer = 'Server error (${response.statusCode}). Please try again.';
      }
    } on TimeoutException {
      answer = '⏱ Request timed out.\n\nMake sure the server is running:\n  python run_server.py';
    } catch (_) {
      answer = '🔌 Could not connect to the AI server.\n\n'
          'Start it in a new terminal:\n\n'
          '  cd r:\\DEGREE\\Mad\n'
          '  python run_server.py\n\n'
          'Then ask your question again.';
    }

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.isTyping);
      _messages.add(_ChatMessage(text: answer, isBot: true, time: _now()));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask Sakshm', style: AppTextStyles.titleMedium),
                Text(
                  'AI ASSISTANT • sgp RAG Model',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.statusOpen, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('How to activate the chatbot'),
                content: const Text(
                  'Powered by the sgp RAG model.\n\n'
                  'Open a NEW terminal and run:\n\n'
                  '  cd r:\\DEGREE\\Mad\n'
                  '  python run_server.py\n\n'
                  'Wait for "Application startup complete", then ask questions!',
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('TODAY', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 2)),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(message: _messages[i]),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _sendMessage(_quickReplies[i]),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(_quickReplies[i], style: AppTextStyles.bodySmall),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: AppColors.backgroundWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Ask about Gujarat government schemes...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.backgroundBeige,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isBot = message.isBot;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBot) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.primaryGreenSurface, shape: BoxShape.circle),
              child: const Icon(Icons.smart_toy_outlined, color: AppColors.primaryGreen, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isBot ? AppColors.surfaceCard : AppColors.primaryGreen,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isBot ? 4 : 14),
                      topRight: Radius.circular(isBot ? 14 : 4),
                      bottomLeft: const Radius.circular(14),
                      bottomRight: const Radius.circular(14),
                    ),
                  ),
                  child: message.isTyping
                      ? const _TypingIndicator()
                      : Text(
                          message.text,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isBot ? AppColors.textPrimary : Colors.white,
                          ),
                        ),
                ),
                if (message.time.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(message.time, style: AppTextStyles.labelSmall),
                  ),
              ],
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Container(
          margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isBot, required this.time, this.isTyping = false});
  final String text;
  final bool isBot;
  final String time;
  final bool isTyping;
}
