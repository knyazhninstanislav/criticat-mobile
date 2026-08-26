import 'package:flutter/material.dart';
import '../models/critical_result.dart';
import '../services/mqtt_service.dart';
import '../widgets/result_card.dart';
import '../widgets/statistic_card.dart';
import 'result_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final MQTTService mqttService;
  
  const HomeScreen({
    super.key,
    required this.mqttService,
  });
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CriticalResult> _filteredResults = [];
  String _filter = 'active';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    
    // Подписка на изменения
    widget.mqttService.addListener(_onServiceChanged);
    
    // Подписка на стрим результатов
    widget.mqttService.resultsStream.listen((results) {
      if (mounted) {
        _applyFilter();
      }
    });
    
    // Подписка на стрим соединения
    widget.mqttService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {});
      }
    });
    
    // Автоматический запрос данных при загрузке
    Future.delayed(const Duration(seconds: 1), () {
      if (widget.mqttService.isConnected) {
        _requestData();
      }
    });
  }
  
  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  void _applyFilter() {
    setState(() {
      final results = widget.mqttService.results;
      switch (_filter) {
        case 'active':
          _filteredResults = results.where((r) => !r.isIgnored).toList();
          break;
        case 'ignored':
          _filteredResults = results.where((r) => r.isIgnored).toList();
          break;
        default:
          _filteredResults = results;
      }
    });
  }
  
  void _requestData() async {
    setState(() => _isLoading = true);
    
    if (!widget.mqttService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нет подключения к серверу'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    
    widget.mqttService.requestData();
    
    // Ждем ответ
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Запрос отправлен, получено ${widget.mqttService.results.length} результатов'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  @override
  void dispose() {
    widget.mqttService.removeListener(_onServiceChanged);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final activeCount = widget.mqttService.activeCount;
    final ignoredCount = widget.mqttService.ignoredCount;
    final totalCount = widget.mqttService.results.length;
    final isConnected = widget.mqttService.isConnected;
    
    _applyFilter();
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1e2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1e2e),
        title: Row(
          children: [
            const Text(
              'CritiCat',
              style: TextStyle(
                color: Color(0xFFff2d55),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          // КНОПКА ЗАПРОСА ДАННЫХ
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _requestData,
            tooltip: 'Запросить данные',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(mqttService: widget.mqttService),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: StatisticCard(
                    title: 'Активные',
                    value: activeCount,
                    color: const Color(0xFFff2d55),
                    icon: Icons.warning_amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatisticCard(
                    title: 'Обработанные',
                    value: ignoredCount,
                    color: const Color(0xFF00ff94),
                    icon: Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatisticCard(
                    title: 'Всего',
                    value: totalCount,
                    color: const Color(0xFF42a5f5),
                    icon: Icons.list_alt,
                  ),
                ),
              ],
            ),
          ),
          
          // Фильтры
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildFilterChip('active', 'Активные'),
                _buildFilterChip('ignored', 'Обработанные'),
                _buildFilterChip('all', 'Все'),
                const Spacer(),
                // Индикатор загрузки
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Text(
                  '${widget.mqttService.results.length}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Список результатов
          Expanded(
            child: _filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 80,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Нет результатов',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isConnected ? 'Нажмите 🔄 для запроса' : 'Нет подключения',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = _filteredResults[index];
                      return ResultCard(
                        result: result,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultDetailScreen(
                                result: result,
                                mqttService: widget.mqttService,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filter = value;
            _applyFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFff2d55) : const Color(0xFF2a2e3e),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}