import 'package:flutter/material.dart';

class CalorieContent extends StatefulWidget {
  const CalorieContent({super.key});

  @override
  State<CalorieContent> createState() => _CalorieContentState();
}

class _CalorieContentState extends State<CalorieContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _gender = 'Erkek';
  double _activityLevel = 1.2;
  double _result = 0;

  void _calculateCalories() {
    // Formdaki tüm alanlar doldurulmuş mu diye kontrol et
    if (_formKey.currentState!.validate()) {
      int age = int.parse(_ageController.text);
      double height = double.parse(_heightController.text);
      double weight = double.parse(_weightController.text);

      double bmr;
      // Harris-Benedict Formülü
      if (_gender == 'Erkek') {
        bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
      } else {
        bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
      }

      // Sonucu güncelle ve ekrana yansıt
      setState(() {
        _result = bmr * _activityLevel;
      });

      // Klavyeyi kapat
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kalori İhtiyacını Hesapla',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Cinsiyet Seçimi
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: InputDecoration(
                labelText: 'Cinsiyet',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              items: ['Erkek', 'Kadın'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) => setState(() => _gender = newValue!),
            ),
            const SizedBox(height: 15),

            // Yaş Girişi
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Yaş',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Lütfen yaşınızı girin' : null,
            ),
            const SizedBox(height: 15),

            // Boy ve Kilo (Yan Yana)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Boy (cm)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.height),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Boş bırakılamaz' : null,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Kilo (kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.monitor_weight),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Boş bırakılamaz' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Hareket Seviyesi
            DropdownButtonFormField<double>(
              value: _activityLevel,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Hareket Seviyesi',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.directions_run),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1.2,
                  child: Text('Masa başı (Hareketsiz)'),
                ),
                DropdownMenuItem(
                  value: 1.375,
                  child: Text('Hafif egzersiz (1-3 gün)'),
                ),
                DropdownMenuItem(
                  value: 1.55,
                  child: Text('Orta egzersiz (3-5 gün)'),
                ),
                DropdownMenuItem(
                  value: 1.725,
                  child: Text('Ağır egzersiz (6-7 gün)'),
                ),
              ],
              onChanged: (newValue) =>
                  setState(() => _activityLevel = newValue!),
            ),
            const SizedBox(height: 25),

            // Hesaplama Butonu
            ElevatedButton(
              onPressed: _calculateCalories,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hesapla',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 25),

            // Sonuç Gösterge Paneli (Sadece hesaplandıysa görünür)
            if (_result > 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Günlük Kalori İhtiyacınız',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_result.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
