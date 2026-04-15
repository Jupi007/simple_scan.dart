import 'structures.dart';

abstract base class SimpleScanPlatform {
  static SimpleScanPlatform? _instance;

  static SimpleScanPlatform get instance {
    if (_instance == null) {
      throw StateError('No scanner platform implementation has been set.');
    }
    return _instance!;
  }

  static set instance(SimpleScanPlatform platform) {
    _instance = platform;
  }

  Future<void> init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  Future<List<ScanDevice>> listDevices() {
    throw UnimplementedError('listDevices() has not been implemented.');
  }

  Future<ScanSession> openSession(String deviceId) {
    throw UnimplementedError('openSession() has not been implemented.');
  }
}

abstract base class ScanSession {
  Stream<ScanSnapshot> scan(ScanOptions options) {
    throw UnimplementedError('scan() has not been implemented.');
  }

  Future<void> cancel() {
    throw UnimplementedError('cancel() has not been implemented.');
  }

  Future<void> close() {
    throw UnimplementedError('close() has not been implemented.');
  }
}
