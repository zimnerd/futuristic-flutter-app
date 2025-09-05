// storage_service_stub.dart
// Export the appropriate implementation based on platform
export 'hive_storage_service.dart'
    if (dart.library.html) 'hive_storage_service_web.dart';
