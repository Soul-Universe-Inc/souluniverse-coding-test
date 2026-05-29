import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/me_state.dart';
import '../../models/chat_message.dart';
import '../../repository/chats_repository.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/message_bubble.dart';

/// 1:1 상담 채팅방 화면.
/// Firestore 스트림으로 실시간 메시지를 수신하고,
/// REST API로 이전 메시지를 페이징 로드합니다.
class ConsultationRoomPage extends StatefulWidget {
  final String roomId;
  final String counselorName;

  const ConsultationRoomPage({
    required this.roomId,
    required this.counselorName,
    super.key,
  });

  @override
  State<ConsultationRoomPage> createState() => _ConsultationRoomPageState();
}

class _ConsultationRoomPageState extends State<ConsultationRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoadingMore = false;
  bool _isSending = false;
  StreamSubscription<ChatMessage>? _messageSubscription;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _connectFirestore();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialMessages() async {
    _isLoadingMore = true;

    final msgs = await ChatsRepository.instance.fetchMessages(widget.roomId, page: 0);

    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _isLoadingMore = false;
    });
    _scrollToBottom();
  }

  // 테스트용: 실제 Firestore 대신 10초마다 상담사 메시지 도착을 시뮬레이션
  static const _mockRealtimeContents = [
    '그렇군요, 조금 더 이야기해 주실 수 있을까요?',
    '많이 힘드셨겠어요.',
    '충분히 이해가 돼요. 계속 말씀해 주세요.',
  ];

  void _connectFirestore() {
    _messageSubscription = Stream.periodic(
      const Duration(seconds: 10),
      (i) => ChatMessage(
        id: 'realtime-$i',
        roomId: widget.roomId,
        senderId: 'counselor-1',
        content: _mockRealtimeContents[i % _mockRealtimeContents.length],
        sentAt: DateTime.now(),
        isRead: false,
      ),
    ).listen((msg) async {
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _scrollToBottom();
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels == 0 && !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    _isLoadingMore = true;
    _page++;
    final older = await ChatsRepository.instance.fetchMessages(widget.roomId, page: _page);
    if (!mounted) return;
    setState(() {
      _messages.insertAll(0, older);
      _isLoadingMore = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await ChatsRepository.instance.sendMessage(widget.roomId, text);
  }

  Future<void> _scrollToBottom() async {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final meState = context.watch<MeState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.counselorName),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '🍪 ${meState.cookie}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoadingMore) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) => MessageBubble(message: _messages[index]),
            ),
          ),
          ChatInputBar(
            onSend: (text) async {
              _controller.text = text;
              await _sendMessage();
            },
            isDisabled: _isSending,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
