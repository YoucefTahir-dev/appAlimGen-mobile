import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Frontière locale entre deux sessions authentifiées.
///
/// Chaque requête reçoit le numéro de génération courant et le jeton
/// d'annulation associé. Une rotation invalide immédiatement les réponses de
/// l'ancienne session et annule les requêtes qui sont encore en vol.
class SessionBoundary {
  int _generation = 0;
  CancelToken _cancelToken = CancelToken();

  int get generation => _generation;
  CancelToken get cancelToken => _cancelToken;

  bool isCurrent(int generation) => generation == _generation;

  int rotate() {
    final previous = _cancelToken;
    _generation++;
    _cancelToken = CancelToken();
    if (!previous.isCancelled) {
      previous.cancel('Session remplacée');
    }
    return _generation;
  }
}

final sessionBoundaryProvider = Provider<SessionBoundary>(
  (ref) => SessionBoundary(),
);

class SessionEpochController extends Notifier<int> {
  @override
  int build() => ref.watch(sessionBoundaryProvider).generation;

  void rotate() {
    state = ref.read(sessionBoundaryProvider).rotate();
  }
}

/// Dépendance commune à tous les caches contenant des données métier privées.
final sessionEpochProvider = NotifierProvider<SessionEpochController, int>(
  SessionEpochController.new,
);
