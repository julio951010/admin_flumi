import 'package:flutter/material.dart';

import '../../config/tema.dart';
import 'mensajes_servicio.dart';

/// Texto legible para un error de Supabase.
String mensajeDeError(Object e) {
  var texto = e.toString();
  const prefijo = 'PostgrestException(message: ';
  if (texto.startsWith(prefijo)) {
    texto = texto.substring(prefijo.length);
    final fin = texto.indexOf(', code: ');
    if (fin >= 0) texto = texto.substring(0, fin);
  }
  return texto.replaceFirst('Exception: ', '');
}

/// dd/mm/aaaa hh:mm
String fechaCorta(DateTime? fecha) {
  if (fecha == null) return '—';
  final ahora = DateTime.now();
  final diff = ahora.difference(fecha);

  if (diff.inSeconds < 60) return 'hace un momento';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24 && ahora.day == fecha.day) {
    return 'hoy ${_dos(fecha.hour)}:${_dos(fecha.minute)}';
  }
  final ayer = ahora.subtract(const Duration(days: 1));
  if (ayer.year == fecha.year &&
      ayer.month == fecha.month &&
      ayer.day == fecha.day) {
    return 'ayer ${_dos(fecha.hour)}:${_dos(fecha.minute)}';
  }
  return '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year} '
      '${_dos(fecha.hour)}:${_dos(fecha.minute)}';
}

String fechaCompleta(DateTime? fecha) {
  if (fecha == null) return 'Fecha desconocida';
  return '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year} '
      'a las ${_dos(fecha.hour)}:${_dos(fecha.minute)}';
}

String _dos(int n) => n.toString().padLeft(2, '0');

/// Estado de envío en español.
String estadoLegible(String estado) {
  switch (estado) {
    case 'leido':
      return 'Leído';
    case 'entregado':
      return 'Entregado';
    default:
      return 'Enviado';
  }
}

/// Sustituye las variables disponibles en una plantilla.
String aplicarVariables(String texto, {required String nombre}) {
  return texto.replaceAll('{nombre}', nombre);
}

Color colorRemitente(String clave) =>
    clave == remitenteFlumiClave ? Tema.marca : Colors.orange.shade700;

IconData iconoRemitente(String clave) => clave == remitenteFlumiClave
    ? Icons.smart_toy_rounded
    : Icons.admin_panel_settings_rounded;

/// Avatar con iniciales (evita cargas de red en listas largas).
class AvatarIniciales extends StatelessWidget {
  final String nombre;
  final String claveRemitente;
  final double radio;

  const AvatarIniciales({
    super.key,
    required this.nombre,
    this.claveRemitente = remitenteAdminClave,
    this.radio = 20,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.trim().isEmpty
        ? '?'
        : nombre.trim().characters.first.toUpperCase();
    final color = colorRemitente(claveRemitente);

    return CircleAvatar(
      radius: radio,
      backgroundColor: color.withValues(alpha: 0.14),
      child: Text(
        inicial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radio * 0.8,
        ),
      ),
    );
  }
}

/// Chip compacto que indica si el mensaje lo envió Administrador o Flumi.
class RemitenteBadge extends StatelessWidget {
  final String clave;
  final bool compacto;

  const RemitenteBadge({
    super.key,
    required this.clave,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorRemitente(clave);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 8 : 10,
        vertical: compacto ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconoRemitente(clave), size: compacto ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              clave == remitenteFlumiClave ? 'Flumi' : 'Admin',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compacto ? 10 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de remitente (Administrador / Flumi).
class RemitenteSelector extends StatelessWidget {
  final String valor;
  final ValueChanged<String> onChanged;

  const RemitenteSelector({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Opcion(
            clave: remitenteAdminClave,
            nombre: 'Administrador',
            seleccionada: valor == remitenteAdminClave,
            onTap: () => onChanged(remitenteAdminClave),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Opcion(
            clave: remitenteFlumiClave,
            nombre: 'Flumi',
            seleccionada: valor == remitenteFlumiClave,
            onTap: () => onChanged(remitenteFlumiClave),
          ),
        ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {
  final String clave;
  final String nombre;
  final bool seleccionada;
  final VoidCallback onTap;

  const _Opcion({
    required this.clave,
    required this.nombre,
    required this.seleccionada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorRemitente(clave);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: seleccionada ? color.withValues(alpha: 0.10) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionada ? color : Colors.grey.shade300,
              width: seleccionada ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(iconoRemitente(clave), size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        seleccionada ? FontWeight.w700 : FontWeight.w500,
                    color: seleccionada ? color : Colors.black87,
                  ),
                ),
              ),
              if (seleccionada)
                Icon(Icons.check_circle_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta compacta de métrica.
class StatTile extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final String? detalle;

  const StatTile({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, size: 15, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 2),
            Text(
              detalle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chips de plantillas para insertar en un mensaje.
class PlantillaChips extends StatelessWidget {
  final List<PlantillaMensaje> plantillas;
  final ValueChanged<PlantillaMensaje> onSeleccionada;

  const PlantillaChips({
    super.key,
    required this.plantillas,
    required this.onSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    if (plantillas.isEmpty) {
      return Text(
        'Aún no hay plantillas. Créalas desde la pestaña Plantillas.',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in plantillas)
          ActionChip(
            avatar: const Icon(Icons.notes_rounded, size: 16),
            label: Text(
              p.titulo,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () => onSeleccionada(p),
          ),
      ],
    );
  }
}

/// Tarjeta de aviso reutilizable.
class AvisoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final Color color;
  final List<Widget>? acciones;

  const AvisoCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.detalle,
    this.color = Colors.grey,
    this.acciones,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            detalle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
          if (acciones != null && acciones!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: acciones!),
          ],
        ],
      ),
    );
  }
}
