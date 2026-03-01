import 'package:dashbord/models/enums.dart';
import 'package:flutter/material.dart';

class ReactionCard extends StatelessWidget {
  final String title;
  final List<String> steps;
  final AlarmType type;

  const ReactionCard({
    super.key,
    required this.title,
    required this.steps,
    required this.type,
  });

  factory ReactionCard.danger({
    required String title,
    required List<String> steps,
  }) {
    return ReactionCard(
      title: title,
      steps: steps,
      type: AlarmType.danger,
    );
  }

  factory ReactionCard.warn({
    required String title,
    required List<String> steps,
  }) {
    return ReactionCard(
      title: title,
      steps: steps,
      type: AlarmType.warn,
    );
  }

  factory ReactionCard.ok({
    required String title,
    required List<String> steps,
  }) {
    return ReactionCard(
      title: title,
      steps: steps,
      type: AlarmType.ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          ...steps.map((step) => _buildStep(step)),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (type) {
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
    switch (type) {
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

  Color _getTextColor() {
    switch (type) {
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

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          _getIconData(),
          color: _getTextColor(),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getTextColor(),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconData() {
    switch (type) {
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

  Widget _buildStep(String step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '→',
            style: TextStyle(
              color: _getTextColor(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}