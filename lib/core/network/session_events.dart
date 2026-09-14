import 'dart:async';

import 'package:app_alim_gen_mobile/core/errors/app_failure.dart';

class SessionEvents {
  final _controller = StreamController<AppFailure>.broadcast();
  Stream<AppFailure> get expired => _controller.stream;
  void notifyExpired() => _controller.add(
    const AppFailure(
      kind: FailureKind.authentication,
      code: 'SESSION_EXPIRED',
      message: 'Votre session a expiré. Veuillez vous reconnecter.',
      statusCode: 401,
    ),
  );
  void dispose() => _controller.close();
}
