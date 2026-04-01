import 'package:injectable/injectable.dart';

abstract class LocalClaimGuard {
  Future<bool> reserve(String idempotencyKey);

  Future<void> commit(String idempotencyKey);

  Future<void> release(String idempotencyKey);
}

@LazySingleton(as: LocalClaimGuard)
class InMemoryLocalClaimGuard implements LocalClaimGuard {
  final Set<String> _inFlight = <String>{};
  final Set<String> _committed = <String>{};

  @override
  Future<bool> reserve(String idempotencyKey) async {
    if (_inFlight.contains(idempotencyKey) || _committed.contains(idempotencyKey)) {
      return false;
    }

    _inFlight.add(idempotencyKey);
    return true;
  }

  @override
  Future<void> commit(String idempotencyKey) async {
    _inFlight.remove(idempotencyKey);
    _committed.add(idempotencyKey);
  }

  @override
  Future<void> release(String idempotencyKey) async {
    _inFlight.remove(idempotencyKey);
  }
}
