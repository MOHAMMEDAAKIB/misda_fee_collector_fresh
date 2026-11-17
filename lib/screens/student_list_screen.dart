// lib/screens/student_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';
import 'register_student_screen.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});
  @override
  State<StudentListScreen> createState() => _State();
}

class _State extends State<StudentListScreen> {
  String _q = '';
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<StudentProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudentProvider>();
    final q = _q.trim().toLowerCase();
    final all = p.students.where((s) => _showInactive || s.isActive).toList();
    final list = q.isEmpty
        ? all
        : all.where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.regNo.toLowerCase().contains(q) ||
            s.phone.contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Students (${p.students.where((s) => _showInactive || s.isActive).length})'),
        actions: [
          Switch(
            value: _showInactive,
            onChanged: (v) => setState(() => _showInactive = v),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Register'),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RegisterStudentScreen())),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name, reg number or phone',
                border: OutlineInputBorder()),
            onChanged: (v) => setState(() => _q = v),
          ),
        ),
        if (p.error != null)
          Padding(padding: const EdgeInsets.all(8), child: Text(p.error!)),
        Expanded(
          child: RefreshIndicator(
            onRefresh: p.load,
            child: p.loading && p.students.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: CircleAvatar(child: Text(
                          list[i].name.isEmpty ? '?' : list[i].name[0])),
                      title: Text(list[i].name),
                      subtitle: Text('${list[i].regNo} • ${list[i].className}'),
                      trailing: Text(list[i].phone),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => StudentDetailScreen(student: list[i]))),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}