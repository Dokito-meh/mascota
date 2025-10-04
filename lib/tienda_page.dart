import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets/app_drawer.dart';

/// Pequeña estructura para manejar cada animación de compra en el overlay.
class AnimacionCompra {
  final AnimationController controller;
  final Animation<double> animY;
  final Animation<double> opacity;
  final Animation<double> scale;
  final String rutaImagen;
  final Offset origen;

  AnimacionCompra({
    required this.controller,
    required this.animY,
    required this.opacity,
    required this.scale,
    required this.rutaImagen,
    required this.origen,
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
  // Catálogo de productos
  final List<ComidaItem> _productos = const [
    ComidaItem(nombre: 'Sushi', imagen: 'assets/images/sushi.png', precio: 10),
    ComidaItem(nombre: 'Completo', imagen: 'assets/images/completo.png', precio: 15),
    ComidaItem(nombre: 'Pizza', imagen: 'assets/images/pizza.png', precio: 20),
    ComidaItem(nombre: 'Milcao', imagen: 'assets/images/milcao.png', precio: 12),
    ComidaItem(
      nombre: 'Mote con Huesillo',
      imagen: 'assets/images/mote_con_huesillo.png',
      precio: 8,
    ),
  ];

  // % de hambre que cura cada comida (solo visual; la lógica real vive en MascotaPage)
  final Map<String, int> _curaHambre = const {
    'Sushi': 15,
    'Completo': 20,
    'Pizza': 25,
    'Milcao': 18,
    'Mote con Huesillo': 10,
  };

  // Animaciones activas en pantalla
  final List<AnimacionCompra> _animaciones = [];

  void _lanzarAnimacionCompra(String imagen, Offset origen) {
    final controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    final animY = Tween<double>(begin: 0, end: -90).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
    final opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.5, 1, curve: Curves.easeIn)),
    );
    final scale = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    final anim = AnimacionCompra(
      controller: controller,
      animY: animY,
      opacity: opacity,
      scale: scale,
      rutaImagen: imagen,
      origen: origen,
    );

    controller.addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        controller.dispose();
        setState(() => _animaciones.remove(anim));
      }
    });

    setState(() => _animaciones.add(anim));
    controller.forward();
  }

  Future<void> _comprar(ComidaItem comida, GlobalKey btnKey) async {
    if (widget.monedas < comida.precio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡No tienes suficientes monedas! 💰'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Cobrar y añadir al inventario del Home
    widget.onMonedasChanged(widget.monedas - comida.precio);
    widget.onComidaComprada(comida);

    // Origen de la animación: el botón de comprar
    final renderBox = btnKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
      _lanzarAnimacionCompra(comida.imagen, offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Drawer compartido
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
          'Tienda',
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: .82,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _productos.length,
              itemBuilder: (context, i) {
                final producto = _productos[i];
                final puedeComprar = widget.monedas >= producto.precio;
                final GlobalKey buttonKey = GlobalKey();
                final cura = _curaHambre[producto.nombre] ?? 15;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: Colors.grey[50],
                            child: Center(
                              child: Image.asset(
                                producto.imagen,
                                fit: BoxFit.contain,
                                width: 110,
                                height: 110,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        producto.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Precio
                          Image.asset('assets/images/moneda.png', width: 16, height: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${producto.precio}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // % que cura (solo número + %)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.pink.shade200),
                            ),
                            child: Text(
                              '$cura%', // ← solo el porcentaje
                              style: TextStyle(
                                color: Colors.pink.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          key: buttonKey,
                          onPressed: puedeComprar ? () => _comprar(producto, buttonKey) : null,
                          icon: const Icon(Icons.add_shopping_cart),
                          label: const Text('Comprar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: puedeComprar ? Colors.pink : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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

          // Overlay: png que "salta" más "+1"
          ..._animaciones.map((a) {
            return Positioned(
              left: a.origen.dx - 40,
              top: a.origen.dy - 40,
              child: AnimatedBuilder(
                animation: a.controller,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, a.animY.value),
                  child: Transform.scale(
                    scale: a.scale.value,
                    child: Opacity(
                      opacity: a.opacity.value,
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(a.rutaImagen, fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '+1',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
