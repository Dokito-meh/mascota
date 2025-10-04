import 'dart:io';
import 'package:flutter/material.dart';
import '../perfil_page.dart';
import '../fondos_page.dart';
import '../config_page.dart';
import '../tienda_page.dart';
import '../dormir_page.dart';

class AppDrawer extends StatelessWidget {
  final String? nombreMascota;
  final int? monedas;
  final String? avatarPath; // opcional: si tienes una ruta de avatar elegida

  const AppDrawer({
    super.key,
    this.nombreMascota,
    this.monedas,
    this.avatarPath,
  });

  void _goHome(BuildContext context) {
    Navigator.of(context).pop(); // cierra drawer
    Navigator.of(context).popUntil((r) => r.isFirst); // vuelve a HomeShell/Mascota
  }

  @override
  Widget build(BuildContext context) {
    final nombre = nombreMascota ?? 'Fluffy';
    final coins = monedas ?? 0;

    Widget avatar() {
      final double r = 28;
      Widget img;
      if (avatarPath != null && avatarPath!.isNotEmpty && File(avatarPath!).existsSync()) {
        img = ClipOval(
          child: Image.file(
            File(avatarPath!),
            width: r * 2,
            height: r * 2,
            fit: BoxFit.cover,
          ),
        );
      } else {
        img = ClipOval(
          child: Image.asset(
            'assets/images/mascota.png',
            width: r * 2,
            height: r * 2,
            fit: BoxFit.contain,
          ),
        );
      }
      return SizedBox(width: r * 2, height: r * 2, child: img);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header claro, sin fondo rosa
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              leading: avatar(),
              title: Text(
                nombre,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              subtitle: Row(
                children: [
                  Image.asset('assets/images/moneda.png', width: 18, height: 18),
                  const SizedBox(width: 6),
                  Text('$coins', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              trailing: IconButton(
                tooltip: 'Ir a inicio',
                icon: const Icon(Icons.home_outlined),
                onPressed: () => _goHome(context),
              ),
            ),
            const Divider(height: 1),

            // Navegación principal
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Mascota (Inicio)'),
              onTap: () => _goHome(context),
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Tienda'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => TiendaPage(
                  monedas: monedas ?? 0,
                  onMonedasChanged: (_) {},
                  onComidaComprada: (_) {},
                  horaActual: '--:--',
                )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Dormir'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => DormirPage(
                  monedas: monedas ?? 0,
                  onMonedasChanged: (_) {},
                  horaActual: '--:--',
                  mascotaDurmiendo: false,
                  onMascotaDurmiendoChanged: (_) {},
                )));
              },
            ),
            const Divider(),

            // Secciones
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PerfilPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper_outlined),
              title: const Text('Fondos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FondosPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionPage()));
              },
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('v1.0 • Mascota Virtual',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
