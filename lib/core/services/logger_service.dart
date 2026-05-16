import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Professional Observability Service.
/// Replaces standard debugPrint with a structured, level-based logging system.
class LoggerService {
  static final Logger _logger = Logger('AmalTracker');

  static void init() {
    // 1. Configure Global Logging Level
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

    // 2. Setup Listener (Console in Dev, Crashlytics/Sentry in Prod)
    Logger.root.onRecord.listen((record) {
      final message = '${record.time}: [${record.level.name}] ${record.loggerName}: ${record.message}';
      
      if (kDebugMode) {
        debugPrint(message);
      } else {
        // In a real SaaS, we would send 'SEVERE' or 'SHOUT' logs to Sentry here.
        // if (record.level >= Level.SEVERE) { Sentry.captureException(record.error); }
      }
    });
  }

  static void info(String message) => _logger.info(message);
  static void warning(String message) => _logger.warning(message);
  static void error(String message, [Object? error, StackTrace? stack]) => 
      _logger.severe(message, error, stack);
}
