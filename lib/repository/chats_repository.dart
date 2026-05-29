import '../models/chat_message.dart';

// 테스트용 Mock — 실제 API 호출 없음
class ChatsRepository {
  ChatsRepository._();
  static final ChatsRepository instance = ChatsRepository._();

  static const _counselorId = 'counselor-1';
  static const _userId = 'user-demo';

  static const _contents = [
    '안녕하세요, 오늘 상담에 오신 것을 환영해요.',
    '요즘 어떻게 지내고 계신가요?',
    '그 감정을 조금 더 이야기해 주실 수 있을까요?',
    '많이 힘드셨겠어요. 충분히 이해가 돼요.',
    '그런 상황에서 어떻게 대처하셨나요?',
    '걱정되는 부분이 있으시면 편하게 말씀해 주세요.',
    '지금 느끼는 감정이 어떤 것인지 표현해 보신다면?',
    '조금씩 나아지고 있다는 느낌이 드시나요?',
    '혹시 이런 상황이 언제부터 시작됐는지 기억하시나요?',
    '맞아요, 그건 정말 어려운 상황이네요.',
    '오늘 이야기 나눠주셔서 감사해요.',
    '다음 상담까지 이 부분을 조금 생각해 보시면 어떨까요?',
    '저도 그 상황이 쉽지 않았을 거라 생각해요.',
    '충분히 잘 하고 계세요.',
    '무슨 일이 있었는지 처음부터 이야기해 주시겠어요?',
  ];

  static List<ChatMessage> _generate() {
    final now = DateTime.now();
    return List.generate(50, (i) {
      final isUser = i % 3 != 0;
      return ChatMessage(
        id: 'msg-$i',
        roomId: 'demo-room',
        senderId: isUser ? _userId : _counselorId,
        content: _contents[i % _contents.length],
        sentAt: now.subtract(Duration(minutes: (50 - i) * 3)),
        isRead: true,
      );
    });
  }

  static final _messages = _generate();

  Future<List<ChatMessage>> fetchMessages(
    String roomId, {
    int page = 0,
    int size = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final start = page * size;
    if (start >= _messages.length) return [];
    final end = (start + size).clamp(0, _messages.length);
    return _messages.sublist(start, end);
  }

  Future<void> sendMessage(String roomId, String content) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  // 실제 Firestore 대신 10초마다 상담사 메시지 도착을 시뮬레이션하기 위한 목 데이터
  static const _mockRealtimeContents = [
    '그렇군요, 조금 더 이야기해 주실 수 있을까요?',
    '많이 힘드셨겠어요.',
    '충분히 이해가 돼요. 계속 말씀해 주세요.',
  ];

  /// 실시간 메시지 수신 스트림 구독 (Firestore 시뮬레이션)
  Stream<ChatMessage> subscribeMessages(String roomId) {
    return Stream.periodic(
      const Duration(seconds: 10),
      (i) => ChatMessage(
        id: 'realtime-$i',
        roomId: roomId,
        senderId: _counselorId,
        content: _mockRealtimeContents[i % _mockRealtimeContents.length],
        sentAt: DateTime.now(),
        isRead: false,
      ),
    );
  }
}
