import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kApiKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';
const String kModel = 'gemini-3.5-flash-lite';
void main() => runApp(const GeminiChatApp());
class GeminiChatApp extends StatelessWidget {
  const GeminiChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini AI Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const ChatScreen(),
    );
  }
}
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
class GeminiService {
  static final Uri _endpoint = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/$kModel:generateContent',
  );
  Future<String> generateReply(List<Map<String, dynamic>> contents) async {
    final response = await http
        .post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': kApiKey,
      },
      body: jsonEncode({'contents': contents}),
    )
        .timeout(const Duration(seconds: 120));
    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      final message = data['error']?['message'] ??
          'Request failed with status ${response.statusCode}';
      throw Exception(message);
    }
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      final blockReason = data['promptFeedback']?['blockReason'];
      throw Exception(blockReason != null
          ? 'Your prompt was blocked ($blockReason).'
          : 'Gemini returned an empty response.');
    }
    final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini returned no text. Try rephrasing your prompt.');
    }
    return parts.map((p) => (p['text'] ?? '').toString()).join().trim();
  }
}
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _gemini = GeminiService();
  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
  Future<void> _sendMessage() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _isLoading) return;
    setState(() {
      _messages.add(ChatMessage(text: prompt, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();
    if (kApiKey.startsWith('PASTE_')) {
      setState(() {
        _messages.add(const ChatMessage(
          text: 'API key missing. Open main.dart and paste your Gemini API '
              'key into kApiKey.',
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }
    _history.add({
      'role': 'user',
      'parts': [
        {'text': prompt}
      ],
    });
    try {
      final reply = await _gemini.generateReply(_history);
      _history.add({
        'role': 'model',
        'parts': [
          {'text': reply}
        ],
      });
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(text: reply, isUser: false)));
    } on TimeoutException {
      _history.removeLast();
      _showError('The request timed out. Please try again.');
    } on FormatException {
      _history.removeLast();
      _showError('Could not read the server response.');
    } catch (e) {
      _history.removeLast();
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }
  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: false, isError: true));
    });
  }
  void _clearChat() {
    setState(() {
      _messages.clear();
      _history.clear();
    });
  }
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini AI Chat'),
        backgroundColor: colors.primaryContainer,
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.isEmpty ? null : _clearChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        MessageBubble(message: _messages[index]),
                  ),
                ),
                if (_isLoading) const _TypingIndicator(),
                _buildInputBar(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildInputBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type your question...',
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send',
            onPressed: _isLoading ? null : _sendMessage,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final Color background = message.isError
        ? colors.errorContainer
        : isUser
        ? colors.primary
        : colors.secondaryContainer;
    final Color foreground = message.isError
        ? colors.onErrorContainer
        : isUser
        ? colors.onPrimary
        : colors.onSecondaryContainer;
    final double maxBubbleWidth =
    (MediaQuery.of(context).size.width * 0.78).clamp(200.0, 560.0).toDouble();
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: SelectableText(
        message.text,
        style: TextStyle(color: foreground, fontSize: 16, height: 1.35),
      ),
    );
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: isUser ? colors.primaryContainer : colors.tertiaryContainer,
      child: Icon(
        isUser ? Icons.person : (message.isError ? Icons.error_outline : Icons.auto_awesome),
        size: 18,
        color: isUser ? colors.onPrimaryContainer : colors.onTertiaryContainer,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isUser
            ? [bubble, const SizedBox(width: 8), avatar]
            : [avatar, const SizedBox(width: 8), bubble],
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              'Ask Gemini anything',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Type a question below and press send.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Gemini is thinking...'),
        ],
      ),
    );
  }
}
