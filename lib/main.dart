import 'dart:async';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'models.dart';
import 'mascota_page.dart';
import 'tienda_page.dart';
import 'dormir_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  // Ping de prueba a Firestore (puedes quitarlo luego)
  await FirebaseFirestore.instance.collection('diagnostics').doc('ping').set(
    {
      'lastPing': FieldValue.serverTimestamp(),
      'uid': auth.currentUser?.uid,
      'origin': 'flutter',
    },
    SetOptions(merge: true),
  );

  // Timezone Chile
  tz.initializeTimeZones();
  final chile = tz.getLocation('America/Santiago');

  runApp(MascotaVirtualApp(chileLocation: chile));
}

class MascotaVirtualApp extends StatelessWidget {
  final tz.Location chileLocation;
  const MascotaVirtualApp({super.key, required this.chileLocation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mascota Virtual',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          primary: Colors.pink,
        ),
        useMaterial3: true,
      ),
      home: HomeShell(chileLocation: chileLocation),
    );
  }
}

class HomeShell extends StatefulWidget {
  final tz.Location chileLocation;
  const HomeShell({super.key, required this.chileLocation});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Estado global simple de la app
  int _monedas = 500; // monedas iniciales
  final List<ComidaItem> _inventario = [];
  bool _mascotaDurmiendo = false;

  // Hora Chile
  late Timer _horaTimer;
  String _horaActual = '--:--';

  @override
  void initState() {
    super.initState();
    _actualizarHora(); // set inicial
    _horaTimer = Timer.periodic(const Duration(minutes: 1), (_) => _actualizarHora());
  }

  @override
  void dispose() {
    _horaTimer.cancel();
    super.dispose();
  }

  void _actualizarHora() {
    final nowChile = tz.TZDateTime.now(widget.chileLocation);
    final h = nowChile.hour.toString().padLeft(2, '0');
    final m = nowChile.minute.toString().padLeft(2, '0');
    setState(() => _horaActual = '$h:$m');
  }

  bool get _esHoraDormir {
    final nowChile = tz.TZDateTime.now(widget.chileLocation);
    final h = nowChile.hour;
    // De 22:00 a 07:59 se considera hora de dormir
    return (h >= 22 || h < 8);
  }

  // Callbacks compartidos
  void _onMonedasChanged(int v) => setState(() => _monedas = v);

  void _onComidaComprada(ComidaItem c) {
    setState(() => _inventario.add(c));
  }

  void _onComidaUsada(ComidaItem c) {
    // elimina la primera coincidencia (una unidad)
    final idx = _inventario.indexWhere((x) => x.nombre == c.nombre && x.imagen == c.imagen);
    if (idx != -1) {
      setState(() => _inventario.removeAt(idx));
    }
  }

  void _onMascotaDurmiendoChanged(bool v) {
    setState(() => _mascotaDurmiendo = v);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      MascotaPage(
        monedas: _monedas,
        onMonedasChanged: _onMonedasChanged,
        inventario: _inventario,
        onComidaUsada: _onComidaUsada,
        horaActual: _horaActual,
        mascotaDurmiendo: _mascotaDurmiendo,
        esHoraDormir: _esHoraDormir,
      ),
      TiendaPage(
        monedas: _monedas,
        onMonedasChanged: _onMonedasChanged,
        onComidaComprada: _onComidaComprada,
        horaActual: _horaActual,
      ),
      DormirPage(
        monedas: _monedas,
        onMonedasChanged: _onMonedasChanged,
        horaActual: _horaActual,
        mascotaDurmiendo: _mascotaDurmiendo,
        onMascotaDurmiendoChanged: _onMascotaDurmiendoChanged,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 64,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'Mascota'),
          NavigationDestination(icon: Icon(Icons.store_mall_directory), label: 'Tienda'),
          NavigationDestination(icon: Icon(Icons.nightlight_round), label: 'Dormir'),
        ],
        indicatorColor: Colors.pink.shade200.withOpacity(0.3),
      ),
    );
    // Nota: cada página incluye su propio Drawer (AppDrawer),
    // por eso aquí no lo repetimos.
  }
}
