import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../appwrite/appwrite_service.dart';
import '../appwrite/auth_storage_service.dart';
import '../models/task_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/status_chip.dart';
import 'add_task_screen.dart';
import 'task_detail_page.dart';
import 'edit_task_page.dart';
import 'login_screens.dart';

class HomePage extends StatefulWidget {
  final String userName;
  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final AppwriteService _service = AppwriteService();
  late StreamSubscription _realtimeSub;
  late TabController _tabController;
  List<Task> tasks = [];
  String _sortBy = 'newest'; // newest, deadline, status, title
  bool _isLoading = true;

  bool get isAdmin => widget.userName.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    // Only initialize tab controller for non-admin users
    if (!isAdmin) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {}); // Refresh UI when tab changes
        }
      });
    }
    _loadTasks();
    _listenToRealtime();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final res = await _service.getTasks(widget.userName, isAdmin);
    setState(() {
      tasks = res;
      _sortTasks();
      _isLoading = false;
    });
  }

  void _sortTasks() {
    switch (_sortBy) {
      case 'newest':
        // Sort by creation date, newest first
        tasks.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.now();
          final bTime = b.createdAt ?? DateTime.now();
          return bTime.compareTo(aTime); // Reverse order for newest first
        });
        break;
      case 'deadline':
        tasks.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'status':
        tasks.sort((a, b) {
          const statusOrder = {'pending': 0, 'in-progress': 1, 'completed': 2};
          return (statusOrder[a.status] ?? 0).compareTo(statusOrder[b.status] ?? 0);
        });
        break;
      case 'title':
        tasks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
  }

  void _listenToRealtime() {
    _realtimeSub = _service.getRealtimeUpdates().listen((event) {
      _loadTasks();
    });
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'newest':
        return 'Newest';
      case 'deadline':
        return 'Deadline';
      case 'status':
        return 'Status';
      case 'title':
        return 'A-Z';
      default:
        return 'Sort';
    }
  }

  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: isSelected
          ? BoxDecoration(
              color: const Color(0xFF26C6DA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF26C6DA).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSelected ? const Color(0xFF26C6DA) : Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: isSelected ? const Color(0xFF26C6DA) : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle,
              color: Color(0xFF26C6DA),
              size: 20,
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _realtimeSub.cancel();
    if (!isAdmin) {
      _tabController.dispose();
    }
    super.dispose();
  }
  
  // Get filtered tasks based on current tab
  List<Task> get _filteredTasks {
    // Admin sees all tasks
    if (isAdmin) {
      return tasks;
    }
    
    // Non-admin users see filtered tasks based on tab
    if (_tabController.index == 0) {
      // My Tasks - tasks assigned to me
      return tasks.where((task) {
        final assignedUsers = task.assignedTo.toLowerCase().split(',').map((e) => e.trim()).toList();
        return assignedUsers.contains(widget.userName.toLowerCase());
      }).toList();
    } else {
      // Team's Tasks - tasks I created and assigned to others
      return tasks.where((task) {
        return task.createdBy.toLowerCase() == widget.userName.toLowerCase();
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withOpacity(0.3),
                    const Color(0xFF26C6DA).withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF26C6DA).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                isAdmin ? Icons.dashboard_rounded : Icons.task_alt_rounded,
                color: const Color(0xFF26C6DA),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isAdmin ? 'Admin Dashboard' : '${widget.userName}\'s Tasks',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: isAdmin 
            ? null 
            : TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF26C6DA),
                indicatorWeight: 3,
                labelColor: const Color(0xFF26C6DA),
                unselectedLabelColor: Colors.white60,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.assignment_ind),
                    text: 'My Tasks',
                  ),
                  Tab(
                    icon: const Icon(Icons.groups),
                    text: 'Team\'s Tasks',
                  ),
                ],
              ),
        actions: [
          // Sort/Filter Button
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF26C6DA).withOpacity(0.15),
                  const Color(0xFF7C4DFF).withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF26C6DA).withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: PopupMenuButton<String>(
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune,
                        color: const Color(0xFF26C6DA),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getSortLabel(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF26C6DA),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                color: const Color(0xFF203a43),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color(0xFF26C6DA).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                offset: const Offset(0, 50),
                onSelected: (value) {
                  setState(() {
                    _sortBy = value;
                    _sortTasks();
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'newest',
                    child: _buildSortOption(
                      icon: Icons.new_releases,
                      title: 'Newest First',
                      subtitle: 'Recently added tasks',
                      isSelected: _sortBy == 'newest',
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'deadline',
                    child: _buildSortOption(
                      icon: Icons.event,
                      title: 'By Deadline',
                      subtitle: 'Urgent tasks first',
                      isSelected: _sortBy == 'deadline',
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'status',
                    child: _buildSortOption(
                      icon: Icons.circle,
                      title: 'By Status',
                      subtitle: 'Pending → In Progress → Done',
                      isSelected: _sortBy == 'status',
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'title',
                    child: _buildSortOption(
                      icon: Icons.sort_by_alpha,
                      title: 'Alphabetically',
                      subtitle: 'A to Z',
                      isSelected: _sortBy == 'title',
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Logout Button
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withOpacity(0.15),
                  Colors.red.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF203a43),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.redAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: Text(
                        'Are you sure you want to logout?',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.redAccent, Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true && mounted) {
                    // Clear login state
                    await AuthStorageService.clearLoginState();
                    // Logout from Appwrite
                    await _service.logout();
                    // Navigate to login page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF26C6DA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF26C6DA).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTaskPage(currentUserName: widget.userName),
              ),
            );
            _loadTasks();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🔹 Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🔹 Task List
          Padding(
            padding: EdgeInsets.only(top: isAdmin ? 100 : 140, left: 16, right: 16),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF26C6DA).withOpacity(0.3),
                            ),
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26C6DA)),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Loading tasks...',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
              onRefresh: _loadTasks,
                    color: const Color(0xFF26C6DA),
              child: _filteredTasks.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getEmptyMessage(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  final bool canUpdateStatus = isAdmin || task.assignedTo.toLowerCase() == widget.userName.toLowerCase();
                  // prettyStatus removed; StatusChip handles labels/colors
                  String relativeDeadline(DateTime deadline) {
                    final now = DateTime.now();
                    final diff = deadline.difference(now);
                    if (diff.isNegative) {
                      final d = diff.abs();
                      if (d.inDays >= 1) return '${d.inDays}d ago';
                      if (d.inHours >= 1) return '${d.inHours}h ago';
                      if (d.inMinutes >= 1) return '${d.inMinutes}m ago';
                      return 'just now';
                    } else {
                      if (diff.inDays >= 1) return 'in ${diff.inDays}d';
                      if (diff.inHours >= 1) return 'in ${diff.inHours}h';
                      if (diff.inMinutes >= 1) return 'in ${diff.inMinutes}m';
                      return 'soon';
                    }
                  }
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    margin: EdgeInsets.only(
                      top: index == 0 ? 0 : 10,
                      bottom: 10,
                    ),
                    child: _buildSwipeableOrPlain(
                      context: context,
                      isAdmin: isAdmin,
                      task: task,
                      onRefresh: _loadTasks,
                      service: _service,
                      userName: widget.userName,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailPage(
                                task: task,
                                isAdmin: isAdmin,
                                currentUserName: widget.userName,
                              ),
                            ),
                          );
                        },
                        title: Hero(
                          tag: 'task-title-${task.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              task.title,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.event_outlined, size: 16, color: Colors.white54),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (task.deadline.isBefore(DateTime.now())
                                              ? Colors.redAccent
                                              : Colors.blueAccent)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      relativeDeadline(task.deadline),
                                      style: TextStyle(
                                        color: task.deadline.isBefore(DateTime.now())
                                            ? Colors.redAccent
                                            : Colors.blueAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: canUpdateStatus
                            ? PopupMenuButton<String>(
                                color: Colors.black,
                                onSelected: (val) async {
                                  // store lowercase in DB
                                  final dbVal = val == 'Pending'
                                      ? 'pending'
                                      : val == 'In Progress'
                                          ? 'in-progress'
                                          : 'completed';
                                  await _service.updateTaskStatus(task.id, dbVal);
                                  _loadTasks();
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'Pending', child: Text('Pending')),
                                  PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                                  PopupMenuItem(value: 'Completed', child: Text('Completed')),
                                ],
                                child: Container(
                                  child: StatusChip(status: task.status),
                                ),
                              )
                            : StatusChip(status: task.status),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getEmptyMessage() {
    if (isAdmin) {
      return 'Create your first task!';
    }
    if (!isAdmin && _tabController.index == 0) {
      return 'No tasks assigned to you yet';
    } else {
      return 'You haven\'t created any tasks yet';
    }
  }
}

Widget _buildSwipeableOrPlain({
  required BuildContext context,
  required bool isAdmin,
  required Task task,
  required Future<void> Function() onRefresh,
  required AppwriteService service,
  required Widget child,
  required String userName,
}) {
  // Allow edit/delete if user is admin OR task creator
  final canModify = isAdmin || task.createdBy.toLowerCase() == userName.toLowerCase();
  
  if (!canModify) {
    return GlassContainer(child: child);
  }
  return Dismissible(
    key: ValueKey('task-${task.id}'),
    background: _SwipeBackground(
      color: Colors.green.withOpacity(0.2),
      icon: Icons.edit,
      alignStart: true,
      label: 'Edit',
    ),
    secondaryBackground: _SwipeBackground(
      color: Colors.redAccent.withOpacity(0.2),
      icon: Icons.delete,
      alignStart: false,
      label: 'Delete',
    ),
    confirmDismiss: (direction) async {
      // Left-to-right: edit
      if (direction == DismissDirection.startToEnd) {
        HapticFeedback.selectionClick();
        // Open edit and do not dismiss
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditTaskPage(
                task: task,
                currentUserName: userName,
                isAdmin: isAdmin,
              ),
            ),
          );
          if (changed == true) await onRefresh();
        });
        return false;
      }
      // Right-to-left: delete with confirmation
      if (direction == DismissDirection.endToStart) {
        HapticFeedback.mediumImpact();
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirm == true) {
          final backup = task;
          await service.deleteTask(task.id);
          await onRefresh();
          // Snackbar with UNDO
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Task deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () async {
                  try {
                    await service.createTaskWithId(backup);
                    await onRefresh();
                  } catch (_) {}
                },
              ),
            ),
          );
          return true;
        }
        return false;
      }
      return false;
    },
    child: GlassContainer(child: child),
  );
}

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool alignStart;
  final String label;
  const _SwipeBackground({required this.color, required this.icon, required this.alignStart, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignStart ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: alignStart ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!alignStart) const SizedBox.shrink(),
          Icon(icon, color: alignStart ? Colors.green : Colors.redAccent),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: alignStart ? Colors.green : Colors.redAccent, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
