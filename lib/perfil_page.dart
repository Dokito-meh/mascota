import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/app_drawer.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  String nombre = 'Fluffy';
  final TextEditingController _ctrl = TextEditingController(text: 'Fluffy');

  String? _avatarPath; // imagen elegida por el usuario
  final _picker = ImagePicker();

  // Logros de ejemplo
  final _achievements = <_Achvm>[
    _Achvm('Días jugando', Icons.calendar_month, 0.62),
    _Achvm('Caricias dadas', Icons.favorite, 0.45),
    _Achvm('Comidas servidas', Icons.restaurant, 0.8),
    _Achvm('Horas de sueño', Icons.bedtime, 0.3),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (img != null && mounted) {
      setState(() => _avatarPath = img.path);
      // TODO: persistir ruta si quieres mantenerla entre sesiones (shared_preferences)
    }
  }

  void _goHome() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Widget _avatarWidget() {
    final double r = 60;
    if (_avatarPath != null && File(_avatarPath!).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(_avatarPath!),
          width: r * 2,
          height: r * 2,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipOval(
      child: Image.asset(
        'assets/images/mascota.png',
        width: r * 2,
        height: r * 2,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(nombreMascota: nombre, monedas: 0, avatarPath: _avatarPath),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Perfil',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Inicio',
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: _goHome,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                _avatarWidget(),
                FloatingActionButton.small(
                  heroTag: 'editAvatar',
                  onPressed: _pickAvatar, // ← abre galería
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.edit, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              nombre,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: 'Nombre de tu mascota',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () {
                  final t = _ctrl.text.trim();
                  if (t.isNotEmpty) {
                    setState(() => nombre = t);
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nombre actualizado')),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logros con iconos y barras
          const Text('Logros', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          ..._achievements.map((a) => _AchievementTile(a)).toList(),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.emoji_events_outlined),
            label: const Text('Ver más logros (próximamente)'),
          ),
        ],
      ),
    );
  }
}

class _Achvm {
  final String title;
  final IconData icon;
  final double progress; // 0..1
  _Achvm(this.title, this.icon, this.progress);
}

class _AchievementTile extends StatelessWidget {
  final _Achvm data;
  const _AchievementTile(this.data);

  @override
  Widget build(BuildContext context) {
    final p = (data.progress * 100).round();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.pink.shade50,
              child: Icon(data.icon, color: Colors.pink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: data.progress.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$p%', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
