import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../services/storage_service.dart';
import '../services/mqtt_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isLoading = true;
  String _status = 'Загрузка...';
  int _progress = 0;
  int _currentStep = 0;
  bool _isPulsing = false;

  final List<String> _loadingSteps = [
    'Подключение к базе данных...',
    'Загрузка настроек...',
    'Инициализация MQTT...',
    'Проверка обновлений...',
    'Запуск системы...'
  ];

  Timer? _pulseTimer;
  Timer? _loadingTimer;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();

    _pulseTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() => _isPulsing = !_isPulsing);
    });

    _loadingTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (_currentStep < _loadingSteps.length) {
        setState(() {
          _progress = ((_currentStep + 1) / _loadingSteps.length * 100).toInt();
          _status = _loadingSteps[_currentStep];
          _currentStep++;
        });
      }
    });

    _initializeApp();

    _closeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _fadeController.reverse().then((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      final username = await StorageService.getString(AppConfig.keyUsername);
      final mqttHost = await StorageService.getString(AppConfig.keyMqttHost);
      final mqttPort = await StorageService.getString(AppConfig.keyMqttPort);

      await Future.delayed(const Duration(milliseconds: 500));

      if (username != null && username.isNotEmpty && mqttHost != null) {
        setState(() => _status = 'Подключение к серверу...');

        final mqttService = Provider.of<MQTTService>(context, listen: false);

        final connected = await mqttService.connect(
          host: mqttHost,
          port: int.tryParse(mqttPort ?? '') ?? AppConfig.mqttPort,
          username: username,
          password: await StorageService.getString(AppConfig.keyPassword) ?? '',
        );

        if (connected) {
          setState(() => _status = 'Подключено, запрос данных...');

          await Future.delayed(const Duration(milliseconds: 500));
          mqttService.requestData();

          await Future.delayed(const Duration(seconds: 1));

          setState(() => _status = 'Готово!');

          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _closeTimer?.cancel();
            _fadeController.reverse().then((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(mqttService: mqttService),
                  ),
                );
              }
            });
          }
        } else {
          setState(() => _status = 'Ошибка подключения');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            _closeTimer?.cancel();
            _fadeController.reverse().then((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            });
          }
        }
      } else {
        setState(() => _status = 'Первый запуск');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          _closeTimer?.cancel();
          _fadeController.reverse().then((_) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          });
        }
      }
    } catch (e) {
      print('Ошибка инициализации: $e');
      setState(() => _status = 'Ошибка: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _closeTimer?.cancel();
        _fadeController.reverse().then((_) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseTimer?.cancel();
    _loadingTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1e2e),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1e2e),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Фон с градиентом
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, -0.3),
                            radius: 0.8,
                            colors: [
                              const Color(0xFF1a1e2e),
                              const Color(0xFF1a1e2e),
                              const Color(0xFF1a1e2e),
                            ],
                            stops: const [0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Свечение
                    Positioned(
                      left: 100,
                      top: 80,
                      right: 100,
                      bottom: 180,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.5, 0.3),
                            radius: 0.6,
                            colors: [
                              const Color(0xFFFF2D55).withOpacity(0.12),
                              const Color(0xFFFF2D55).withOpacity(0.05),
                              Colors.transparent,
                            ],
                            stops: const [0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Контент
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Логотип с кошечкой
                        _buildCatLogo(),

                        const SizedBox(height: 30),

                        // Заголовок
                        const Text(
                          'CRITICAT',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF2D55),
                            letterSpacing: 5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Подзаголовок
                        Text(
                          'CRITICAL ALERT SYSTEM',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            letterSpacing: 6,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Прогресс-бар
                        _buildProgressBar(),

                        const SizedBox(height: 12),

                        // Статус
                        Text(
                          _status,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Версия
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 20, bottom: 10),
                            child: Text(
                              'v1.0.0',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatLogo() {
    final pulseSize = _isPulsing ? 1.0 : 0.95;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 160 * pulseSize,
      height: 160 * pulseSize,
      child: CustomPaint(
        painter: CritiCatLogoPainter(isPulsing: _isPulsing),
        size: const Size(160, 160),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Container(
          width: 300,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Container(
                width: 300 * (_progress / 100),
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2D55),
                      Color(0xFF00FF94),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$_progress%',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// РИСОВАЛЬЩИК ЛОГОТИПА С КОШЕЧКОЙ (точная копия из Python)
// ============================================================

class CritiCatLogoPainter extends CustomPainter {
  final bool isPulsing;

  CritiCatLogoPainter({this.isPulsing = false});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 200.0;

    // Смещение для центрирования
    final offsetX = centerX - 100 * scale;
    final offsetY = centerY - 100 * scale;

    // Вспомогательные функции
    double sx(double x) => offsetX + x * scale;
    double sy(double y) => offsetY + y * scale;
    Offset sp(double x, double y) => Offset(sx(x), sy(y));

    // Цвета
    final redColor = const Color(0xFFFF2D55);
    final lightRed = const Color(0xFFFF6B8A);
    final greenColor = const Color(0xFF00FF94);

    // Создаем кисти
    final Paint redPaint = Paint()
      ..color = redColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint redFillPaint = Paint()
      ..color = redColor
      ..style = PaintingStyle.fill;

    final Paint greenPaint = Paint()
      ..color = greenColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint greenGlowPaint = Paint()
      ..color = greenColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..strokeCap = StrokeCap.round;

    // ========== УШИ ==========
    // Левое ухо
    final leftEarPath = Path()
      ..moveTo(sx(30), sy(40))
      ..lineTo(sx(70), sy(10))
      ..lineTo(sx(90), sy(55))
      ..close();
    canvas.drawPath(leftEarPath, redPaint);

    // Правое ухо
    final rightEarPath = Path()
      ..moveTo(sx(170), sy(40))
      ..lineTo(sx(130), sy(10))
      ..lineTo(sx(110), sy(55))
      ..close();
    canvas.drawPath(rightEarPath, redPaint);

    // ========== ГОЛОВА ==========
    final headRect = Rect.fromLTWH(
      sx(25), sy(25),
      150 * scale, 140 * scale,
    );
    final headRRect = RRect.fromRectAndRadius(
      headRect,
      Radius.circular(30 * scale),
    );
    canvas.drawRRect(headRRect, redPaint);

    // ========== ГЛАЗА ==========
    // Левый глаз
    canvas.drawOval(
      Rect.fromCenter(
        center: sp(65, 80),
        width: 28 * scale,
        height: 28 * scale,
      ),
      redPaint,
    );

    // Зрачок левого глаза
    canvas.drawOval(
      Rect.fromCenter(
        center: sp(68, 77),
        width: 8 * scale,
        height: 8 * scale,
      ),
      redFillPaint,
    );

    // Правый глаз
    canvas.drawOval(
      Rect.fromCenter(
        center: sp(135, 80),
        width: 28 * scale,
        height: 28 * scale,
      ),
      redPaint,
    );

    // Зрачок правого глаза
    canvas.drawOval(
      Rect.fromCenter(
        center: sp(138, 77),
        width: 8 * scale,
        height: 8 * scale,
      ),
      redFillPaint,
    );

    // ========== НОС ==========
    final nosePath = Path()
      ..moveTo(sx(100), sy(95))
      ..lineTo(sx(94), sy(108))
      ..lineTo(sx(106), sy(108))
      ..close();
    canvas.drawPath(nosePath, redFillPaint);

    // ========== УСЫ ==========
    // Левые усы
    canvas.drawLine(sp(30, 105), sp(75, 110), whitePaint);
    canvas.drawLine(sp(30, 120), sp(78, 118), whitePaint);

    // Правые усы
    canvas.drawLine(sp(170, 105), sp(125, 110), whitePaint);
    canvas.drawLine(sp(170, 120), sp(122, 118), whitePaint);

    // ========== ECG ЛИНИЯ ==========
    final ecgPoints = [
      Offset(sx(25), sy(60)),
      Offset(sx(50), sy(60)),
      Offset(sx(58), sy(40)),
      Offset(sx(66), sy(80)),
      Offset(sx(74), sy(30)),
      Offset(sx(82), sy(70)),
      Offset(sx(90), sy(55)),
      Offset(sx(98), sy(90)),
      Offset(sx(106), sy(45)),
      Offset(sx(114), sy(85)),
      Offset(sx(122), sy(50)),
      Offset(sx(130), sy(70)),
      Offset(sx(138), sy(45)),
      Offset(sx(146), sy(75)),
      Offset(sx(154), sy(55)),
      Offset(sx(175), sy(60)),
    ];

    // Свечение ECG
    final ecgPath = Path()
      ..moveTo(ecgPoints[0].dx, ecgPoints[0].dy);
    for (int i = 1; i < ecgPoints.length; i++) {
      ecgPath.lineTo(ecgPoints[i].dx, ecgPoints[i].dy);
    }
    canvas.drawPath(ecgPath, greenGlowPaint);

    // Основная ECG линия
    canvas.drawPath(ecgPath, greenPaint);

    // ========== УГЛЫ СКАНИРОВАНИЯ ==========
    final cornerColor = const Color(0x80FF6B8A);
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale;

    // Верхний левый
    canvas.drawRect(
      Rect.fromLTWH(sx(10), sy(10), 12 * scale, 12 * scale),
      cornerPaint,
    );
    // Верхний правый
    canvas.drawRect(
      Rect.fromLTWH(sx(178), sy(10), 12 * scale, 12 * scale),
      cornerPaint,
    );
    // Нижний левый
    canvas.drawRect(
      Rect.fromLTWH(sx(10), sy(178), 12 * scale, 12 * scale),
      cornerPaint,
    );
    // Нижний правый
    canvas.drawRect(
      Rect.fromLTWH(sx(178), sy(178), 12 * scale, 12 * scale),
      cornerPaint,
    );

    // ========== ПУЛЬСИРУЮЩЕЕ СВЕЧЕНИЕ ==========
    if (isPulsing) {
      final pulsePaint = Paint()
        ..color = const Color(0xFFFF2D55).withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * scale;

      final pulseSize = 120 + 10 * (0.5 + 0.5 * math.sin(DateTime.now().millisecondsSinceEpoch / 500));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, centerY - 10),
          width: pulseSize * scale,
          height: pulseSize * scale,
        ),
        pulsePaint,
      );
    }
  }

  @override
  bool shouldRepaint(CritiCatLogoPainter oldDelegate) {
    return oldDelegate.isPulsing != isPulsing;
  }
}