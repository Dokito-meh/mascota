import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets/app_drawer.dart';

class MascotaPage extends StatefulWidget {
  final int monedas;
  final Function(int) onMonedasChanged;
  final List<ComidaItem> inventario;
  final Function(ComidaItem) onComidaUsada;
  final String horaActual;
  final bool mascotaDurmiendo;
  final bool esHoraDormir;

  const MascotaPage({
    super.key,
    required this.monedas,
    required this.onMonedasChanged,
    required this.inventario,
    required this.onComidaUsada,
    required this.horaActual,
    required this.mascotaDurmiendo,
    required this.esHoraDormir,
  });

  @override
  State<MascotaPage> createState() => _MascotaPageState();
}

class _MascotaPageState extends State<MascotaPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  // Estado
  double _hambre = 1.0, _carino = 1.0, _sueno = 1.0;
  bool _estaFeliz = false, _estaComiendo = false, _durmiendo = false;

  // Timers
  Timer? _timerHambre, _timerCarinoPerdida, _timerCarinoGanancia, _timerComiendo;
  Timer? _timerSuenoRecuperacion, _timerSuenoPerdida;
  int _cariciaSegAcumulados = 0;

  // Animaciones
  AnimationController? _saltarController;
  Animation<double>? _saltarAnimacion;
  bool _estaSaltando = false;

  AnimationController? _monedaController;
  Animation<double>? _monedaAnimacion;
  bool _mostrarMoneda = false;

  // Zzz al dormir
  late final AnimationController _zzzController;
  late final Animation<double> _zzzFade;
  late final Animation<Offset> _zzzSlide;

  // “oleaje” para los círculos líquidos
  double _waveBoost = 0.0; // amplitud extra al agitar
  Timer? _waveDecay;

  String _nombre = 'Fluffy';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _durmiendo = widget.mascotaDurmiendo;
    _durmiendo ? _iniciarRecuperacionSueno() : _iniciarPerdidaSueno();

    _iniciarTimerHambre();
    _iniciarTimerCarinoPerdida();

    _saltarController =
        AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _saltarAnimacion = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _saltarController!, curve: Curves.easeInOut),
    );

    _monedaController =
        AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _monedaAnimacion = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(parent: _monedaController!, curve: Curves.easeOut),
    );

    _zzzController =
        AnimationController(duration: const Duration(milliseconds: 1600), vsync: this);
    _zzzFade = CurvedAnimation(parent: _zzzController, curve: Curves.easeOut);
    _zzzSlide = Tween<Offset>(begin: const Offset(0.15, 0.1), end: const Offset(0.15, -0.25))
        .animate(CurvedAnimation(parent: _zzzController, curve: Curves.easeOut));
    if (_durmiendo) _zzzController.repeat();
  }

  @override
  void didUpdateWidget(covariant MascotaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mascotaDurmiendo != widget.mascotaDurmiendo) {
      _setDormir(widget.mascotaDurmiendo);
    }
  }

  @override
  void dispose() {
    _timerHambre?.cancel();
    _timerCarinoPerdida?.cancel();
    _timerCarinoGanancia?.cancel();
    _timerComiendo?.cancel();
    _timerSuenoRecuperacion?.cancel();
    _timerSuenoPerdida?.cancel();
    _saltarController?.dispose();
    _monedaController?.dispose();
    _zzzController.dispose();
    _waveDecay?.cancel();
    super.dispose();
  }

  // Timers
  void _iniciarTimerHambre() {
    _timerHambre = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _hambre = (_hambre - 0.01).clamp(0.0, 1.0));
    });
  }

  void _iniciarTimerCarinoPerdida() {
    _timerCarinoPerdida = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _carino = (_carino - 0.02).clamp(0.0, 1.0));
    });
  }

  void _iniciarRecuperacionSueno() {
    _timerSuenoRecuperacion?.cancel();
    _timerSuenoRecuperacion = Timer.periodic(const Duration(minutes: 3), (_) {
      setState(() => _sueno = (_sueno + 0.01).clamp(0.0, 1.0));
    });
  }

  void _iniciarPerdidaSueno() {
    _timerSuenoPerdida?.cancel();
    _timerSuenoPerdida = Timer.periodic(const Duration(minutes: 10), (_) {
      setState(() => _sueno = (_sueno - 0.01).clamp(0.0, 1.0));
    });
  }

  void _detenerRecuperacionSueno() => _timerSuenoRecuperacion?.cancel();
  void _detenerPerdidaSueno() => _timerSuenoPerdida?.cancel();

  // Interacciones
  void _hacerSaltar() {
    if (!_estaSaltando && _estaFeliz && _saltarController != null) {
      _estaSaltando = true;
      _saltarController!.forward().then((_) {
        _saltarController!.reverse().then((_) => _estaSaltando = false);
      });
    }
  }

  void _mostrarAnimacionMoneda() {
    setState(() => _mostrarMoneda = true);
    _monedaController!.forward().then((_) {
      setState(() => _mostrarMoneda = false);
      _monedaController!.reset();
    });
  }

  // Empuja las olas (más fuerte) y decae lentamente
  void _kickWaves([double add = 0.35]) {
    _waveDecay?.cancel();
    setState(() => _waveBoost = (_waveBoost + add).clamp(0.0, 1.6));
    _waveDecay = Timer.periodic(const Duration(milliseconds: 50), (t) {
      if (!mounted) return;
      setState(() => _waveBoost = (_waveBoost - 0.05).clamp(0.0, 1.6));
      if (_waveBoost <= 0) t.cancel();
    });
  }

  // Reacciona al scroll para agitar el agua según velocidad
  bool _onScrollNotify(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final delta = (n.scrollDelta ?? 0).abs();
      if (delta > 0) _kickWaves((delta / 18.0).clamp(0.15, 0.6));
    } else if (n is UserScrollNotification) {
      _kickWaves(0.2);
    }
    return false;
  }

  void _iniciarCaricia() {
    if (_durmiendo) return;
    setState(() => _estaFeliz = true);
    _kickWaves();
    _timerCarinoGanancia?.cancel();
    _timerCarinoGanancia = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _carino = (_carino + 0.05).clamp(0.0, 1.0);
        if (_carino < 1.0) {
          widget.onMonedasChanged(widget.monedas + 1);
          _mostrarAnimacionMoneda();
        }
        _cariciaSegAcumulados += 3;
        if (_cariciaSegAcumulados >= 10) {
          final n = _cariciaSegAcumulados ~/ 10;
          _cariciaSegAcumulados %= 10;
          _sueno = (_sueno - 0.01 * n).clamp(0.0, 1.0);
        }
      });
    });
  }

  void _terminarCaricia() {
    if (_durmiendo) return;
    setState(() => _estaFeliz = false);
    _timerCarinoGanancia?.cancel();
    _timerCarinoGanancia = null;
    _cariciaSegAcumulados = 0;
  }

  int _curaHambreDe(ComidaItem c) {
    switch (c.nombre) {
      case 'Sushi':
        return 15;
      case 'Completo':
        return 20;
      case 'Pizza':
        return 25;
      case 'Milcao':
        return 18;
      case 'Mote con Huesillo':
        return 10;
      default:
        return 15;
    }
  }

  void _alimentarConComida(ComidaItem comida) {
    if (_durmiendo) return;
    final curaPct = _curaHambreDe(comida);
    setState(() {
      _estaComiendo = true;
      _hambre = (_hambre + (curaPct / 100)).clamp(0.0, 1.0);
    });
    widget.onComidaUsada(comida);
    _timerComiendo?.cancel();
    _timerComiendo = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _estaComiendo = false);
    });
  }

  void _toggleDormir() => _setDormir(!_durmiendo);

  void _setDormir(bool dormir) {
    setState(() => _durmiendo = dormir);
    if (_durmiendo) {
      _estaFeliz = false;
      _timerCarinoGanancia?.cancel();
      _detenerPerdidaSueno();
      _iniciarRecuperacionSueno();
      _zzzController.repeat();
    } else {
      _detenerRecuperacionSueno();
      _iniciarPerdidaSueno();
      _zzzController.stop();
      _zzzController.reset();
    }
  }

  String _obtenerImagenMascota() {
    if (_durmiendo) return 'assets/images/mascota_durmiendo.png';
    if (_estaComiendo) return 'assets/images/mascota_comiendo.png';
    if (_estaFeliz) return 'assets/images/mascota_feliz.png';
    return 'assets/images/mascota.png';
  }

  Future<void> _editarNombre() async {
    final controller = TextEditingController(text: _nombre);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre de tu mascota'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) Navigator.pop(context, t);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (nuevo != null && mounted) setState(() => _nombre = nuevo);
  }

  void _abrirMensajeria() {
    final mensajes = [
      'Oye, llevo días viendo a $_nombre más inquieto de lo normal. ¿Probaste cambiarle la rutina de juego? Podemos coordinar para pasearlo por la tarde y que queme energía.',
      'Ayer noté que $_nombre comió muy rápido. Quizá podríamos repartirle la comida en porciones pequeñas durante el día para que no le caiga pesado.',
      'Si te interesa, estuve leyendo sobre entrenamiento positivo. Puedo ayudarte a enseñarle un truco nuevo a $_nombre el fin de semana.',
      'Cuando lo vi, me pareció que $_nombre estaba un poco somnoliento. Tal vez necesita una siesta corta después de almorzar. ¿Qué opinas?',
      'Estuve probando snacks caseros sanos. Si quieres, te paso la receta y vemos si a $_nombre le gusta.',
      '¿Te tinca que salgamos al parque nuevo? Tiene zonas tranquilas para que $_nombre explore sin estresarse.',
    ];

    final selectedIndex = ValueNotifier<int?>(null);
    final respCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mensajes de tu amigo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Cards seleccionables
              ValueListenableBuilder<int?>(
                valueListenable: selectedIndex,
                builder: (ctx, sel, _) {
                  return Column(
                    children: List.generate(mensajes.length, (i) {
                      final seleccionado = sel == i;
                      return GestureDetector(
                        onTap: () => selectedIndex.value = i,
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.pink,
                              width: seleccionado ? 3 : 1,
                            ),
                          ),
                          child: Text(
                            mensajes[i],
                            style: TextStyle(
                              fontWeight:
                                  seleccionado ? FontWeight.w700 : FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),

              const SizedBox(height: 10),
              TextField(
                controller: respCtrl,
                decoration: const InputDecoration(
                  labelText: 'Responder…',
                  border: OutlineInputBorder(),
                ),
                minLines: 1,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Respuesta enviada')),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Enviar'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final moonBg = _durmiendo ? Colors.black87 : Colors.white;
    final moonIcon = _durmiendo ? Colors.white : Colors.grey[700];

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(nombreMascota: _nombre, monedas: widget.monedas),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menú',
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _nombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _editarNombre,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(Icons.edit, size: 18, color: Colors.black54),
              ),
            ),
          ],
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

      // Detectamos scrolls para "agitar" el agua
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotify,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 44), // círculos un poco más abajo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LiquidCircle(
                      value: _hambre,
                      color: Colors.orange,
                      icon: Icons.restaurant,
                      waveBoost: _waveBoost,
                      label: 'Hambre',
                    ),
                    const SizedBox(width: 26),
                    LiquidCircle(
                      value: _carino,
                      color: Colors.pink,
                      icon: Icons.favorite,
                      waveBoost: _waveBoost,
                      label: 'Cariño',
                    ),
                    const SizedBox(width: 26),
                    LiquidCircle(
                      value: _sueno,
                      color: Colors.indigo,
                      icon: Icons.bedtime,
                      waveBoost: _waveBoost,
                      label: 'Sueño',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Imagen + interacción (área más amplia sin interferir con el swipe del PageView)
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_durmiendo)
                          Positioned(
                            top: 60,
                            right: MediaQuery.of(context).size.width * 0.32,
                            child: FadeTransition(
                              opacity: _zzzFade,
                              child: SlideTransition(
                                position: _zzzSlide,
                                child: const Text(
                                  'Zzz…',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // 👉 El área de la mascota captura drags horizontales/verticales
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragStart: (_) { _iniciarCaricia(); _kickWaves(); },
                          onHorizontalDragUpdate: (_) => _hacerSaltar(),
                          onHorizontalDragEnd: (_) => _terminarCaricia(),
                          onVerticalDragStart: (_) { _iniciarCaricia(); _kickWaves(); },
                          onVerticalDragUpdate: (_) => _hacerSaltar(),
                          onVerticalDragEnd: (_) => _terminarCaricia(),
                          onTapDown: (_) => _iniciarCaricia(),
                          onTapUp: (_) => _terminarCaricia(),
                          onTapCancel: () => _terminarCaricia(),
                          child: DragTarget<ComidaItem>(
                            onAccept: (c) => _alimentarConComida(c),
                            builder: (context, candidate, rejected) {
                              return Container(
                                width: 340,
                                height: 340,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: !_durmiendo && candidate.isNotEmpty
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                                alignment: Alignment.center,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(17),
                                  child: AnimatedBuilder(
                                    animation:
                                        _saltarAnimacion ?? const AlwaysStoppedAnimation(0),
                                    builder: (_, __) => Transform.translate(
                                      offset: Offset(0, _saltarAnimacion?.value ?? 0),
                                      child: Image.asset(
                                        _obtenerImagenMascota(),
                                        fit: BoxFit.contain,
                                        width: 320,
                                        height: 320,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        if (_mostrarMoneda)
                          AnimatedBuilder(
                            animation: _monedaAnimacion!,
                            builder: (_, __) => Transform.translate(
                              offset: Offset(0, _monedaAnimacion!.value),
                              child: Opacity(
                                opacity: 1 - _monedaController!.value,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset('assets/images/moneda.png',
                                        width: 30, height: 30),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '+1',
                                      style: TextStyle(
                                          color: Colors.yellow,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Inventario (banda gris siempre visible, sin mensaje cuando está vacío) ──
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: widget.inventario.isEmpty
                      ? null // sin contenido cuando no hay comida
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.inventario.length,
                          itemBuilder: (context, index) {
                            final comida = widget.inventario[index];
                            return Draggable<ComidaItem>(
                              data: comida,
                              feedback: Image.asset(
                                comida.imagen,
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                              ),
                              childWhenDragging: const SizedBox(width: 56, height: 56),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index == widget.inventario.length - 1 ? 0 : 10,
                                ),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Image.asset(
                                    comida.imagen, // PNG puro (sin fondo)
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // FABs más arriba para no tapar la barra
            Positioned(
              right: 16,
              bottom: 120,
              child: FloatingActionButton(
                onPressed: _toggleDormir,
                backgroundColor: moonBg,
                elevation: 6,
                shape: const CircleBorder(),
                child: Icon(Icons.nightlight_round, color: moonIcon),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 120,
              child: FloatingActionButton(
                onPressed: _abrirMensajeria,
                backgroundColor: Colors.white,
                elevation: 6,
                shape: const CircleBorder(),
                child: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Círculo con “líquido” animado.
/// - value: 0..1
/// - waveBoost: 0..1.6, incrementa momentáneamente la amplitud (se atenúa sola)
class LiquidCircle extends StatefulWidget {
  final double value;
  final Color color;
  final IconData icon;
  final double waveBoost;
  final String label;

  const LiquidCircle({
    super.key,
    required this.value,
    required this.color,
    required this.icon,
    required this.waveBoost,
    required this.label,
  });

  @override
  State<LiquidCircle> createState() => _LiquidCircleState();
}

class _LiquidCircleState extends State<LiquidCircle> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.value * 100).clamp(0, 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 62,
          height: 62,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => CustomPaint(
              painter: _LiquidPainter(
                progress: widget.value,
                color: widget.color,
                phase: _ctrl.value * 2 * math.pi,
                boost: widget.waveBoost,
              ),
              child: Center(child: Icon(widget.icon, size: 18, color: widget.color)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('$percent%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
        Text(widget.label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final double phase;
  final double boost;

  _LiquidPainter({
    required this.progress,
    required this.color,
    required this.phase,
    required this.boost,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    // Clip en círculo
    final circle = Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    // Fondo
    final bg = Paint()..color = Colors.grey.shade200;
    canvas.drawCircle(center, radius, bg);

    // Nivel (0 abajo, 1 arriba)
    final level = (1 - progress) * size.height;

    // Amplitud más exagerada
    final amp = 8.0 + 20.0 * math.min(boost, 1.0); // base + boost fuerte
    final k = 2 * math.pi / size.width; // frecuencia

    // Onda principal
    final wave = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = level + amp * math.sin(k * x + phase);
      wave.lineTo(x, y);
    }
    wave
      ..lineTo(size.width, size.height)
      ..close();

    final fill = Paint()..color = color.withOpacity(0.25);
    final fillDark = Paint()..color = color.withOpacity(0.35);

    // Recortar al círculo y pintar
    canvas.save();
    canvas.clipPath(circle);
    canvas.drawPath(wave, fill);

    // Segunda onda más notoria y desfasada
    final wave2 = Path();
    for (double x = 0; x <= size.width; x++) {
      final y = level + amp * 0.9 * math.sin(k * x + phase + math.pi / 2);
      if (x == 0) {
        wave2.moveTo(x, y);
      } else {
        wave2.lineTo(x, y);
      }
    }
    wave2
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave2, fillDark);

    canvas.restore();

    // Borde
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = color;
    canvas.drawCircle(center, radius, border);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) =>
      old.progress != progress || old.phase != phase || old.boost != boost || old.color != color;
}

// Helper por si no tienes importado dart:ui
double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}
