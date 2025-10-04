// Basic Flutter widget test adaptado a la app actual.
// - Inicializa timezones para poder crear MascotaVirtualApp con la hora de Chile.
// - Hace un smoke test: monta la app, espera que construya y verifica
//   que exista el NavigationBar y que se pueda cambiar de pestaña.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mascota/main.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  // Asegura binding e inicializa zonas horarias UNA sola vez.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    tz.initializeTimeZones();
  });

  testWidgets('App smoke test: build + nav funciona', (WidgetTester tester) async {
    // Localización de Chile para el constructor requerido.
    final cl = tz.getLocation('America/Santiago');

    // Monta la app (sin const, porque recibe parámetros dinámicos).
    await tester.pumpWidget(MascotaVirtualApp(chileLocation: cl));
    await tester.pumpAndSettle();

    // La app debería construir y mostrar un NavigationBar.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Navega entre pestañas tocando los destinos (si los labels son visibles).
    // Intentamos tocar por icono para asegurar compatibilidad con Material 3.
    await tester.tap(find.byIcon(Icons.storefront_outlined)); // Tienda
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.nightlight_round)); // Dormir
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.pets)); // Mascota
    await tester.pumpAndSettle();

    // Si quieres, puedes añadir más expectativas específicas de tu UI aquí.
  });
}
