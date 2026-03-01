import 'package:dashbord/models/enums.dart';
import 'package:flutter/material.dart';
import '../../models/alarm.dart';
import '../../providers/app_provider.dart';

class AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final AppProvider provider;
  final bool showResponseButton;

  const AlarmTile({
    super.key,
    required this.alarm,
    required this.provider,
    this.showResponseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(),
          const SizedBox(width: 12),
          Expanded(child: _buildContent(context)),
          _buildTime(),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (alarm.type) {
      case AlarmType.danger:
        return Colors.red.shade50;
      case AlarmType.warn:
        return Colors.orange.shade50;
      case AlarmType.ok:
        return Colors.green.shade50;
      case AlarmType.info:
        return Colors.blue.shade50;
    }
  }

  Color _getBorderColor() {
    switch (alarm.type) {
      case AlarmType.danger:
        return Colors.red.shade200;
      case AlarmType.warn:
        return Colors.orange.shade200;
      case AlarmType.ok:
        return Colors.green.shade200;
      case AlarmType.info:
        return Colors.blue.shade200;
    }
  }

  Color _getIconColor() {
    switch (alarm.type) {
      case AlarmType.danger:
        return Colors.red;
      case AlarmType.warn:
        return Colors.orange;
      case AlarmType.ok:
        return Colors.green;
      case AlarmType.info:
        return Colors.blue;
    }
  }

  IconData _getIconData() {
    switch (alarm.type) {
      case AlarmType.danger:
        return Icons.error_outline;
      case AlarmType.warn:
        return Icons.warning_amber_outlined;
      case AlarmType.ok:
        return Icons.check_circle_outline;
      case AlarmType.info:
        return Icons.info_outline;
    }
  }

  Widget _buildIcon() {
    return Icon(
      _getIconData(),
      color: _getIconColor(),
      size: 20,
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${alarm.parameterName} — ${alarm.message}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          alarm.suggestedAction,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        if (alarm.type == AlarmType.danger) ...[
          const SizedBox(height: 4),
          const Text(
            '✉️ E-posta bildirim gönderildi',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue,
            ),
          ),
        ],
        if (showResponseButton && !alarm.isResponded && alarm.type == AlarmType.danger)
          _buildResponseButton(context),
        if (alarm.isResponded)
          const Text(
            '✓ Müdahale Kaydedildi',
            style: TextStyle(
              color: Colors.green,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildResponseButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        provider.setCurrentAlarmForModal(alarm);
        // Modal will be shown by parent
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text(
        '+ Müdahale Gir',
        style: TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildTime() {
    return Text(
      alarm.formattedTime,
      style: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
      ),
    );
  }
}