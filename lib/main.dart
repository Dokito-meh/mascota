import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'mascota_page.dart';
import 'tienda_page.dart';
import 'dormir_page.dart';

void main() {
  runApp(const MascotaVirtualApp());
}

class MascotaVirtualApp extends StatelessWidget {
  const MascotaVirtualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Mascota Virtual',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Navegador principal con pestañas y scroll lateral
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  int _monedas = 50;
  List<ComidaItem> _inventario = [];
  late PageController _pageController;
  
  // Sistema de tiempo y sueño
  DateTime _horaActual = DateTime.now();
  Timer? _timerHora;
  bool _mascotaDurmiendo = false;
  bool _esHoraDormir = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _iniciarTimerHora();
    _verificarHoraDormir();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timerHora?.cancel();
    super.dispose();
  }

  void _iniciarTimerHora() {
    _timerHora = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _horaActual = DateTime.now();
      });
      _verificarHoraDormir();
    });
  }

  void _verificarHoraDormir() {
    final hora = _horaActual.hour;
    final nuevaEsHoraDormir = hora >= 22 || hora < 6;
    
    if (nuevaEsHoraDormir != _esHoraDormir) {
      setState(() {
        _esHoraDormir = nuevaEsHoraDormir;
        
        if (_esHoraDormir && !_mascotaDurmiendo) {
          // Es hora de dormir, cambiar automáticamente a vista de dormir
          _mascotaDurmiendo = true;
          _onBottomNavTapped(2); // Ir a pestaña de dormir
        } else if (!_esHoraDormir && _mascotaDurmiendo) {
          // Es hora de despertar, volver a vista principal
          _mascotaDurmiendo = false;
          _onBottomNavTapped(0); // Ir a pestaña principal
        }
      });
    }
  }

  String _formatearHora() {
    final hora = _horaActual.hour.toString().padLeft(2, '0');
    final minuto = _horaActual.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  void _actualizarMonedas(int nuevasMonedas) {
    setState(() {
      _monedas = nuevasMonedas;
    });
  }

  void _agregarComida(ComidaItem comida) {
    setState(() {
      _inventario.add(comida);
    });
  }

  void _removerComida(ComidaItem comida) {
    setState(() {
      _inventario.remove(comida);
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          MascotaPage(
            monedas: _monedas,
            onMonedasChanged: _actualizarMonedas,
            inventario: _inventario,
            onComidaUsada: _removerComida,
            horaActual: _formatearHora(),
            mascotaDurmiendo: _mascotaDurmiendo,
            esHoraDormir: _esHoraDormir,
          ),
          TiendaPage(
            monedas: _monedas,
            onMonedasChanged: _actualizarMonedas,
            onComidaComprada: _agregarComida,
            horaActual: _formatearHora(),
          ),
          DormirPage(
            monedas: _monedas,
            onMonedasChanged: _actualizarMonedas,
            horaActual: _formatearHora(),
            mascotaDurmiendo: _mascotaDurmiendo,
            onMascotaDurmiendoChanged: (durmiendo) {
              setState(() {
                _mascotaDurmiendo = durmiendo;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.purple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Mascota',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Tienda',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.bedtime),
                if (_esHoraDormir)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Dormir',
          ),
        ],
      ),
    );
  }
}