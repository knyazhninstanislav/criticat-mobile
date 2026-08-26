import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';
import '../services/mqtt_service.dart';

class SettingsScreen extends StatefulWidget {
  final MQTTService mqttService;
  
  const SettingsScreen({
    super.key,
    required this.mqttService,
  });
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    widget.mqttService.addListener(_onServiceChanged);
  }
  
  void _onServiceChanged() {
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    widget.mqttService.removeListener(_onServiceChanged);
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    final host = await StorageService.getString(AppConfig.keyMqttHost);
    final port = await StorageService.getString(AppConfig.keyMqttPort);
    final username = await StorageService.getString(AppConfig.keyUsername);
    final notifications = await StorageService.getBool('notifications_enabled');
    final sound = await StorageService.getBool('sound_enabled');
    final vibration = await StorageService.getBool('vibration_enabled');
    
    setState(() {
      _hostController.text = host ?? AppConfig.mqttHost;
      _portController.text = port ?? AppConfig.mqttPort.toString();
      _usernameController.text = username ?? '';
      _notificationsEnabled = notifications ?? true;
      _soundEnabled = sound ?? true;
      _vibrationEnabled = vibration ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    // Сохраняем настройки
    await StorageService.saveString(AppConfig.keyMqttHost, _hostController.text);
    await StorageService.saveString(AppConfig.keyMqttPort, _portController.text);
    await StorageService.saveString(AppConfig.keyUsername, _usernameController.text);
    await StorageService.saveBool('notifications_enabled', _notificationsEnabled);
    await StorageService.saveBool('sound_enabled', _soundEnabled);
    await StorageService.saveBool('vibration_enabled', _vibrationEnabled);
    
    // Подключаемся
    final connected = await widget.mqttService.connect(
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? AppConfig.mqttPort,
      username: _usernameController.text,
      password: _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected 
                ? '✅ Подключено к ${_hostController.text}:${_portController.text}'
                : '❌ Ошибка подключения: ${widget.mqttService.lastError}',
          ),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    
    final connected = await widget.mqttService.connect(
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? AppConfig.mqttPort,
      username: _usernameController.text,
      password: _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected 
                ? '✅ Подключено к ${_hostController.text}:${_portController.text}'
                : '❌ Ошибка: ${widget.mqttService.lastError}',
          ),
          backgroundColor: connected ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  Future<void> _requestTestData() async {
    if (!widget.mqttService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала подключитесь к серверу'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    widget.mqttService.requestData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Запрос данных отправлен'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1e2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1e2e),
        title: const Text(
          'Настройки',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Статус
            _buildConnectionStatus(),
            const SizedBox(height: 20),
            
            // Настройки
            _buildConnectionSettings(),
            const SizedBox(height: 20),
            
            // Кнопки действий
            _buildActionButtons(),
            const SizedBox(height: 20),
            
            // Уведомления
            _buildNotificationSettings(),
            const SizedBox(height: 20),
            
            // Статистика
            _buildStatistics(),
            const SizedBox(height: 20),
            
            // Информация
            _buildAppInfo(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionStatus() {
    final isConnected = widget.mqttService.isConnected;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: isConnected ? Colors.green : Colors.red,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Подключено' : 'Не подключено',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _hostController.text,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (!isConnected && widget.mqttService.lastError.isNotEmpty)
                  Text(
                    widget.mqttService.lastError,
                    style: const TextStyle(color: Colors.red, fontSize: 11),
                  ),
              ],
            ),
          ),
          if (widget.mqttService.isConnecting)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionSettings() {
    return _buildSection(
      title: '🔗 Подключение к MQTT',
      child: Column(
        children: [
          _buildTextField(
            controller: _hostController,
            label: 'Адрес сервера',
            icon: Icons.dns,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _portController,
            label: 'Порт',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _usernameController,
            label: 'Логин',
            icon: Icons.person,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            label: 'Пароль',
            icon: Icons.lock,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Проверить'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFff2d55),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return _buildSection(
      title: '⚡ Действия',
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: widget.mqttService.isConnected ? _requestTestData : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFff2d55),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                '🔄 Запросить данные',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationSettings() {
    return _buildSection(
      title: '🔔 Уведомления',
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Push-уведомления',
            subtitle: 'Получать уведомления о критических результатах',
            value: _notificationsEnabled,
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              await StorageService.saveBool('notifications_enabled', value);
            },
          ),
          const Divider(color: Colors.grey),
          _buildSwitchTile(
            title: 'Звук',
            subtitle: 'Воспроизводить звук при уведомлении',
            value: _soundEnabled,
            onChanged: (value) async {
              setState(() => _soundEnabled = value);
              await StorageService.saveBool('sound_enabled', value);
            },
          ),
          const Divider(color: Colors.grey),
          _buildSwitchTile(
            title: 'Вибрация',
            subtitle: 'Вибрировать при уведомлении',
            value: _vibrationEnabled,
            onChanged: (value) async {
              setState(() => _vibrationEnabled = value);
              await StorageService.saveBool('vibration_enabled', value);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatistics() {
    final total = widget.mqttService.results.length;
    final active = widget.mqttService.activeCount;
    final ignored = widget.mqttService.ignoredCount;
    
    return _buildSection(
      title: '📊 Статистика',
      child: Row(
        children: [
          _buildStatItem(title: 'Всего', value: total, color: const Color(0xFF42a5f5)),
          _buildStatItem(title: 'Активные', value: active, color: const Color(0xFFff2d55)),
          _buildStatItem(title: 'Обработанные', value: ignored, color: Colors.green),
        ],
      ),
    );
  }
  
  Widget _buildAppInfo() {
    return _buildSection(
      title: 'ℹ️ О приложении',
      child: Column(
        children: [
          _buildInfoRow('Версия', AppConfig.appVersion),
          _buildInfoRow('Название', AppConfig.appName),
          _buildInfoRow('Протокол', 'MQTT'),
          _buildInfoRow('Устройство', widget.mqttService.isConnected ? 'Подключено' : 'Отключено'),
        ],
      ),
    );
  }
  
  // ===== ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ =====
  
  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2e3e),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFff2d55), width: 2),
        ),
      ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFFff2d55),
    );
  }
  
  Widget _buildStatItem({
    required String title,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}