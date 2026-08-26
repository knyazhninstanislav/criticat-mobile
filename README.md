# 🐱 CritiCat Mobile Client

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![MQTT](https://img.shields.io/badge/MQTT-5.0-660066?style=flat&logo=mqtt&logoColor=white)](https://mqtt.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Мобильный клиент для системы критических оповещений о лабораторных исследованиях**

---

## 📱 О приложении

**CritiCat Mobile** — это Flutter-приложение для получения и управления критическими результатами лабораторных исследований в реальном времени через MQTT. Приложение получает уведомления о критических отклонениях, позволяет просматривать детали, подтверждать или отклонять результаты.

### ✨ Основные возможности

| Возможность | Описание |
|-------------|----------|
| 🔔 **Push-уведомления** | Мгновенные уведомления о критических результатах |
| 📊 **Мониторинг** | Отображение активных и обработанных результатов |
| 🔄 **Синхронизация** | Обмен данными с десктопным клиентом через MQTT |
| ✅ **Управление** | Подтверждение и отклонение результатов одним нажатием |
| 🎨 **Современный UI** | Темная тема с анимациями и интуитивным интерфейсом |
| 📱 **Кроссплатформенность** | Поддержка Android и iOS |



---

## 🚀 Установка и запуск

### 📋 Требования

- Flutter SDK >= 3.0.0
- Android Studio / VS Code
- Android SDK (для Android) или Xcode (для iOS)
- MQTT брокер (например, Mosquitto)

### 📦 Установка

```bash
# 1. Клонировать репозиторий
git clone https://github.com/yourusername/criticat-mobile.git
cd criticat-mobile

# 2. Установить зависимости
flutter pub get

# 3. Запустить приложение
flutter run
```

## 🙏 Благодарности
- MQTT Client - за отличную реализацию MQTT
- Flutter Team - за потрясающий фреймворк

<div align="center"> <sub>Built with ❤️ using Flutter</sub> </div>
