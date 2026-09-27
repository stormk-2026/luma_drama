abstract interface class PlayerPort {
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}
