import 'package:uuid/uuid.dart';

abstract interface class IdempotencyKeyGenerator {
  String create();
}

class UuidIdempotencyKeyGenerator implements IdempotencyKeyGenerator {
  const UuidIdempotencyKeyGenerator();
  @override
  String create() => const Uuid().v4();
}
