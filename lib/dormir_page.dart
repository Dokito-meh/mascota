import 'package:flutter/material.dart';
import 'dart:async';
import 'widgets/app_drawer.dart';

class DormirPage extends StatefulWidget {
  final int monedas;
  final Function(int) onMonedasChanged;
  final String horaActual;
  final bool mascotaDurmiendo;
  final Function(bool) onMascotaDurmiendoChanged;

  const DormirPage({
    super.key,
    required this.monedas,
    required this.onMonedasChanged,
    required this.horaActual,
    required this.mascotaDurmiendo,
    required this.onMascotaDurmiendoChanged,
  });

  @override
  State<DormirPage> createState() => _DormirPageState();
}

class _DormirPageState extends State<DormirPage> with TickerProviderStateMixin {
  bool _estaDurmiendo = false;
  double _energia = 1.0;

  // Timers
  Timer? _timerRecupera;     // + energía mientras duerme
  Timer? _timerPierde;       // - energía mientras despierta
  Timer? _timerContador;     // cronómetro de sueño
  int _segundosDurmiendo = 0;

  // Animaciones suaves
  AnimationController? _respController;
  Animation<double>? _respAnim;

  // “Zzz…”
  AnimationController? _zzController;
  Animation<double>? _zzFade;
  Animation<Offset>? _zzSlide;

  @override
  void initState() {
    super.initState();
    _estaDurmiendo = widget.mascotaDurmiendo;

    // Respiración de la mascota (levemente)
    _respController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..addStatusListener((st) {
        if (st == AnimationStatus.completed) _respController!.reverse();
        if (st == AnimationStatus.dismissed) _respController!.forward();
      });
    _respAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(parent: _respController!, curve: Curves.easeInOut),
    );

    // Zzz…
    _zzController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _zzFade = CurvedAnimation(parent: _zzController!, curve: Curves.easeOut);
    _zzSlide = Tween<Offset>(begin: const Offset(0.12, 0.08), end: const Offset(0.12, -0.22))
        .animate(CurvedAnimation(parent: _zzController!, curve: Curves.easeOut));

    // Timers iniciales
    if (_estaDurmiendo) {
      _respController!.forward();
      _zzController!.repeat();
      _iniciarRecuperacion();
    } else {
      _iniciarPerdida();
    }
  }

  @override
  void didUpdateWidget(covariant DormirPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mascotaDurmiendo != widget.mascotaDurmiendo) {
      _setDurmiendo(widget.mascotaDurmiendo);
    }
  }

  @override
  void dispose() {
    _timerRecupera?.cancel();
    _timerPierde?.cancel();
    _timerContador?.cancel();
    _respController?.dispose();
    _zzController?.dispose();
    super.dispose();
  }

  // ---- Timers ----
  void _iniciarRecuperacion() {
    _timerRecupera?.cancel();
    _timerPierde?.cancel();
    _timerContador?.cancel();

    _timerRecupera = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() => _energia = (_energia + 0.05).clamp(0.0, 1.0));
      // Bonus: cada 15 s durmiendo, +2 monedas
      if (_segundosDurmiendo > 0 && _segundosDurmiendo % 15 == 0) {
        widget.onMonedasChanged(widget.monedas + 2);
      }
    });

    _timerContador = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _segundosDurmiendo++);
    });
  }

  void _iniciarPerdida() {
    _timerRecupera?.cancel();
    _timerPierde?.cancel();
    _timerContador?.cancel();
    _segundosDurmiendo = 0;

    // Pierde energía gradual cuando está despierta
    _timerPierde = Timer.periodic(const Duration(minutes: 10), (_) {
      setState(() => _energia = (_energia - 0.01).clamp(0.0, 1.0));
    });
  }

  // ---- Estado dormir/despertar ----
  void _setDurmiendo(bool dormir) {
    setState(() => _estaDurmiendo = dormir);

    if (_estaDurmiendo) {
      widget.onMascotaDurmiendoChanged(true);
      _respController?.forward();
      _zzController?.repeat();
      _iniciarRecuperacion();
    } else {
      widget.onMascotaDurmiendoChanged(false);
      _respController?.stop();
      _zzController?.stop();
      _zzController?.reset();
      _iniciarPerdida();
    }
  }

  void _toggleDormir() => _setDurmiendo(!_estaDurmiendo);

  String _imgMascota() =>
      _estaDurmiendo ? 'assets/images/mascota_durmiendo.png' : 'assets/images/mascota.png';

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final awakeOverlay = [
      Colors.pink.shade100.withOpacity(0.35),
      Colors.pink.shade200.withOpacity(0.45),
    ];
    final sleepOverlay = [
      Colors.black.withOpacity(0.55),
      Colors.black.withOpacity(0.75),
    ];

    return Scaffold(
      drawer: AppDrawer(monedas: widget.monedas),
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
        title: const Text(
          'Dormitorio',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.black87, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.horaActual,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset('assets/images/moneda.png', width: 20, height: 20),
                const SizedBox(width: 4),
                Text(
                  '${widget.monedas}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          // Fondo del dormitorio
          Positioned.fill(
            child: Image.asset(
              'assets/images/dormitorio_fondo.png',
              fit: BoxFit.cover,
            ),
          ),

          // Overlay (rosa/oscuro)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _estaDurmiendo ? sleepOverlay : awakeOverlay,
                ),
              ),
            ),
          ),

          // Contenido
          Column(
            children: [
              const SizedBox(height: 20),
              // Cabecera de energía
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 0,
                  color: _estaDurmiendo ? Colors.black.withOpacity(.35) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bedtime, color: _estaDurmiendo ? Colors.white : Colors.pink),
                            const SizedBox(width: 8),
                            Text(
                              'Energía',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _estaDurmiendo ? Colors.white : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(_energia * 100).round()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _estaDurmiendo ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _energia,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(_estaDurmiendo ? .25 : .8),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _energia > .7 ? Colors.green : _energia > .3 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mascota
              Expanded(
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _respAnim ?? const AlwaysStoppedAnimation(0),
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _estaDurmiendo ? (_respAnim?.value ?? 0) : 0),
                          child: SizedBox(
                            width: 260,
                            height: 260,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(_imgMascota(), fit: BoxFit.contain),
                            ),
                          ),
                        ),
                      ),

                      // Zzz cuando duerme
                      if (_estaDurmiendo)
                        Positioned(
                          top: -10,
                          right: 30,
                          child: FadeTransition(
                            opacity: _zzFade!,
                            child: SlideTransition(
                              position: _zzSlide!,
                              child: const Text(
                                'Zzz…',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Cronómetro y botón
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    if (_estaDurmiendo && _segundosDurmiendo > 0)
                      Text(
                        'Durmiendo: ${_fmt(_segundosDurmiendo)}',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _estaDurmiendo ? Colors.black87 : Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: _toggleDormir,
                        icon: Icon(_estaDurmiendo ? Icons.wb_sunny_outlined : Icons.nightlight_round),
                        label: Text(_estaDurmiendo ? 'Despertar' : 'Dormir'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _estaDurmiendo
                          ? 'Recuperando energía… +5%/3s y +2 monedas/15s'
                          : 'Despierta: pierde 1% cada 10 minutos',
                      style: TextStyle(
                        color: _estaDurmiendo ? Colors.white70 : Colors.pink.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
