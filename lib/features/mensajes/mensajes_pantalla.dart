import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/tema.dart';
import 'enviar_tab.dart';
import 'historial_tab.dart';
import 'masivo_tab.dart';
import 'mensajes_servicio.dart';
import 'plantillas_tab.dart';

/// Página "Mensajes": historial, envío puntual, plantillas y envío masivo
/// desde las cuentas oficiales Administrador y Flumi.
class MensajesPantalla extends StatefulWidget {
  final MensajesServicio? servicio;

  /// Pestaña inicial: 0 historial, 1 enviar, 2 plantillas, 3 masivo.
  final int tabInicial;

  /// Cuando la página se abre como ruta propia ya existe un AppBar con el
  /// título, así que se puede ocultar el encabezado interno.
  final bool mostrarTitulo;

  const MensajesPantalla({
    super.key,
    this.servicio,
    this.tabInicial = 0,
    this.mostrarTitulo = true,
  });

  @override
  State<MensajesPantalla> createState() => _MensajesPantallaState();
}

class _MensajesPantallaState extends State<MensajesPantalla>
    with SingleTickerProviderStateMixin {
  late final MensajesServicio _servicio =
      widget.servicio ?? MensajesServicio(Supabase.instance.client);
  late final TabController _tabs = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.tabInicial.clamp(0, 3),
  );

  /// Se incrementa cuando se envía algo para refrescar el historial.
  final ValueNotifier<int> _version = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tabs.dispose();
    _version.dispose();
    super.dispose();
  }

  void _irAEnviar() {
    _tabs.animateTo(1);
  }

  void _actualizar() {
    _version.value++;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.mostrarTitulo) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensajes',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      'Historial, plantillas y envíos de Administrador y Flumi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _actualizar,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Tema.marca,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: Tema.marca,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Historial'),
            Tab(icon: Icon(Icons.send_rounded, size: 18), text: 'Enviar'),
            Tab(icon: Icon(Icons.notes_rounded, size: 18), text: 'Plantillas'),
            Tab(icon: Icon(Icons.campaign_rounded, size: 18), text: 'Masivo'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              HistorialTab(
                servicio: _servicio,
                version: _version,
                onIrAEnviar: _irAEnviar,
              ),
              EnviarTab(servicio: _servicio, onEnviado: _actualizar),
              PlantillasTab(servicio: _servicio),
              MasivoTab(servicio: _servicio, onEnviado: _actualizar),
            ],
          ),
        ),
      ],
    );
  }
}
