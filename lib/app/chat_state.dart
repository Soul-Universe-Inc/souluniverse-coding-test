import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../repository/chats_repository.dart';

/// 1:1 상담 채팅방의 비즈니스 로직 및 상태 관리 클래스.
/// 특정 roomId에 대한 실시간 메시지 수신 및 페이징 로드를 담당합니다.
class ChatState extends ChangeNotifier {
  final String roomId;

  List<ChatMessage> _messages = [];
  bool _isLoadingMore = false;
  bool _isSending = false;
  int _page = 0;
  StreamSubscription<ChatMessage>? _messageSubscription;

  List<ChatMessage> get messages => _messages;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSending => _isSending;

  ChatState({required this.roomId}) {
    _loadInitialMessages();
    _connectFirestore();
  }

  /// 첫 페이지 메시지 로드
  Future<void> _loadInitialMessages() async {
    _isLoadingMore = true;
    notifyListeners();

    try {
      final msgs = await ChatsRepository.instance.fetchMessages(roomId, page: 0);
      _messages = msgs;
    } catch (e) {
      debugPrint("초기 메시지 로드 중 오류 발생: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // 실제 Firestore 대신 10초마다 상담사 메시지 도착을 시뮬레이션
  static const _mockRealtimeContents = [
    '그렇군요, 조금 더 이야기해 주실 수 있을까요?',
    '많이 힘드셨겠어요.',
    '충분히 이해가 돼요. 계속 말씀해 주세요.',
  ];

  /// Firestore 실시간 스트림 연결 시뮬레이션
  void _connectFirestore() {
    _messageSubscription = Stream.periodic(
      const Duration(seconds: 10),
      (i) => ChatMessage(
        id: 'realtime-$i',
        roomId: roomId,
        senderId: 'counselor-1',
        content: _mockRealtimeContents[i % _mockRealtimeContents.length],
        sentAt: DateTime.now(),
        isRead: false,
      ),
    ).listen((msg) {
      _messages = [..._messages, msg];
      notifyListeners();
    });
  }

  /// 스크롤이 상단에 도달할 때 이전 페이지 메시지 로드 (페이징)
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _page++;
    try {
      final older = await ChatsRepository.instance.fetchMessages(roomId, page: _page);
      _messages = [...older, ..._messages];
    } catch (e) {
      _page--; // 실패 시 페이지 상태 원복
      debugPrint("이전 메시지 로드 중 오류 발생: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 새로운 메시지 전송
  Future<void> sendMessage(String text) async {
    if (text.isEmpty || _isSending) return;

    _isSending = true;
    notifyListeners();

    try {
      await ChatsRepository.instance.sendMessage(roomId, text);
    } catch (e) {
      debugPrint("메시지 전송 중 오류 발생: $e");
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}
