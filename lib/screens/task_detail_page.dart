import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../models/comment_model.dart';
import '../widgets/glass_container.dart';
import '../widgets/status_chip.dart';
import '../appwrite/appwrite_service.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final bool isAdmin;
  final String currentUserName;
  
  const TaskDetailPage({
    super.key,
    required this.task,
    required this.isAdmin,
    required this.currentUserName,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final AppwriteService _service = AppwriteService();
  final TextEditingController _commentController = TextEditingController();
  late StreamSubscription _realtimeSub;
  List<Comment> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _listenToRealtimeComments();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);
    final comments = await _service.getComments(widget.task.id);
    setState(() {
      _comments = comments;
      _isLoadingComments = false;
    });
  }

  void _listenToRealtimeComments() {
    _realtimeSub = _service.getCommentsRealtimeUpdates(widget.task.id).listen((event) {
      _loadComments();
    });
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      final comment = Comment(
        id: '',
        taskId: widget.task.id,
        authorName: widget.currentUserName,
        content: _commentController.text.trim(),
      );

      await _service.addComment(comment);
      _commentController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post comment: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isPostingComment = false);
    }
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203a43),
        title: Text(
          'Edit Comment',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your comment...',
            hintStyle: GoogleFonts.poppins(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF26C6DA), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: const Color(0xFF26C6DA)),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != comment.content) {
      try {
        await _service.updateComment(comment.id, result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment updated!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update comment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF203a43),
        title: Text(
          'Delete Comment',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteComment(comment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _realtimeSub.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                // Task Details Card
                GlassContainer(
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
                                tag: 'task-title-${widget.task.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                    widget.task.title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                            StatusChip(status: widget.task.status),
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
                                    children: widget.task.assignedUsers.map((user) {
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
                        if (widget.task.createdBy.isNotEmpty) ...[
                    const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.create, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Created by: ${widget.task.createdBy}',
                                style: GoogleFonts.poppins(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                        if (widget.task.createdAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                                'Created at: ${_formatDateTime(widget.task.createdAt!)}',
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
                                final diff = widget.task.deadline.difference(now);
                            final overdue = diff.isNegative;
                            final rel = _relativeTime(diff);
                            return Text(
                                  'Deadline: ${_formatDate(widget.task.deadline)}  ($rel)',
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
                          widget.task.description,
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
                const SizedBox(height: 20),
                
                // Comments Section
                GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.comment_outlined, color: Color(0xFF26C6DA), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Comments (${_comments.length})',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Comment Input (Enhanced Chat Style)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF26C6DA).withOpacity(0.1),
                                const Color(0xFF7C4DFF).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF26C6DA).withOpacity(0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF26C6DA).withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const SizedBox(width: 16),
                                // Text Input
                                Expanded(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 100,
                                    ),
                                    child: TextField(
                                      controller: _commentController,
                                      maxLines: null,
                                      textCapitalization: TextCapitalization.sentences,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.4,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Type your message...',
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.white54,
                                          fontSize: 15,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Send Button
                                _isPostingComment
                                    ? Container(
                                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        child: const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26C6DA)),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        margin: const EdgeInsets.only(right: 4, bottom: 4),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF26C6DA),
                                              Color(0xFF7C4DFF),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF26C6DA).withOpacity(0.4),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(28),
                                            onTap: _postComment,
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              child: const Icon(
                                                Icons.send_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Comments List (Chat Style)
                        _isLoadingComments
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF26C6DA)),
                                  ),
                                ),
                              )
                            : _comments.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            size: 48,
                                            color: Colors.white.withOpacity(0.3),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No comments yet',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white54,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Be the first to comment!',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _comments.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final comment = _comments[index];
                                      final isAuthor = comment.authorName.toLowerCase() == 
                                                       widget.currentUserName.toLowerCase();
                                      
                                      return _buildChatBubble(comment, isAuthor);
                                    },
                                  ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatBubble(Comment comment, bool isAuthor) {
    return Align(
      alignment: isAuthor ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isAuthor ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar for others (left side)
          if (!isAuthor) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.3),
              child: Text(
                comment.authorName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF7C4DFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Chat Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: isAuthor ? () => _showMessageOptions(comment) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isAuthor
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF26C6DA).withOpacity(0.8),
                            const Color(0xFF7C4DFF).withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isAuthor ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isAuthor ? 16 : 4),
                    bottomRight: Radius.circular(isAuthor ? 4 : 16),
                  ),
                  border: Border.all(
                    color: isAuthor
                        ? const Color(0xFF26C6DA).withOpacity(0.3)
                        : Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author name (only for others)
                    if (!isAuthor) ...[
                      Text(
                        comment.authorName,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF7C4DFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Message content
                    Text(
                      comment.content,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Time and edited indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _formatCommentTime(comment),
                          style: GoogleFonts.poppins(
                            color: isAuthor
                                ? Colors.white.withOpacity(0.7)
                                : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Avatar for current user (right side)
          if (isAuthor) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF26C6DA).withOpacity(0.3),
              child: Text(
                comment.authorName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF26C6DA),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _showMessageOptions(Comment comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF203a43),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26C6DA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF26C6DA),
                  size: 20,
                ),
              ),
              title: Text(
                'Edit Message',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _editComment(comment);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              title: Text(
                'Delete Message',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteComment(comment);
              },
            ),
          ],
        ),
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

String _formatCommentTime(Comment comment) {
  final time = comment.updatedAt ?? comment.createdAt;
  if (time == null) return '';
  
  final now = DateTime.now();
  final diff = now.difference(time);
  
  String timeStr;
  if (diff.inDays >= 1) {
    timeStr = '${diff.inDays}d ago';
  } else if (diff.inHours >= 1) {
    timeStr = '${diff.inHours}h ago';
  } else if (diff.inMinutes >= 1) {
    timeStr = '${diff.inMinutes}m ago';
  } else {
    timeStr = 'just now';
  }
  
  // Check if comment was edited (updatedAt is different from createdAt)
  if (comment.updatedAt != null && comment.createdAt != null) {
    final timeDiff = comment.updatedAt!.difference(comment.createdAt!).abs();
    // If difference is more than 1 second, consider it edited
    if (timeDiff.inSeconds > 1) {
      return '$timeStr (edited)';
    }
  }
  
  return timeStr;
}
