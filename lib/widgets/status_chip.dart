import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status; // 'pending' | 'in-progress' | 'completed'
  const StatusChip({super.key, required this.status});

  Color _color() {
    switch (status) {
      case 'pending':
        return Colors.amberAccent;
      case 'in-progress':
        return Colors.lightBlueAccent;
      case 'completed':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  String _label() {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in-progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.6)),
      ),
      child: Text(_label(), style: TextStyle(color: c, fontWeight: FontWeight.w600)),
    );
  }
}


