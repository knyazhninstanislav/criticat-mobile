class AppConfig {
  static const String appName = 'CritiCat';
  static const String appVersion = '1.0.0';
  
  // MQTT Configuration
  static const String mqttHost = '176.98.181.45';
  static const int mqttPort = 18830;
  static const String mqttUsername = 'mobile_app';
  static const String mqttPassword = 'your-password';
  
  // Топики - ИСПРАВЛЕНЫ для правильной подписки
  static const String resultsTopic = 'criticat/results';  // Для публикации
  static const String resultsSubscribe = 'criticat/results';  // Для подписки
  static const String resultSpecificTopic = 'criticat/results/'; // для конкретного ID
  
  // Топики для подтверждений - ИСПРАВЛЕНЫ
  static const String confirmationsTopic = 'criticat/confirmations';
  static const String acceptTopicPrefix = 'criticat/confirmations/accept/';
  static const String rejectTopicPrefix = 'criticat/confirmations/reject/';
  
  // Системные топики
  static const String systemTopic = 'criticat/system';
  static const String statusTopic = 'criticat/status';
  static const String mobileStatusTopic = 'criticat/mobile/status';
  static const String requestDataTopic = 'criticat/request/data';  // Запрос данных
  
  // Хранилище
  static const String keyUsername = 'username';
  static const String keyPassword = 'password';
  static const String keyMqttHost = 'mqtt_host';
  static const String keyMqttPort = 'mqtt_port';
  static const String keyDeviceId = 'device_id';
  static const String keyRememberMe = 'remember_me';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyVibrationEnabled = 'vibration_enabled';
}