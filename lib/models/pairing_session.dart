class PairingSession {
  const PairingSession({
    required this.sessionId,
    required this.qrPayload,
    this.completed = false,
  });

  final String sessionId;
  final String qrPayload;
  final bool completed;

  PairingSession copyWith({
    String? sessionId,
    String? qrPayload,
    bool? completed,
  }) {
    return PairingSession(
      sessionId: sessionId ?? this.sessionId,
      qrPayload: qrPayload ?? this.qrPayload,
      completed: completed ?? this.completed,
    );
  }
}
