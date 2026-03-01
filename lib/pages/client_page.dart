import 'package:dashbord/models/enums.dart';
import 'package:dashbord/models/parameter.dart';
import 'package:dashbord/screens/alarms_screen.dart';
import 'package:dashbord/screens/dashboard_screen.dart';
import 'package:dashbord/screens/deformation_screen.dart';
import 'package:dashbord/screens/nem_analysis_screen.dart';
import 'package:dashbord/screens/reactions_screen.dart';
import 'package:dashbord/util/my_drawers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<_TabItem> _tabs = const [
    _TabItem(title: 'Dashboard', icon: Icons.dashboard_outlined),
    _TabItem(title: 'Nem Analizi', icon: Icons.water_drop_outlined),
    _TabItem(title: 'Deformasyon', icon: Icons.straighten_outlined),
    _TabItem(title: 'Alarmlar', icon: Icons.notifications_outlined),
    _TabItem(title: 'Reaksiyonlar', icon: Icons.rule_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('VitrA SPC - Kalite Kontrol Sistemi'),
              backgroundColor: const Color(0xFF98312A),
              foregroundColor: Colors.white,
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _tabs.map((tab) => Tab(text: tab.title)).toList(),
              ),
              actions: [
                _buildSimulationButton(provider),
                _buildStatusBadge(provider),
                _buildNotificationIcon(provider),
              ],
            ),
            body: Row(
              children: [
                _buildDrawer(provider),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      DashboardScreen(),
                      NemAnalysisScreen(),
                      DeformationScreen(),
                      AlarmsScreen(),
                      ReactionsScreen(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimulationButton(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: provider.simRunning ? Colors.amber : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton.icon(
        onPressed: () => provider.toggleSimulation(),
        icon: Icon(
          provider.simRunning ? Icons.stop : Icons.play_arrow,
          color: provider.simRunning ? Colors.black : const Color(0xFF98312A),
          size: 18,
        ),
        label: Text(
          provider.simRunning ? 'DURDUR' : 'SİMÜLASYON',
          style: TextStyle(
            fontSize: 12,
            color: provider.simRunning ? Colors.black : const Color(0xFF98312A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AppProvider provider) {
    final statusColor = _getStatusColor(provider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(provider),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(AppProvider provider) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _showNotificationDrawer(context, provider),
        ),
        if (provider.criticalAlarmCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  '${provider.criticalAlarmCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer(AppProvider provider) {
    return Container(
      width: 240,
      color: Colors.grey.shade50,
      child: Column(
        children: [
          ..._buildNavItems(provider),
          const Divider(),
          _buildParametersSection(provider),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(AppProvider provider) {
    return _tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      
      return ListTile(
        leading: Icon(tab.icon, size: 20),
        title: Text(tab.title, style: const TextStyle(fontSize: 13)),
        trailing: index == 3 && provider.criticalAlarmCount > 0
            ? Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    '${provider.criticalAlarmCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              )
            : null,
        selected: _tabController.index == index,
        selectedTileColor: const Color(0xFF98312A).withValues(alpha: 0.1),
        onTap: () => _tabController.animateTo(index),
      );
    }).toList();
  }

  Widget _buildParametersSection(AppProvider provider) {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'PARAMETRELER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ...['nem', 'uk1', 'uk2', 'm1', 'm2'].map((key) {
            final param = provider.parameters[key];
            if (param == null) return const SizedBox.shrink();
            return _buildParameterTile(param);
          }),
        ],
      ),
    );
  }

  Widget _buildParameterTile(Parameter parameter) {
    final cpk = parameter.cpk;
    final lastValue = parameter.lastValue;
    
    Color getStatusColor() {
      if (cpk == null) return Colors.orange;
      if (cpk.cpk >= 1.33) return Colors.green;
      if (cpk.cpk >= 1.0) return Colors.orange;
      return Colors.red;
    }

    return InkWell(
      onTap: () {
        final index = parameter.key == 'nem' ? 1 : 2;
        _tabController.animateTo(index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  parameter.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Cpk ${cpk?.cpk.toStringAsFixed(2) ?? '—'}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _buildProgressBar(parameter),
            const SizedBox(height: 4),
            Text(
              lastValue != null
                  ? '${lastValue.toStringAsFixed(3)} ${parameter.unit}'
                  : 'veri yok',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Parameter parameter) {
    final lastValue = parameter.lastValue;
    final percent = lastValue != null
        ? ((lastValue - parameter.lsl) / (parameter.usl - parameter.lsl) * 100)
            .clamp(0, 100)
        : 50.0;

    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percent / 100,
        child: Container(
          decoration: BoxDecoration(
            color: _getCpkColor(parameter.cpkStatus),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Color _getCpkColor(StatusType status) {
    switch (status) {
      case StatusType.ok:
        return Colors.green;
      case StatusType.warn:
        return Colors.orange;
      case StatusType.danger:
        return Colors.red;
    }
  }

  Color _getStatusColor(AppProvider provider) {
    if (provider.criticalAlarmCount > 0) return Colors.red;
    if (provider.alarms.where((a) => a.type == AlarmType.warn).any((a) {
      final minutesSince = DateTime.now().difference(a.timestamp).inMinutes;
      return minutesSince < 3;
    })) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getStatusText(AppProvider provider) {
    if (provider.criticalAlarmCount > 0) {
      return '${provider.criticalAlarmCount} KRİTİK ALARM';
    }
    if (provider.alarms.where((a) => a.type == AlarmType.warn).any((a) {
      final minutesSince = DateTime.now().difference(a.timestamp).inMinutes;
      return minutesSince < 3;
    })) {
      return 'UYARI VAR';
    }
    return 'SİSTEM NORMAL';
  }

  void _showNotificationDrawer(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => NotificationDrawer(provider: provider),
    );
  }
}

class _TabItem {
  final String title;
  final IconData icon;

  const _TabItem({required this.title, required this.icon});
}