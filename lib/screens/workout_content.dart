import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutContent extends StatefulWidget {
  const WorkoutContent({super.key});

  @override
  State<WorkoutContent> createState() => _WorkoutContentState();
}

class _WorkoutContentState extends State<WorkoutContent> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _workouts = [];
  String _selectedCategory = 'Ağırlık';
  String _selectedFilter = 'Tümü';
  bool _isLoading = true;

  final List<String> _categories = ['Ağırlık', 'Kardiyo', 'Esneme'];
  final List<String> _filters = ['Tümü', 'Ağırlık', 'Kardiyo', 'Esneme'];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Telefon hafızasından sadece kullanıcının eklediği antrenmanları yükle
  Future<void> _loadWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('user_workouts');

    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);
      setState(() {
        _workouts = decoded
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _workouts = [];
        _isLoading = false;
      });
    }
  }

  // Değişiklikleri telefon hafızasına kalıcı olarak kaydet
  Future<void> _saveWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_workouts);
    await prefs.setString('user_workouts', encoded);
  }

  void _addWorkout() {
    final title = _titleController.text.trim();
    final detail = _detailController.text.trim();
    final note = _noteController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir egzersiz adı girin.')),
      );
      return;
    }

    setState(() {
      _workouts.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'category': _selectedCategory,
        'detail': detail.isEmpty ? 'Belirtilmedi' : detail,
        'note': note,
        'isDone': false,
      });
    });

    _saveWorkouts();
    _titleController.clear();
    _detailController.clear();
    _noteController.clear();
    FocusScope.of(context).unfocus();
  }

  void _toggleWorkout(String id) {
    setState(() {
      final index = _workouts.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _workouts[index]['isDone'] = !(_workouts[index]['isDone'] as bool);
      }
    });
    _saveWorkouts();
  }

  void _deleteWorkout(String id) {
    setState(() {
      _workouts.removeWhere((item) => item['id'] == id);
    });
    _saveWorkouts();
  }

  void _clearCompleted() {
    setState(() {
      _workouts.removeWhere((item) => item['isDone'] == true);
    });
    _saveWorkouts();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Kardiyo':
        return Colors.orange.shade700;
      case 'Esneme':
        return Colors.purple.shade700;
      default:
        return Colors.blue.shade700;
    }
  }

  Color _getCategoryBgColor(String category) {
    switch (category) {
      case 'Kardiyo':
        return Colors.orange.shade50;
      case 'Esneme':
        return Colors.purple.shade50;
      default:
        return Colors.blue.shade50;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Kardiyo':
        return Icons.directions_run;
      case 'Esneme':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _workouts.length;
    final int completedCount = _workouts
        .where((w) => w['isDone'] == true)
        .length;
    final double progress = totalCount == 0 ? 0 : completedCount / totalCount;

    final List<Map<String, dynamic>> filteredWorkouts =
        _selectedFilter == 'Tümü'
        ? _workouts
        : _workouts.where((w) => w['category'] == _selectedFilter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst Başlık ve Günlük İlerleme Kartı
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.teal.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Antrenman Programım',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$completedCount / $totalCount Tamamlandı',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Detaylı Antrenman Ekleme Formu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Yeni Hareket Ekle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Egzersiz Adı (Örn: Bench Press, Koşu)',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.sports_gymnastics),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: TextField(
                        controller: _detailController,
                        decoration: InputDecoration(
                          labelText: 'Set/Süre (4x12)',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText:
                              'Ağırlık / Not (İsteğe bağlı - Örn: 50 kg)',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.edit_note),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _addWorkout,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Ekle',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Kategori Filtreleri ve Tamamlananları Temizle Butonu
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: Colors.green.shade100,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.green.shade900
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (completedCount > 0)
                TextButton.icon(
                  onPressed: _clearCompleted,
                  icon: const Icon(
                    Icons.cleaning_services_outlined,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Bitenleri Sil',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Antrenman Listesi
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredWorkouts.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _workouts.isEmpty
                        ? 'Henüz antrenman eklemedin.\nYukarıdan kendi programını oluşturabilirsin!'
                        : 'Bu kategoride kayıtlı hareket bulunmuyor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredWorkouts.length,
              itemBuilder: (context, index) {
                final item = filteredWorkouts[index];
                final bool isDone = item['isDone'] as bool;
                final String category = item['category'] as String;
                final String detail = item['detail'] as String;
                final String note = (item['note'] ?? '') as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: isDone ? Colors.grey.shade100 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDone
                          ? Colors.grey.shade300
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isDone,
                        activeColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onChanged: (_) => _toggleWorkout(item['id'] as String),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDone ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryBgColor(category),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(category),
                                  size: 14,
                                  color: _getCategoryColor(category),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getCategoryColor(category),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.repeat,
                                  size: 15,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  detail,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (note.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.notes,
                                    size: 15,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    note,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteWorkout(item['id'] as String),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
