import 'dart:async';

class SessionEvents {
  final _controller = StreamController<void>.broadcast();
  Stream<void> get expired => _controller.stream;
  void notifyExpired() => _controller.add(null);
  void dispose() => _controller.close();
}
