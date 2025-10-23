import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/status_chip.dart';

class TaskDetailPage extends StatelessWidget {
  final Task task;
  final bool isAdmin;
  const TaskDetailPage({super.key, required this.task, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    // labels/colors handled by StatusChip

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Task Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
            child: GlassContainer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Hero(
                            tag: 'task-title-${task.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                task.title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        StatusChip(status: task.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned to:',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: task.assignedUsers.map((user) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C4DFF).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF7C4DFF).withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      user,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF7C4DFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (task.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Created at: ${_formatDateTime(task.createdAt!)}',
                            style: GoogleFonts.poppins(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event_outlined, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Builder(
                          builder: (_) {
                            final now = DateTime.now();
                            final diff = task.deadline.difference(now);
                            final overdue = diff.isNegative;
                            final rel = _relativeTime(diff);
                            return Text(
                              'Deadline: ${_formatDate(task.deadline)}  ($rel)',
                              style: GoogleFonts.poppins(
                                color: overdue ? Colors.redAccent : Colors.white70,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    Text(
                      task.description,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        height: 1.4,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

String _relativeTime(Duration diff) {
  if (diff.isNegative) {
    final d = diff.abs();
    if (d.inDays >= 1) return '${d.inDays} day(s) ago';
    if (d.inHours >= 1) return '${d.inHours} hour(s) ago';
    if (d.inMinutes >= 1) return '${d.inMinutes} minute(s) ago';
    return 'just now';
  } else {
    if (diff.inDays >= 1) return 'in ${diff.inDays} day(s)';
    if (diff.inHours >= 1) return 'in ${diff.inHours} hour(s)';
    if (diff.inMinutes >= 1) return 'in ${diff.inMinutes} minute(s)';
    return 'soon';
  }
}

String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dateTime.year}-${two(dateTime.month)}-${two(dateTime.day)} ${two(dateTime.hour)}:${two(dateTime.minute)}';
}


