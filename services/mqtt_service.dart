import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../config/app_config.dart';
import '../models/critical_result.dart';
import 'notification_service.dart';

class MQTTService extends ChangeNotifier {
  MqttServerClient? _client;
  final StreamController<List<CriticalResult>> _resultsController =
      StreamController.broadcast();
  final StreamController<bool> _connectionController =
      StreamController.broadcast();
  final NotificationService _notificationService = NotificationService();

  bool _isConnected = false;
  bool _isConnecting = false;
  final List<CriticalResult> _results = [];
  final Set<int> _sentNotificationIds = {}; // Для отслеживания уведомлений
  String _lastError = '';

  // Геттеры
  Stream<List<CriticalResult>> get resultsStream => _resultsController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get lastError => _lastError;
  List<CriticalResult> get results => List.unmodifiable(_results);
  int get activeCount => _results.where((r) => !r.isIgnored).length;
  int get ignoredCount => _results.where((r) => r.isIgnored).length;

  Future<bool> connect({
    String? host,
    int? port,
    String? username,
    String? password,
  }) async {
    if (_isConnecting) {
      print('MQTT: Уже подключаемся...');
      return false;
    }

    _isConnecting = true;
    _lastError = '';
    notifyListeners();

    final mqttHost = host ?? AppConfig.mqttHost;
    final mqttPort = port ?? AppConfig.mqttPort;
    final mqttUsername = username ?? AppConfig.mqttUsername;
    final mqttPassword = password ?? AppConfig.mqttPassword;

    await _notificationService.init();
    await disconnect();

    // Создаем клиент с уникальным ID
    final clientId = 'mobile_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient(mqttHost, clientId);
    _client!.port = mqttPort;
    _client!.logging(on: false);
    _client!.keepAlivePeriod = 60;
    _client!.autoReconnect = true;
    _client!.setProtocolV311();

    // Колбэки
    _client!.onConnected = _onConnected;
    _client!.onDisconnected = _onDisconnected;
    _client!.onSubscribed = _onSubscribed;
    _client!.onSubscribeFail = _onSubscribeFail;
    _client!.onConnectionFailed = _onConnectionFailed;

    // Настройка сообщения подключения
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .withWillTopic(AppConfig.mobileStatusTopic)
        .withWillMessage('offline')
        .withWillQos(MqttQos.atLeastOnce)
        .startClean();

    if (mqttUsername.isNotEmpty) {
      connMessage.authenticateAs(mqttUsername, mqttPassword);
    }

    _client!.connectionMessage = connMessage;

    try {
      print('MQTT: Подключение к $mqttHost:$mqttPort...');
      await _client!.connect();

      // Ждем подключения
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (_isConnected) {
          _isConnecting = false;
          notifyListeners();
          return true;
        }
      }

      _isConnecting = false;
      _lastError = 'Таймаут подключения';
      notifyListeners();
      return false;
    } catch (e) {
      print('MQTT Connection error: $e');
      _isConnected = false;
      _isConnecting = false;
      _lastError = e.toString();
      _client = null;
      notifyListeners();
      if (!_connectionController.isClosed) {
        _connectionController.add(false);
      }
      return false;
    }
  }

  void _onConnected() {
    _isConnected = true;
    _isConnecting = false;
    print('MQTT: Подключен к брокеру');

    // Подписываемся на топики
    _subscribeToTopics();

    // Публикуем статус
    _publishMessage(AppConfig.mobileStatusTopic, jsonEncode({
      'status': 'online',
      'device_id': _client!.clientIdentifier,
      'timestamp': DateTime.now().toIso8601String(),
    }));

    // Уведомляем
    if (!_connectionController.isClosed) {
      _connectionController.add(true);
    }
    notifyListeners();

    // Показываем уведомление о подключении
    _notificationService.showConnectionNotification(connected: true);
  }

  void _subscribeToTopics() {
    if (_client == null || !_isConnected) return;

    final topics = [
      AppConfig.resultsSubscribe,
      'criticat/results/+',
      'criticat/confirmations/+',
      'criticat/system/+',
      AppConfig.statusTopic,
    ];

    for (final topic in topics) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
      print('MQTT: Подписка на $topic');
    }

    // Настройка обработчика сообщений
    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      for (final event in events) {
        final topic = event.topic;
        final message = event.payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);
        _handleMessage(topic, payload);
      }
    });
  }

  void _onDisconnected() {
    _isConnected = false;
    print('MQTT: Отключен от брокера');

    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
    notifyListeners();

    _notificationService.showConnectionNotification(connected: false);
  }

  void _onConnectionFailed(String reason) {
    _isConnected = false;
    _isConnecting = false;
    _lastError = reason;
    print('MQTT: Ошибка подключения: $reason');
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    print('MQTT: Подписан на $topic');
  }

  void _onSubscribeFail(String topic) {
    print('MQTT: Ошибка подписки на $topic');
  }

  void _handleMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      print('MQTT: Получено сообщение из $topic');

      if (topic == AppConfig.resultsSubscribe ||
          topic.startsWith('criticat/results')) {
        _handleResult(data);
      } else if (topic.startsWith('criticat/confirmations/')) {
        _handleConfirmation(topic, data);
      } else if (topic.startsWith('criticat/system/')) {
        print('MQTT: Системное сообщение: $data');
      } else if (topic == AppConfig.statusTopic) {
        print('MQTT: Статус: ${data['status']} - ${data['message']}');
      }
    } catch (e) {
      print('MQTT: Ошибка обработки сообщения: $e');
      print('MQTT: Топик: $topic, Пейлоад: $payload');
    }
  }

  void _handleResult(Map<String, dynamic> data) {
    try {
      List<CriticalResult> newResults = [];

      if (data.containsKey('results') && data['results'] is List) {
        newResults =
            (data['results'] as List).map((r) => CriticalResult.fromJson(r)).toList();
      } else if (data.containsKey('id') || data.containsKey('result_id')) {
        newResults = [CriticalResult.fromJson(data)];
      } 

      if (newResults.isEmpty) {
        print('MQTT: Нет результатов для обработки');
        return;
      }

      print('MQTT: Получено ${newResults.length} результатов');

      for (final result in newResults) {
        _addOrUpdateResult(result);
      }

      if (!_resultsController.isClosed) {
        _resultsController.add(List.from(_results));
      }
      notifyListeners();
    } catch (e) {
      print('MQTT: Ошибка обработки результата: $e');
      print('MQTT: Данные: $data');
    }
  }

  void _addOrUpdateResult(CriticalResult result) {
    final index = _results.indexWhere((r) => r.resultId == result.resultId);

    if (index >= 0) {
      _results[index] = result;
      print('MQTT: Обновлен результат #${result.resultId}');
    } else {
      _results.insert(0, result);
      print('MQTT: Добавлен результат #${result.resultId}');
      
      // ✅ ПОКАЗЫВАЕМ УВЕДОМЛЕНИЕ ТОЛЬКО ДЛЯ НОВЫХ РЕЗУЛЬТАТОВ
      _showResultNotification(result);
    }
  }

  void _showResultNotification(CriticalResult result) {
    // Проверяем, не отправляли ли уже уведомление
    if (_sentNotificationIds.contains(result.resultId)) {
      print('⚠️ Уведомление для #${result.resultId} уже отправлено');
      return;
    }

    // Добавляем в список отправленных
    _sentNotificationIds.add(result.resultId);

    // Показываем уведомление
    _notificationService.showCriticalResultNotification(
      resultId: result.resultId,
      testName: result.testName,
      value: result.resultValue,
      department: result.department,
      patientName: result.fullName,
    );

    print('🔔 Показано уведомление для #${result.resultId}');
  }

  void _handleConfirmation(String topic, Map<String, dynamic> data) {
    final action = topic.split('/').last;
    final resultId = data['result_id'] ?? data['id'];

    print('MQTT: Подтверждение $action для #$resultId');

    final index = _results.indexWhere((r) => r.resultId == resultId);
    if (index >= 0) {
      if (action == 'accept' || action == 'accepted') {
        _results[index].markAsIgnored();
        _results[index].status = 'confirmed';
        _results[index].confirmedBy = data['user'] ?? 'system';

        _notificationService.showConfirmationNotification(
          resultId: resultId,
          accepted: true,
        );
      } else if (action == 'reject' || action == 'rejected') {
        _results.removeAt(index);

        _notificationService.showConfirmationNotification(
          resultId: resultId,
          accepted: false,
        );
      }

      if (!_resultsController.isClosed) {
        _resultsController.add(List.from(_results));
      }
      notifyListeners();
    }
  }

  // ===== ПУБЛИЧНЫЕ МЕТОДЫ =====

  void requestData() {
    if (!_isConnected) {
      _lastError = 'Нет подключения к серверу';
      notifyListeners();
      return;
    }

    final message = jsonEncode({
      'action': 'get_results',
      'client_id': _client?.clientIdentifier ?? 'mobile',
      'timestamp': DateTime.now().toIso8601String(),
    });

    _publishMessage(AppConfig.requestDataTopic, message);
    print('MQTT: Запрос данных отправлен');
  }

  void acceptResult(int resultId) {
    if (!_isConnected) {
      _lastError = 'Нет подключения к серверу';
      notifyListeners();
      return;
    }

    final topic = '${AppConfig.acceptTopicPrefix}$resultId';
    final message = jsonEncode({
      'result_id': resultId,
      'action': 'accept',
      'user': _client?.clientIdentifier ?? 'mobile',
      'timestamp': DateTime.now().toIso8601String(),
    });

    _publishMessage(topic, message);
    print('MQTT: Принят результат #$resultId');

    final index = _results.indexWhere((r) => r.resultId == resultId);
    if (index >= 0) {
      _results[index].markAsIgnored();
      _results[index].status = 'confirmed';
      _results[index].confirmedBy = 'mobile';

      if (!_resultsController.isClosed) {
        _resultsController.add(List.from(_results));
      }
      notifyListeners();

      _notificationService.showConfirmationNotification(
        resultId: resultId,
        accepted: true,
      );
    }
  }

  void rejectResult(int resultId) {
    if (!_isConnected) {
      _lastError = 'Нет подключения к серверу';
      notifyListeners();
      return;
    }

    final topic = '${AppConfig.rejectTopicPrefix}$resultId';
    final message = jsonEncode({
      'result_id': resultId,
      'action': 'reject',
      'user': _client?.clientIdentifier ?? 'mobile',
      'timestamp': DateTime.now().toIso8601String(),
    });

    _publishMessage(topic, message);
    print('MQTT: Отклонен результат #$resultId');

    _results.removeWhere((r) => r.resultId == resultId);
    if (!_resultsController.isClosed) {
      _resultsController.add(List.from(_results));
    }
    notifyListeners();

    _notificationService.showConfirmationNotification(
      resultId: resultId,
      accepted: false,
    );
  }

  void _publishMessage(String topic, String message) {
    if (_client != null && _isConnected) {
      try {
        final builder = MqttClientPayloadBuilder();
        builder.addString(message);
        _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
        print('MQTT: Опубликовано в $topic');
      } catch (e) {
        print('MQTT: Ошибка публикации: $e');
      }
    } else {
      print('MQTT: Не удалось опубликовать - нет подключения');
    }
  }

  Future<void> disconnect() async {
    if (_client != null) {
      try {
        if (_isConnected) {
          _publishMessage(AppConfig.mobileStatusTopic, jsonEncode({
            'status': 'offline',
            'device_id': _client!.clientIdentifier,
            'timestamp': DateTime.now().toIso8601String(),
          }));
        }
        _client!.disconnect();
      } catch (e) {
        print('MQTT: Ошибка отключения: $e');
      }
      _client = null;
    }

    _isConnected = false;
    _isConnecting = false;
    if (!_connectionController.isClosed) {
      _connectionController.add(false);
    }
    notifyListeners();
  }

  void clearResults() {
    _results.clear();
    _sentNotificationIds.clear();
    if (!_resultsController.isClosed) {
      _resultsController.add(List.from(_results));
    }
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _resultsController.close();
    _connectionController.close();
    super.dispose();
  }
}

extension on MqttServerClient {
  set onConnectionFailed(void Function(String reason) value) {}
}