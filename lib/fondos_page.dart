import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';

class FondoOption {
  final String id;
  final String name;
  final Gradient? gradient;
  final Color? color;
  final String? imageAsset;

  const FondoOption({
    required this.id,
    required this.name,
    this.gradient,
    this.color,
    this.imageAsset,
  });
}

class FondosPage extends StatefulWidget {
  const FondosPage({super.key});

  @override
  State<FondosPage> createState() => _FondosPageState();
}

class _FondosPageState extends State<FondosPage> {
  final List<FondoOption> opciones = const [
    FondoOption(id: 'blanco', name: 'Blanco', color: Colors.white),
    FondoOption(id: 'rosa', name: 'Rosa suave', color: Color(0xfffde7ef)),
    FondoOption(
      id: 'grad_rosa',
      name: 'Degradado Rosa',
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xffff8fb1), Color(0xffffd6e3)],
      ),
    ),
    FondoOption(
      id: 'grad_magenta',
      name: 'Degradado Magenta',
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xffd63384), Color(0xffff8fab)],
      ),
    ),
    FondoOption(
      id: 'image_dormitorio',
      name: 'Dormitorio (imagen)',
      imageAsset: 'assets/images/dormitorio_fondo.png',
    ),
  ];

  String selectedId = 'blanco';

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
        title: const Text('Fondos',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Inicio',
            icon: const Icon(Icons.home_outlined, color: Colors.black87),
            onPressed: _goHome,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: opciones.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 1.1,
          ),
          itemBuilder: (context, i) {
            final f = opciones[i];
            final selected = selectedId == f.id;

            Widget preview;
            if (f.imageAsset != null) {
              preview = ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(f.imageAsset!, fit: BoxFit.cover),
              );
            } else if (f.gradient != null) {
              preview = Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: f.gradient,
                ),
              );
            } else {
              preview = Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: f.color,
                ),
              );
            }

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => selectedId = f.id),
              child: Stack(
                children: [
                  Positioned.fill(child: preview),
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? Colors.pink : Colors.black12,
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      child: Text(
                        f.name,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? Colors.pink : Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: FilledButton.icon(
            onPressed: () {
              // TODO: aplicar fondo global aquí (shared_preferences / estado global)
              // Luego volver automáticamente a la principal:
              _goHome();
            },
            icon: const Icon(Icons.check),
            label: const Text('Aplicar y volver a Inicio'),
          ),
        ),
      ),
    );
  }
}
