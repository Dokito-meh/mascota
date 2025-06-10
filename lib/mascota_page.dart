import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';

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

class _MascotaPageState extends State<MascotaPage> with TickerProviderStateMixin {
  // Estado de la mascota
  double _hambre = 1.0; // 100%
  double _carino = 1.0; // 100%
  bool _estaFeliz = false;
  bool _estaComiendo = false;
  Timer? _timerHambre;
  Timer? _timerCarinoPerdida;
  Timer? _timerCarinoGanancia;
  Timer? _timerComiendo;
  
  // Animaciones
  AnimationController? _saltarController;
  Animation<double>? _saltarAnimacion;
  bool _estaSaltando = false;
  
  // Animación de monedas
  AnimationController? _monedaController;
  Animation<double>? _monedaAnimacion;
  bool _mostrarMoneda = false;

  @override
  void initState() {
    super.initState();
    _iniciarTimerHambre();
    _iniciarTimerCarinoPerdida();
    
    _saltarController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _saltarAnimacion = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _saltarController!, curve: Curves.easeInOut),
    );

    _monedaController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _monedaAnimacion = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(parent: _monedaController!, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _timerHambre?.cancel();
    _timerCarinoPerdida?.cancel();
    _timerCarinoGanancia?.cancel();
    _timerComiendo?.cancel();
    _saltarController?.dispose();
    _monedaController?.dispose();
    super.dispose();
  }

  void _iniciarTimerHambre() {
    _timerHambre = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        _hambre = (_hambre - 0.01).clamp(0.0, 1.0);
      });
    });
  }

  void _iniciarTimerCarinoPerdida() {
    _timerCarinoPerdida = Timer.periodic(const Duration(seconds: 30), (timer) {
      setState(() {
        _carino = (_carino - 0.02).clamp(0.0, 1.0);
      });
    });
  }

  void _hacerSaltar() {
    if (!_estaSaltando && _estaFeliz && _saltarController != null) {
      _estaSaltando = true;
      _saltarController!.forward().then((_) {
        _saltarController!.reverse().then((_) {
          _estaSaltando = false;
        });
      });
    }
  }

  void _mostrarAnimacionMoneda() {
    setState(() {
      _mostrarMoneda = true;
    });
    _monedaController!.forward().then((_) {
      setState(() {
        _mostrarMoneda = false;
      });
      _monedaController!.reset();
    });
  }

  void _alimentarMascota() {
    setState(() {
      _hambre = (_hambre + 0.2).clamp(0.0, 1.0);
    });
  }

  void _iniciarCaricia() {
    setState(() {
      _estaFeliz = true;
    });
    
    _timerCarinoGanancia = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _carino = (_carino + 0.05).clamp(0.0, 1.0);
        // Solo dar monedas si el cariño no está al 100%
        if (_carino < 1.0) {
          widget.onMonedasChanged(widget.monedas + 1);
          _mostrarAnimacionMoneda();
        }
      });
    });
  }

  void _terminarCaricia() {
    setState(() {
      _estaFeliz = false;
    });
    _timerCarinoGanancia?.cancel();
    _timerCarinoGanancia = null;
  }

  void _alimentarConComida(ComidaItem comida) {
    setState(() {
      _estaComiendo = true;
      _hambre = (_hambre + 0.3).clamp(0.0, 1.0);
    });
    
    widget.onComidaUsada(comida);
    
    _timerComiendo = Timer(const Duration(seconds: 2), () {
      setState(() {
        _estaComiendo = false;
      });
    });
  }

  String _obtenerImagenMascota() {
    if (_estaComiendo) {
      return 'assets/images/mascota_comiendo.png';
    } else if (_estaFeliz) {
      return 'assets/images/mascota_feliz.png';
    } else {
      return 'assets/images/mascota.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Mi Mascota: Fluffy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.horaActual,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset(
                  'assets/images/moneda.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.monedas}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple, Colors.pink],
            stops: [0.0, 0.3],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          margin: const EdgeInsets.only(top: 80),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),

                      // Área de toque con animación de moneda
                      if (widget.mascotaDurmiendo || widget.esHoraDormir)
                        // Mensaje cuando la mascota está durmiendo
                        Container(
                          width: 250,
                          height: 250,
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.blue.withOpacity(0.1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bedtime,
                                size: 80,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.mascotaDurmiendo 
                                    ? '😴 Fluffy está durmiendo...'
                                    : '😪 Fluffy tiene sueño...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.mascotaDurmiendo
                                    ? 'Está descansando en su dormitorio'
                                    : 'Ve a la pestaña "Dormir"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Mascota normal cuando no está durmiendo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            GestureDetector(
                              onPanStart: (details) => _iniciarCaricia(),
                              onPanUpdate: (details) => _hacerSaltar(),
                              onPanEnd: (details) => _terminarCaricia(),
                              onTapDown: (details) => _iniciarCaricia(),
                              onTapUp: (details) => _terminarCaricia(),
                              onTapCancel: () => _terminarCaricia(),
                              child: DragTarget<ComidaItem>(
                                onAccept: (comida) => _alimentarConComida(comida),
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    width: 250,
                                    height: 250,
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: candidateData.isNotEmpty 
                                          ? Colors.green.withOpacity(0.3) 
                                          : Colors.transparent,
                                    ),
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(17),
                                        child: AnimatedBuilder(
                                          animation: _saltarAnimacion ?? const AlwaysStoppedAnimation(0),
                                          builder: (context, child) {
                                            return Transform.translate(
                                              offset: Offset(0, _saltarAnimacion?.value ?? 0),
                                              child: Image.asset(
                                                _obtenerImagenMascota(),
                                                fit: BoxFit.cover,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            // Animación de moneda
                            if (_mostrarMoneda)
                              AnimatedBuilder(
                                animation: _monedaAnimacion!,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _monedaAnimacion!.value),
                                    child: Opacity(
                                      opacity: 1 - _monedaController!.value,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.asset(
                                            'assets/images/moneda.png',
                                            width: 30,
                                            height: 30,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            '+1',
                                            style: TextStyle(
                                              color: Colors.yellow,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),

                      const SizedBox(height: 40),

                      // Barras de estado
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.restaurant, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Text('Hambre:', style: TextStyle(fontSize: 16)),
                                  const Spacer(),
                                  Text('${(_hambre * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _hambre,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.favorite, color: Colors.pink),
                                  const SizedBox(width: 8),
                                  const Text('Cariño:', style: TextStyle(fontSize: 16)),
                                  const Spacer(),
                                  Text('${(_carino * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _carino,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Center(
                        child: ElevatedButton.icon(
                          onPressed: _alimentarMascota,
                          icon: const Icon(Icons.restaurant, color: Colors.white),
                          label: const Text(
                            'Alimentar',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Inventario de comida en la parte inferior
              if (widget.inventario.isNotEmpty)
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.inventario.length,
                    itemBuilder: (context, index) {
                      final comida = widget.inventario[index];
                      return Draggable<ComidaItem>(
                        data: comida,
                        feedback: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(comida.imagen, fit: BoxFit.contain),
                        ),
                        childWhenDragging: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Container(
                          width: 60,
                          height: 60,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Image.asset(comida.imagen, fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}