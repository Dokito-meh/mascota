import 'package:flutter/material.dart';
import 'dart:async';

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
  Timer? _timerSueno;
  Timer? _timerEnergiaPerdida;
  
  AnimationController? _respiracionController;
  Animation<double>? _respiracionAnimacion;
  
  AnimationController? _zzController;
  Animation<double>? _zzAnimacion;
  
  int _tiempoSueno = 0;
  Timer? _timerTiempoSueno;

  @override
  void didUpdateWidget(DormirPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.mascotaDurmiendo != widget.mascotaDurmiendo) {
      setState(() {
        _estaDurmiendo = widget.mascotaDurmiendo;
      });
      
      if (widget.mascotaDurmiendo && _respiracionController != null && _zzController != null) {
        _respiracionController!.repeat(reverse: true);
        _zzController!.repeat(reverse: true);
        
        if (_timerSueno == null) {
          _timerSueno = Timer.periodic(const Duration(seconds: 3), (timer) {
            setState(() {
              _energia = (_energia + 0.05).clamp(0.0, 1.0);
              if (_tiempoSueno % 15 == 0 && _tiempoSueno > 0) {
                widget.onMonedasChanged(widget.monedas + 2);
              }
            });
          });
        }
        
        if (_timerTiempoSueno == null) {
          _timerTiempoSueno = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _tiempoSueno++;
            });
          });
        }
      } else if (!widget.mascotaDurmiendo && _respiracionController != null && _zzController != null) {
        _respiracionController!.stop();
        _zzController!.stop();
        _respiracionController!.reset();
        _zzController!.reset();
        
        _timerSueno?.cancel();
        _timerTiempoSueno?.cancel();
        _timerSueno = null;
        _timerTiempoSueno = null;
        
        setState(() {
          _tiempoSueno = 0;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _iniciarTimerEnergiaPerdida();
    
    _estaDurmiendo = widget.mascotaDurmiendo;
    
    _respiracionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _respiracionAnimacion = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _respiracionController!, curve: Curves.easeInOut),
    );
    
    _zzController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _zzAnimacion = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _zzController!, curve: Curves.easeInOut),
    );
    
    if (_estaDurmiendo) {
      _respiracionController!.repeat(reverse: true);
      _zzController!.repeat(reverse: true);
      
      _timerSueno = Timer.periodic(const Duration(seconds: 3), (timer) {
        setState(() {
          _energia = (_energia + 0.05).clamp(0.0, 1.0);
          if (_tiempoSueno % 15 == 0 && _tiempoSueno > 0) {
            widget.onMonedasChanged(widget.monedas + 2);
          }
        });
      });
      
      _timerTiempoSueno = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _tiempoSueno++;
        });
      });
    }
  }

  @override
  void dispose() {
    _timerSueno?.cancel();
    _timerEnergiaPerdida?.cancel();
    _timerTiempoSueno?.cancel();
    _respiracionController?.dispose();
    _zzController?.dispose();
    super.dispose();
  }

  void _iniciarTimerEnergiaPerdida() {
    _timerEnergiaPerdida = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (!_estaDurmiendo) {
        setState(() {
          _energia = (_energia - 0.02).clamp(0.0, 1.0);
        });
      }
    });
  }

  void _iniciarSueno() {
    setState(() {
      _estaDurmiendo = true;
      _tiempoSueno = 0;
    });
    
    widget.onMascotaDurmiendoChanged(true);
    
    if (_respiracionController != null && _zzController != null) {
      _respiracionController!.repeat(reverse: true);
      _zzController!.repeat(reverse: true);
    }
    
    _timerSueno?.cancel();
    _timerTiempoSueno?.cancel();
    
    _timerSueno = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _energia = (_energia + 0.05).clamp(0.0, 1.0);
        if (_tiempoSueno % 15 == 0 && _tiempoSueno > 0) {
          widget.onMonedasChanged(widget.monedas + 2);
        }
      });
    });
    
    _timerTiempoSueno = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _tiempoSueno++;
      });
    });
  }

  void _despertarMascota() {
    setState(() {
      _estaDurmiendo = false;
      _tiempoSueno = 0;
    });
    
    widget.onMascotaDurmiendoChanged(false);
    
    if (_respiracionController != null && _zzController != null) {
      _respiracionController!.stop();
      _zzController!.stop();
      _respiracionController!.reset();
      _zzController!.reset();
    }
    
    _timerSueno?.cancel();
    _timerTiempoSueno?.cancel();
    _timerSueno = null;
    _timerTiempoSueno = null;
  }

  String _formatearTiempo(int segundos) {
    int minutos = segundos ~/ 60;
    int segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  String _obtenerImagenMascota() {
    if (_estaDurmiendo || widget.mascotaDurmiendo) {
      return 'assets/images/mascota_durmiendo.png';
    } else {
      return 'assets/images/mascota.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text(
          'Dormitorio de Fluffy',
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
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/dormitorio_fondo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _estaDurmiendo || widget.mascotaDurmiendo
                    ? [
                        Colors.indigo.shade900.withOpacity(0.7),
                        Colors.purple.shade900.withOpacity(0.8)
                      ]
                    : [
                        Colors.indigo.withOpacity(0.3),
                        Colors.blue.withOpacity(0.5)
                      ],
                stops: const [0.0, 0.3],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 120),
                const SizedBox(height: 100),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _respiracionAnimacion ?? const AlwaysStoppedAnimation(1.0),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: (_estaDurmiendo || widget.mascotaDurmiendo) 
                              ? _respiracionAnimacion!.value 
                              : 1.0,
                          child: Container(
                            width: 250,
                            height: 250,
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: (_estaDurmiendo || widget.mascotaDurmiendo)
                                  ? Colors.blue.withOpacity(0.1) 
                                  : Colors.transparent,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Image.asset(
                                _obtenerImagenMascota(),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_estaDurmiendo || widget.mascotaDurmiendo)
                      Positioned(
                        top: 20,
                        right: 30,
                        child: AnimatedBuilder(
                          animation: _zzAnimacion!,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _zzAnimacion!.value,
                              child: Column(
                                children: [
                                  Text(
                                    'Z',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Z',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Z',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 40),
                Card(
                  color: (_estaDurmiendo || widget.mascotaDurmiendo) 
                      ? Colors.grey.shade800 
                      : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.battery_charging_full, 
                              color: (_estaDurmiendo || widget.mascotaDurmiendo) 
                                  ? Colors.white 
                                  : Colors.blue
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Energía:', 
                              style: TextStyle(
                                fontSize: 16,
                                color: (_estaDurmiendo || widget.mascotaDurmiendo) 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(_energia * 100).round()}%', 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: (_estaDurmiendo || widget.mascotaDurmiendo) 
                                    ? Colors.white 
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _energia,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _energia > 0.7 ? Colors.green : 
                            _energia > 0.3 ? Colors.orange : Colors.red
                          ),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_estaDurmiendo && _tiempoSueno > 0)
                  Card(
                    color: Colors.grey.shade800,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Durmiendo: ${_formatearTiempo(_tiempoSueno)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _estaDurmiendo ? _despertarMascota : _iniciarSueno,
                    icon: Icon(
                      _estaDurmiendo ? Icons.alarm : Icons.bedtime,
                      color: Colors.white,
                    ),
                    label: Text(
                      _estaDurmiendo ? 'Despertar' : 'Dormir',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _estaDurmiendo ? Colors.orange : Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _estaDurmiendo 
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _estaDurmiendo
                        ? '💤 Fluffy está descansando y recuperando energía...\n+2 monedas cada 15 segundos'
                        : '🛏️ Fluffy necesita dormir para recuperar energía.\n¡Un buen descanso da monedas extra!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _estaDurmiendo ? Colors.white70 : Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}