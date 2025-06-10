import 'package:flutter/material.dart';
import 'models.dart';

// Clase para manejar las animaciones de compra
class AnimacionCompra {
  final AnimationController controller;
  final Animation<double> animacionY;
  final Animation<double> animacionOpacidad;
  final Animation<double> animacionEscala;
  final String rutaImagen;
  final Offset posicionInicial;

  AnimacionCompra({
    required this.controller,
    required this.animacionY,
    required this.animacionOpacidad,
    required this.animacionEscala,
    required this.rutaImagen,
    required this.posicionInicial,
  });
}

class TiendaPage extends StatefulWidget {
  final int monedas;
  final Function(int) onMonedasChanged;
  final Function(ComidaItem) onComidaComprada;
  final String horaActual;

  const TiendaPage({
    super.key,
    required this.monedas,
    required this.onMonedasChanged,
    required this.onComidaComprada,
    required this.horaActual,
  });

  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> with TickerProviderStateMixin {
  final List<ComidaItem> _productos = const [
    ComidaItem(nombre: 'Sushi', imagen: 'assets/images/sushi.png', precio: 10),
    ComidaItem(nombre: 'Completo', imagen: 'assets/images/completo.png', precio: 15),
    ComidaItem(nombre: 'Pizza', imagen: 'assets/images/pizza.png', precio: 20),
    ComidaItem(nombre: 'Milcao', imagen: 'assets/images/milcao.png', precio: 12),
    ComidaItem(nombre: 'Mote con Huesillo', imagen: 'assets/images/mote_con_huesillo.png', precio: 8),
  ];

  // Lista para manejar múltiples animaciones simultáneas
  List<AnimacionCompra> _animacionesCompra = [];

  @override
  void dispose() {
    // Cancelar todas las animaciones antes de dispose
    for (var animacion in _animacionesCompra) {
      animacion.controller.dispose();
    }
    super.dispose();
  }

  // Método para mostrar animación de compra
  void _mostrarAnimacionCompra(String rutaImagen, Offset posicion) {
    final controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    final animacionY = Tween<double>(
      begin: 0.0,
      end: -120.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));
    
    final animacionOpacidad = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    ));
    
    final animacionEscala = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    final nuevaAnimacion = AnimacionCompra(
      controller: controller,
      animacionY: animacionY,
      animacionOpacidad: animacionOpacidad,
      animacionEscala: animacionEscala,
      rutaImagen: rutaImagen,
      posicionInicial: posicion,
    );

    setState(() {
      _animacionesCompra.add(nuevaAnimacion);
    });

    controller.forward().then((_) {
      setState(() {
        _animacionesCompra.remove(nuevaAnimacion);
      });
      controller.dispose();
    });
  }

  void _comprarComida(ComidaItem comida, GlobalKey buttonKey) {
    if (widget.monedas >= comida.precio) {
      // Realizar la compra
      widget.onMonedasChanged(widget.monedas - comida.precio);
      widget.onComidaComprada(comida);

      // Obtener la posición del botón para la animación
      final RenderBox? renderBox = buttonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final center = Offset(
          position.dx + size.width / 2,
          position.dy + size.height / 2,
        );
        
        // Mostrar animación de compra
        _mostrarAnimacionCompra(comida.imagen, center);
      }
      
      // Mostrar SnackBar de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Compraste ${comida.nombre}! 🍽️'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Mostrar error de fondos insuficientes
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡No tienes suficientes monedas! 💰'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: const Text(
          'Tienda de Comida',
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
      ),
      body: Stack(
        children: [
          // Contenido principal de la tienda
          Container(
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _productos.length,
                  itemBuilder: (context, index) {
                    final producto = _productos[index];
                    final puedeComprar = widget.monedas >= producto.precio;
                    final GlobalKey buttonKey = GlobalKey();
                    
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset(
                              producto.imagen,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                            Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/moneda.png',
                                  width: 16,
                                  height: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${producto.precio}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              key: buttonKey,
                              onPressed: puedeComprar ? () => _comprarComida(producto, buttonKey) : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: puedeComprar ? Colors.green : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              ),
                              child: Text(
                                puedeComprar ? 'Comprar' : 'Sin dinero',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Overlay para animaciones de compra flotantes
          ...(_animacionesCompra.map((animacion) => 
            Positioned(
              left: animacion.posicionInicial.dx - 60,
              top: animacion.posicionInicial.dy - 60,
              child: AnimatedBuilder(
                animation: animacion.controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, animacion.animacionY.value),
                    child: Transform.scale(
                      scale: animacion.animacionEscala.value,
                      child: Opacity(
                        opacity: animacion.animacionOpacidad.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Imagen de la comida flotante
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  animacion.rutaImagen,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Texto "+1" flotante
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                '+1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          )),
        ],
      ),
    );
  }
}