import 'package:flutter/material.dart';
import '/services/sathi_ai_service.dart';

class SathiChatScreen extends StatefulWidget {
  const SathiChatScreen({super.key});

  @override
  State<SathiChatScreen> createState() => _SathiChatScreenState();
}

class _SathiChatScreenState extends State<SathiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final SathiAIService _aiService = SathiAIService();

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Show welcome message on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addWelcomeMessage();
    });
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Hi! I'm SATHI, your friendly study assistant! 👋\n\n"
              "I can guide you on app features, marks, attendance, notes, and even give you motivational tips if needed.\n\n"
              "Feel free to ask me anything related to your studies!",
          isUser: false,
          isWelcome: true,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final aiReply = await _aiService.sendMessage(text);

      setState(() {
        _messages.add(ChatMessage(text: aiReply, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: "Oops! Something went wrong 😅", isUser: false),
        );
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            // Mascot placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.book_rounded,
                color: Colors.amber.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'SATHI Assistant',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      return _buildMessageBubble(message, theme);
                    },
                  ),
          ),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade200, width: 3),
            ),
            child: Icon(
              Icons.book_rounded,
              size: 60,
              color: Colors.amber.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Hi! I\'m SATHI 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Your friendly study assistant is here to help!\nStart a conversation below.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.textTheme.bodyMedium?.color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, ThemeData theme) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && message.isWelcome) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
              ),
              child: Icon(
                Icons.book_rounded,
                color: Colors.amber.shade700,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : (theme.brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (theme.textTheme.bodyLarge?.color ?? Colors.black87),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade300, width: 1.5),
            ),
            child: Icon(
              Icons.book_rounded,
              color: Colors.amber.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animationValue = ((value + delay) % 1.0);
        return Opacity(
          opacity: animationValue < 0.5
              ? animationValue * 2
              : 2 - (animationValue * 2),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 15,
                ),
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isWelcome;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isWelcome = false,
  });
}
