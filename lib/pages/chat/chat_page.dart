import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../colors.dart';
import '../../utilities/openai.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/chat_provider.dart';
import '../../backend-api/sync_service.dart';

class ChatPage extends StatefulHookConsumerWidget {
  final String? title;

  const ChatPage({
    Key? key, 
    this.title,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom(immediate: true);
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    // Verificar conexión antes de enviar a la IA
    final isOnline = await requestOpenAiResponse([]).then((_) => true).catchError((_) => false); 
    // Wait, requestOpenAiResponse might not be the best way to check connection.
    // I should use SyncService.isOnline().
    
    if (!await SyncService.isOnline()) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text("Atlas necesita conexión a internet para funcionar. Por favor, conéctate y reintenta."),
           backgroundColor: Colors.orange,
         )
       );
       return;
    }

    final chatNotifier = ref.read(chatProvider.notifier);
    
    setState(() {
      chatNotifier.addMessage("user", userInput);
      _controller.clear();
      _isLoading = true;
    });
    
    _scrollToBottom();

    final messages = ref.read(chatProvider);
    final response = await requestOpenAiResponse(messages);

    setState(() {
      if (response != null) {
        chatNotifier.addMessage("assistant", response);
      } else {
        chatNotifier.addMessage("assistant", "Lo siento, tuve un problema al procesar tu solicitud.");
      }
      _isLoading = false;
    });
    
    _scrollToBottom();
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Vaciar chat"),
        content: const Text("¿Estás seguro de que deseas eliminar todo el historial de la conversación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: const Text("VACIAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // To make it loop properly, we use a simple Infinite Animation
  Widget _buildAnimatedRobot() {
    return _RobotFloater();
  }

  Widget _buildQuickAction(String label, String prompt) {
    return GestureDetector(
      onTap: () {
        _controller.text = prompt;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HospiredColors.primary.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(color: HospiredColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, String> message) {
    final role = message["role"];
    if (role == "system") return const SizedBox.shrink();
    
    final isUser = role == "user";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: HospiredColors.primary,
                child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? HospiredColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: MarkdownBody(
                data: message["content"] ?? "",
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.white : Colors.black,
                  ),
                  listBullet: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                  ),
                  h1: TextStyle(color: isUser ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                  h2: TextStyle(color: isUser ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  h3: TextStyle(color: isUser ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: HospiredColors.primaryLight,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final displayMessages = messages.where((m) => m["role"] != "system").toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: HospiredColors.primary, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Atlas IA",
          style: TextStyle(color: HospiredColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: HospiredColors.primary),
            onPressed: () => _confirmClearChat(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: displayMessages.length <= 1 
                ? Center(child: _buildAnimatedRobot())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (_, index) => _buildMessage(messages[index]),
                  ),
            ),
            if (displayMessages.length <= 1 && !_isLoading)
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildQuickAction("📊 Ventas", "¿Cómo van mis ventas este mes?"),
                    _buildQuickAction("💰 Rentabilidad", "¿Mi emprendimiento es realmente rentable?"),
                    _buildQuickAction("🏥 Salud Financiera", "¿Qué salud financiera tiene mi negocio actualmente?"),
                  ],
                ),
              ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: HospiredColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Analizando datos...",
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: "Pregunta sobre tus finanzas...",
                          hintStyle: TextStyle(color: Colors.black45),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: HospiredColors.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RobotFloater extends StatefulWidget {
  @override
  _RobotFloaterState createState() => _RobotFloaterState();
}

class _RobotFloaterState extends State<_RobotFloater> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HospiredColors.primary.withOpacity(0.05),
                  boxShadow: [
                    BoxShadow(
                      color: HospiredColors.primary.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.smart_toy_rounded,
                    size: 80,
                    color: HospiredColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "¡Hola! Soy Atlas",
                style: TextStyle(
                  color: HospiredColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tu Mentor Financiero Inteligente",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
