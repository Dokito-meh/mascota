import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  bool musica = true;
  bool notificaciones = true;
  bool vibracion = true;
  bool modoAhorro = false;

  void _goHome() {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
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
        title: const Text('Configuración',
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
        children: [
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Música de fondo'),
            subtitle: const Text('Reproduce una pista en bucle'),
            value: musica,
            onChanged: (v) => setState(() => musica = v),
            secondary: const Icon(Icons.music_note),
          ),
          SwitchListTile(
            title: const Text('Notificaciones'),
            subtitle: const Text('Recordatorios diarios'),
            value: notificaciones,
            onChanged: (v) => setState(() => notificaciones = v),
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          SwitchListTile(
            title: const Text('Vibración'),
            value: vibracion,
            onChanged: (v) => setState(() => vibracion = v),
            secondary: const Icon(Icons.vibration),
          ),
          SwitchListTile(
            title: const Text('Modo ahorro'),
            subtitle: const Text('Reduce animaciones y consumo'),
            value: modoAhorro,
            onChanged: (v) => setState(() => modoAhorro = v),
            secondary: const Icon(Icons.battery_saver_outlined),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            subtitle: const Text('Mascota Virtual v1.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Mascota Virtual',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.pets),
                children: const [
                  Text('Proyecto de mascota virtual con Flutter.'),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: () {
              // TODO: persistir config si quieres
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Configuración guardada')),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ),
      ),
    );
  }
}
