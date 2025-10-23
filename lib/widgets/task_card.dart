import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      color: Colors.white.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(status: task.status),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                task.description,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Footer with deadline and assigned user
              Row(
                children: [
                  // Deadline
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: _getDeadlineColor(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDeadline(),
                          style: GoogleFonts.poppins(
                            color: _getDeadlineColor(),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Assigned user
                  if (task.assignedTo.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: Colors.white60,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.assignedTo,
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              
              // Action buttons (if showActions is true)
              if (showActions) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                        ),
                      ),
                    if (onEdit != null && onDelete != null)
                      const SizedBox(width: 8),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getDeadlineColor() {
    final now = DateTime.now();
    final diff = task.deadline.difference(now);
    
    if (diff.isNegative) {
      return Colors.redAccent; // Overdue
    } else if (diff.inDays <= 1) {
      return Colors.orangeAccent; // Due soon
    } else {
      return Colors.blueAccent; // Normal
    }
  }

  String _formatDeadline() {
    final now = DateTime.now();
    final diff = task.deadline.difference(now);
    
    if (diff.isNegative) {
      final overdue = diff.abs();
      if (overdue.inDays >= 1) {
        return '${overdue.inDays}d overdue';
      } else if (overdue.inHours >= 1) {
        return '${overdue.inHours}h overdue';
      } else {
        return 'Overdue';
      }
    } else {
      if (diff.inDays >= 1) {
        return 'Due in ${diff.inDays}d';
      } else if (diff.inHours >= 1) {
        return 'Due in ${diff.inHours}h';
      } else if (diff.inMinutes >= 1) {
        return 'Due in ${diff.inMinutes}m';
      } else {
        return 'Due soon';
      }
    }
  }
}
