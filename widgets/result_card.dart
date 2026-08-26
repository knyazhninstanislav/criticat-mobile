import 'package:flutter/material.dart';
import '../models/critical_result.dart';

class ResultCard extends StatelessWidget {
  final CriticalResult result;
  final VoidCallback onTap;
  
  const ResultCard({
    super.key,
    required this.result,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: result.isIgnored ? Colors.green : Colors.red,
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                if (result.isIgnored)
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ),
            
            const SizedBox(height: 5),
            
            Text(
              result.department,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            const Divider(height: 15),
            
            // Тест и значение
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.testName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                    ),
                  ),
                ),
                Text(
                  result.resultValue.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFff2d55),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 5),
            
            Text(
              'Норма: ${result.refRangeText}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Отклонение и время
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: result.severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    result.deviationText,
                    style: TextStyle(
                      color: result.severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(result.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Только что';
    if (diff.inHours < 1) return '${diff.inMinutes} мин назад';
    if (diff.inDays < 1) return '${diff.inHours} ч назад';
    return '${time.day}.${time.month}.${time.year}';
  }
}