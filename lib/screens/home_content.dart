import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ai_service.dart';

class HomeContent extends StatefulWidget {
  final Function(int) onTabSelected;

  const HomeContent({super.key, required this.onTabSelected});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final List<Map<String, dynamic>> slideData = const [
    {
      'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop',
      'title': 'Sınırlarını Zorla!',
      'desc': 'Bugün dünden daha güçlüsün.',
    },
    {
      'image': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=1453&auto=format&fit=crop',
      'title': 'Sağlıklı Beslenme',
      'desc': 'Beslenmeni kontrol altına al.',
    },
    {
      'image': 'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?q=80&w=1470&auto=format&fit=crop',
      'title': 'Disiplin ve İstikrar',
      'desc': 'Kendi antrenman günlüğünü tut.',
    },
  ];

  // AI sunucusu yoğun olursa kullanılacak yedek sağlıklı yaşam görevleri
  final List<List<String>> _fallbackTaskSets = const [
    [
      'Gün boyunca en az 2.5 litre su iç',
      '15 dakika tempolu yürüyüş veya esneme yap',
      'Bugün paketli ve şekerli gıdalardan uzak dur',
    ],
    [
      'Her öğününe mutlaka bir porsiyon yeşillik ekle',
      'Asansör yerine merdivenleri kullan',
      'Uyumadan 1 saat önce ekran kullanımını bırak',
    ],
    [
      'Sabah güne 1 bardak ılık su ile başla',
      'Gün içinde 30 dakika kesintisiz hareket et',
      'Akşam yemeğini yatmadan en az 3 saat önce tamamla',
    ],
  ];

  List<Map<String, dynamic>> _dailyTasks = [];
  int _streakCount = 0;
  String _lastCompletedDate = '';
  String _prevCompletedDate = '';
  bool _isGeneratingTasks = false;

  @override
  void initState() {
    super.initState();
    _initDailyData();
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _getTodayStr() => _formatDate(DateTime.now());

  String _getYesterdayStr() =>
      _formatDate(DateTime.now().subtract(const Duration(days: 1)));

  Future<void> _initDailyData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayStr();
    final yesterday = _getYesterdayStr();

    int savedStreak = prefs.getInt('streak_count') ?? 0;
    String lastDone = prefs.getString('last_completed_date') ?? '';
    String prevDone = prefs.getString('prev_completed_date') ?? '';
    String tasksDate = prefs.getString('tasks_date') ?? '';
    String? savedTasksJson = prefs.getString('daily_tasks');

    // Eğer son tamamlama tarihi bugün veya dün değilse seri bozulmuştur
    if (lastDone != today && lastDone != yesterday) {
      savedStreak = 0;
      await prefs.setInt('streak_count', 0);
    }

    setState(() {
      _streakCount = savedStreak;
      _lastCompletedDate = lastDone;
      _prevCompletedDate = prevDone;
    });

    // Bugünün görevleri zaten kayıtlıysa yükle, yeni güne geçildiyse AI'dan yeni görev iste
    if (tasksDate == today && savedTasksJson != null) {
      final List<dynamic> decoded = jsonDecode(savedTasksJson);
      setState(() {
        _dailyTasks = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      await _generateAiTasks(isAutoInit: true);
    }
  }

  Future<void> _saveDailyState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('daily_tasks', jsonEncode(_dailyTasks));
    await prefs.setString('tasks_date', _getTodayStr());
    await prefs.setInt('streak_count', _streakCount);
    await prefs.setString('last_completed_date', _lastCompletedDate);
    await prefs.setString('prev_completed_date', _prevCompletedDate);
  }

  Future<void> _generateAiTasks({bool isAutoInit = false}) async {
    if (_isGeneratingTasks) return;

    setState(() {
      _isGeneratingTasks = true;
    });

    const prompt =
        'Bana bugün için sağlıklı yaşam, su tüketimi, hareket veya beslenme ile ilgili '
        '3 adet kısa ve uygulanabilir günlük görev ver. '
        'Sadece 3 görevi aralarına | işareti koyarak tek satırda yaz. '
        'Numara, madde işareti veya ekstra açıklama yazma. '
        'Örnek: 2.5 litre su iç|20 dakika tempolu yürüyüş yap|Şekerli içecek tüketme';

    final response = await AiService.askGemini(prompt);

    List<String> parsedTitles = [];
    final bool isErrorResponse =
        response.startsWith('Sunucu') ||
        response.startsWith('Bağlantı') ||
        response.startsWith('Yanıt');

    if (!isErrorResponse) {
      parsedTitles = response
          .split(RegExp(r'\||\n'))
          .map((e) => e.replaceAll(RegExp(r'^[\d\-\*\.\)\s]+'), '').trim())
          .where((e) => e.isNotEmpty)
          .take(3)
          .toList();
    }

    // AI yanıtı eksikse veya sunucu yoğunsa yedek listeden rastgele bir set seç
    if (parsedTitles.length < 3) {
      final randomSet =
          _fallbackTaskSets[Random().nextInt(_fallbackTaskSets.length)];
      parsedTitles = List<String>.from(randomSet);

      if (!isAutoInit && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI sunucusu yoğun olduğu için hazır sağlıklı görevler yüklendi.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() {
      _dailyTasks = parsedTitles
          .map((title) => {'title': title, 'isDone': false})
          .toList();
      _isGeneratingTasks = false;
    });

    await _saveDailyState();
  }

  Future<void> _toggleTask(int index) async {
    final today = _getTodayStr();
    final yesterday = _getYesterdayStr();

    setState(() {
      _dailyTasks[index]['isDone'] = !(_dailyTasks[index]['isDone'] as bool);
    });

    final bool allDone =
        _dailyTasks.isNotEmpty && _dailyTasks.every((t) => t['isDone'] == true);

    if (allDone && _lastCompletedDate != today) {
      setState(() {
        _prevCompletedDate = _lastCompletedDate;
        if (_lastCompletedDate == yesterday) {
          _streakCount += 1;
        } else {
          _streakCount = 1;
        }
        _lastCompletedDate = today;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade700,
            content: Text(
              '🔥 Tebrikler! Günlük görevlerin tamamlandı. Serin: $_streakCount Gün!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } else if (!allDone && _lastCompletedDate == today) {
      // Kullanıcı aynı gün içinde tiklerden birini geri alırsa seriyi eski haline döndür
      setState(() {
        _streakCount = _streakCount > 0 ? _streakCount - 1 : 0;
        _lastCompletedDate = _prevCompletedDate;
      });
    }

    await _saveDailyState();
  }

  @override
  Widget build(BuildContext context) {
    final int completedCount = _dailyTasks
        .where((t) => t['isDone'] == true)
        .length;
    final bool isStreakActive = _streakCount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SLIDER ALANI
          CarouselSlider(
            options: CarouselOptions(
              height: 220.0,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              autoPlayCurve: Curves.fastOutSlowIn,
              enableInfiniteScroll: true,
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
              viewportFraction: 0.85,
            ),
            items: slideData.map((item) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 5.0,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: NetworkImage(item['image']!),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.4),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 15),

          // GÜNLÜK AI GÖREVLER & STREAK KARTI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kart Üst Bilgisi: Başlık + Streak Rozeti + AI Yenile Butonu
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.blue,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Günlük Görevler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Streak Sayacı Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isStreakActive
                              ? Colors.orange.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isStreakActive
                                ? Colors.orange.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              size: 18,
                              color: isStreakActive
                                  ? Colors.deepOrange
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_streakCount Gün',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isStreakActive
                                    ? Colors.deepOrange.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Yeni AI Görevleri İste Butonu
                      IconButton(
                        tooltip: 'AI ile yeni görevler oluştur',
                        onPressed: _isGeneratingTasks
                            ? null
                            : () => _generateAiTasks(isAutoInit: false),
                        icon: _isGeneratingTasks
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh, color: Colors.blue),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'Bugün $completedCount / ${_dailyTasks.length} görev tamamlandı',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),

                  // Görev Listesi
                  if (_isGeneratingTasks && _dailyTasks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...List.generate(_dailyTasks.length, (index) {
                      final task = _dailyTasks[index];
                      final bool isDone = task['isDone'] as bool;

                      return InkWell(
                        onTap: () => _toggleTask(index),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.green.shade50
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDone
                                  ? Colors.green.shade200
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isDone
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isDone ? Colors.green : Colors.grey,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  task['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isDone
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isDone
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // HOŞGELDİN MESAJI VE HIZLI ERİŞİM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoş Geldin! 🚀',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'MyFitDay AI ile bugün hedeflerine bir adım daha yaklaş. '
                  'Sağ alttaki mavi yapay zeka butonuna tıklayarak asistanına hemen soru sorabilirsin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue.shade50,
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => widget.onTabSelected(
                            1,
                          ), // Kalori sekmesine (1. indeks) yönlendirir
                          child: const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Kalori',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Card(
                        color: Colors.green.shade50,
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => widget.onTabSelected(
                            2,
                          ), // Antrenman sekmesine (2. indeks) yönlendirir
                          child: const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  color: Colors.green,
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Antrenman',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
