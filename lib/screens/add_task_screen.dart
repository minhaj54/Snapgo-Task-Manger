import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../appwrite/appwrite_service.dart';
import '../models/task_model.dart';

class AddTaskPage extends StatefulWidget {
  final String currentUserName;
  const AddTaskPage({super.key, required this.currentUserName});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();

  final AppwriteService _service = AppwriteService();
  bool _loading = false;
  List<String> _users = [];
  List<String> _selectedUsers = []; // Multiple users selection
  DateTime? _selectedDeadline;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _service.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  Future<void> _addTask() async {
    if (titleController.text.isEmpty ||
        descController.text.isEmpty ||
        _selectedUsers.isEmpty ||
        _selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Please fill all fields before adding task"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Join selected users with comma
      final assignedToStr = _selectedUsers.map((e) => e.toLowerCase()).join(', ');
      
      final task = Task(
        id: '',
        title: titleController.text.trim(),
        description: descController.text.trim(),
        assignedTo: assignedToStr,
        deadline: _selectedDeadline!,
        status: _selectedStatus,
        createdBy: widget.currentUserName,
      );

      await _service.addTask(task);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Task added successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Wait for feedback visibility
      await Future.delayed(const Duration(milliseconds: 700));

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to add task: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Add Task',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(titleController, 'Title'),
            const SizedBox(height: 12),
            _buildTextField(descController, 'Description', maxLines: 3),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign To (${_selectedUsers.length} selected)',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Display selected users as chips
                      if (_selectedUsers.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedUsers.map((user) {
                            return Chip(
                              label: Text(
                                user,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: const Color(0xFF7C4DFF).withOpacity(0.3),
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedUsers.remove(user);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 8),
                      // Button to open user selection
                      OutlinedButton.icon(
                        onPressed: () => _showUserSelectionDialog(),
                        icon: const Icon(Icons.person_add, color: Color(0xFF26C6DA)),
                        label: Text(
                          'Select Users',
                          style: GoogleFonts.poppins(color: Color(0xFF26C6DA)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF26C6DA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDeadline ?? now,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDeadline = picked;
                    deadlineController.text = _formatDate(picked);
                  });
                }
              },
              child: AbsorbPointer(
                child: _buildTextField(deadlineController, 'Deadline (YYYY-MM-DD)'),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
              ],
              onChanged: (v) => setState(() => _selectedStatus = v ?? 'pending'),
              dropdownColor: const Color(0xFF203a43),
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
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
            const SizedBox(height: 30),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF26C6DA),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF26C6DA)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: _addTask,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                "Add Task",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF203a43),
              title: Text(
                'Select Users',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isSelected = _selectedUsers.contains(user);
                    return CheckboxListTile(
                      title: Text(
                        user,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      value: isSelected,
                      activeColor: const Color(0xFF26C6DA),
                      checkColor: Colors.white,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            if (!_selectedUsers.contains(user)) {
                              _selectedUsers.add(user);
                            }
                          } else {
                            _selectedUsers.remove(user);
                          }
                        });
                        setState(() {}); // Update parent widget
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: GoogleFonts.poppins(color: const Color(0xFF26C6DA)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white70),
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
    );
  }
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
