import 'package:flutter/material.dart';

class CriticalResult {
  final int resultId;
  final int ids;
  final String fullName;
  final String department;
  final String testName;
  final double resultValue;
  final double refLower;
  final double refUpper;
  final double deviationPercent;
  final String monitorType;
  final DateTime timestamp;
  bool isIgnored;
  String? ignoredAt;
  String status;
  String? confirmedBy;
  
  CriticalResult({
    required this.resultId,
    required this.ids,
    required this.fullName,
    required this.department,
    required this.testName,
    required this.resultValue,
    required this.refLower,
    required this.refUpper,
    required this.deviationPercent,
    required this.monitorType,
    required this.timestamp,
    this.isIgnored = false,
    this.confirmedBy = '',
    this.status = '',
    this.ignoredAt

  });
  
  factory CriticalResult.fromJson(Map<String, dynamic> json) {
    return CriticalResult(
      resultId: json['result_id'] ?? json['id'] ?? 0,
      ids: json['ids'] ?? 0,
      fullName: json['full_name'] ?? 'Неизвестно',
      department: json['department'] ?? 'Не указано',
      testName: json['test_name'] ?? 'Неизвестный тест',
      resultValue: (json['result_value'] ?? 0).toDouble(),
      refLower: (json['ref_lower'] ?? 0).toDouble(),
      refUpper: (json['ref_upper'] ?? 0).toDouble(),
      deviationPercent: (json['deviation_percent'] ?? 0).toDouble(),
      monitorType: json['monitor_type'] ?? 'both',
      timestamp: DateTime.tryParse(json['timestamp'] ?? json['found_at'] ?? '') ?? DateTime.now(),
      isIgnored: json['is_ignored'] ?? false,
      ignoredAt: json['ignored_at'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'result_id': resultId,
      'ids': ids,
      'full_name': fullName,
      'department': department,
      'test_name': testName,
      'result_value': resultValue,
      'ref_lower': refLower,
      'ref_upper': refUpper,
      'deviation_percent': deviationPercent,
      'monitor_type': monitorType,
      'timestamp': timestamp.toIso8601String(),
      'is_ignored': isIgnored,
      'ignored_at': ignoredAt,
    };
  }

  // Методы для изменения состояния
  void markAsIgnored() {
    isIgnored = true;
    ignoredAt = DateTime.now().toIso8601String();
  }
  
  void markAsActive() {
    isIgnored = false;
    ignoredAt = null;
  }
  
  String get deviationText {
    if (resultValue > refUpper) {
      return '⬆️ +${deviationPercent.toStringAsFixed(1)}%';
    } else {
      return '⬇️ -${deviationPercent.toStringAsFixed(1)}%';
    }
  }
  
  String get refRangeText => '${refLower.toStringAsFixed(1)} - ${refUpper.toStringAsFixed(1)}';
  
  Color get severityColor {
    if (deviationPercent > 50) return Color(0xFFD32F2F);
    if (deviationPercent > 30) return Color(0xFFF57C00);
    return Color(0xFFFFC107);
  }
}

