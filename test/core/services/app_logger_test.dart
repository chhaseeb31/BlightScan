import 'package:flutter_test/flutter_test.dart';
import 'package:blightscan/core/services/app_logger.dart';

void main() {
  group('AppLogger Tests', () {
    late AppLogger logger;

    setUp(() {
      logger = AppLogger();
      logger.clearLogs();
    });

    test('debug log adds entry', () {
      logger.debug('Test debug message', tag: 'TEST');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.message, equals('Test debug message'));
      expect(logs.first.level, equals(LogLevel.debug));
      expect(logs.first.tag, equals('TEST'));
    });

    test('info log adds entry', () {
      logger.info('Test info message', tag: 'TEST');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.info));
    });

    test('warning log adds entry with error', () {
      logger.warning('Test warning', tag: 'TEST', error: 'Some error');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.warning));
      expect(logs.first.error, equals('Some error'));
    });

    test('error log adds entry with stack trace', () {
      try {
        throw Exception('Test error');
      } catch (e, stack) {
        logger.error('Test error', tag: 'TEST', error: e, stackTrace: stack);
      }
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.error));
    });

    test('critical log adds entry', () {
      logger.critical('Critical error', tag: 'TEST');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.level, equals(LogLevel.critical));
    });

    test('logNavigation formats correctly', () {
      logger.logNavigation('/login', '/home');
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.extra?['from'], equals('/login'));
      expect(logs.first.extra?['to'], equals('/home'));
    });

    test('logScreenView formats correctly', () {
      logger.logScreenView('/home', params: {'userId': '123'});
      final logs = logger.getLogs();
      expect(logs.length, equals(1));
      expect(logs.first.extra?['userId'], equals('123'));
    });

    test('clearLogs removes all entries', () {
      logger.debug('Message 1');
      logger.info('Message 2');
      logger.clearLogs();
      final logs = logger.getLogs();
      expect(logs.isEmpty, isTrue);
    });

    test('getLogs with limit returns correct count', () {
      for (int i = 0; i < 10; i++) {
        logger.debug('Message $i');
      }
      final logs = logger.getLogs(limit: 5);
      expect(logs.length, equals(5));
    });

    test('getLogs with minLevel filters correctly', () {
      logger.debug('Debug');
      logger.info('Info');
      logger.error('Error');
      final errorsOnly = logger.getLogs(minLevel: LogLevel.error);
      expect(errorsOnly.length, equals(1));
      expect(errorsOnly.first.level, equals(LogLevel.error));
    });

    test('listener receives log events', () {
      bool listenerCalled = false;
      logger.addListener((entry) {
        listenerCalled = true;
      });
      logger.info('Test message');
      expect(listenerCalled, isTrue);
    });

    test('removeListener stops events', () {
      bool listenerCalled = false;
      void listener(AppLogEntry entry) {
        listenerCalled = true;
      }

      logger.addListener(listener);
      logger.removeListener(listener);
      logger.info('Test message');
      expect(listenerCalled, isFalse);
    });
  });
}
