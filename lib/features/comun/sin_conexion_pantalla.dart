import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/tema.dart';
import '../../core/conectividad/conectividad_servicio.dart';

class SinConexionPantalla extends StatelessWidget {
  const SinConexionPantalla({super.key, this.mensaje});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final conectividad = context.watch<ConectividadServicio>();
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Tema.marca, Tema.marcaOscuro],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Icon(
                          Icons.wifi_off_rounded,
                          size: 44,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Sin conexión',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mensaje ??
                            'No hay conexión a internet. Verifica tu WiFi o datos móviles para continuar.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: () => conectividad.reintentar(),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reintentar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner compacto para mostrar dentro de AdminShell cuando hay pérdida
/// de conexión pero ya se había iniciado sesión.
class BannerSinConexion extends StatelessWidget {
  const BannerSinConexion({super.key});

  @override
  Widget build(BuildContext context) {
    final enLinea = context.watch<ConectividadServicio>().enLinea;
    if (enLinea) return const SizedBox.shrink();
    return Material(
      color: Colors.orange.shade700,
      child: InkWell(
        onTap: () => context.read<ConectividadServicio>().reintentar(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sin conexión — toca para reintentar',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () =>
                    context.read<ConectividadServicio>().reintentar(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
