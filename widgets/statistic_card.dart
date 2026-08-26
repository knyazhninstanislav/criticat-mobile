import 'package:flutter/material.dart';

class StatisticCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final String? subtitle;
  
  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
    this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2e3e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Иконка
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Значение
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 5),
            
            // Название
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            // Подзаголовок (опционально)
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Вариант с горизонтальным расположением
class StatisticCardHorizontal extends StatelessWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  
  const StatisticCardHorizontal({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2e3e),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            
            const SizedBox(width: 10),
            
            // Значение и название
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Вариант с анимацией изменения значения
class AnimatedStatisticCard extends StatefulWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  
  const AnimatedStatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });
  
  @override
  State<AnimatedStatisticCard> createState() => _AnimatedStatisticCardState();
}

class _AnimatedStatisticCardState extends State<AnimatedStatisticCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }
  
  @override
  void didUpdateWidget(AnimatedStatisticCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: StatisticCard(
        title: widget.title,
        value: widget.value,
        color: widget.color,
        icon: widget.icon,
      ),
    );
  }
}

// Вариант с прогресс-баром
class StatisticCardWithProgress extends StatelessWidget {
  final String title;
  final int value;
  final int total;
  final Color color;
  final IconData icon;
  
  const StatisticCardWithProgress({
    super.key,
    required this.title,
    required this.value,
    required this.total,
    required this.color,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? value / total : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2e3e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          Text(
            '$value / $total',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Прогресс-бар
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 5),
          
          Text(
            '${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// Вариант с трендом
class StatisticCardWithTrend extends StatelessWidget {
  final String title;
  final int value;
  final int previousValue;
  final Color color;
  final IconData icon;
  
  const StatisticCardWithTrend({
    super.key,
    required this.title,
    required this.value,
    required this.previousValue,
    required this.color,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final difference = value - previousValue;
    final isPositive = difference >= 0;
    final trendColor = isPositive ? Colors.red : Colors.green;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2e3e),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 5),
          
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 16),
              const SizedBox(width: 5),
              Text(
                '${isPositive ? "+" : ""}$difference',
                style: TextStyle(
                  color: trendColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'с прошлого раза',
                style: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}