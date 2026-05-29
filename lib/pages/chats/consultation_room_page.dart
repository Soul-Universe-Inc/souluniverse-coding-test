import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/chat_state.dart';
import '../../app/me_state.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/message_bubble.dart';

/// 1:1 상담 채팅방 화면.
/// [ChatState] 프로바이더를 통해 실시간 메시지 수신 및 페이징 로드 등의 상태를 관리합니다.
class ConsultationRoomPage extends StatelessWidget {
  final String roomId;
  final String counselorName;

  const ConsultationRoomPage({
    required this.roomId,
    required this.counselorName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // 채팅방 진입 시 지역 상태로 ChatState를 공급하며,
    // 화면을 나갈 때(pop) 자동으로 dispose 처리되어 스트림 구독이 해제됩니다.
    return ChangeNotifierProvider<ChatState>(
      create: (_) => ChatState(roomId: roomId),
      child: _ConsultationRoomView(counselorName: counselorName),
    );
  }
}

class _ConsultationRoomView extends StatefulWidget {
  final String counselorName;

  const _ConsultationRoomView({required this.counselorName});

  @override
  State<_ConsultationRoomView> createState() => _ConsultationRoomViewState();
}

class _ConsultationRoomViewState extends State<_ConsultationRoomView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 메시지 리스트의 변화를 감지해 자동으로 스크롤 최하단 이동 처리를 하기 위한 캐싱 변수
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final chatState = context.read<ChatState>();
    // 최상단으로 스크롤되었고 로딩 중이 아닐 때 이전 메시지를 더 페이징 로드합니다.
    if (_scrollController.position.pixels == 0 && !chatState.isLoadingMore) {
      chatState.loadMoreMessages();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await context.read<ChatState>().sendMessage(text);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = context.watch<ChatState>();
    final meState = context.watch<MeState>();

    // 메시지 개수가 변경되면(새 메시지 수신, 페이징 로드, 메시지 전송 등) 스크롤 맨 아래로 이동
    if (chatState.messages.length != _lastMessageCount) {
      _lastMessageCount = chatState.messages.length;
      _scrollToBottom();
    }

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
          if (chatState.isLoadingMore) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) => MessageBubble(message: chatState.messages[index]),
            ),
          ),
          ChatInputBar(
            onSend: (text) async {
              _controller.text = text;
              await _sendMessage();
            },
            isDisabled: chatState.isSending,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
