import 'package:flutter/material.dart';

import '../../../config/tema.dart';

/// Filtros y ordenamiento para la lista de usuarios
class UsuariosFilters extends StatelessWidget {
  final String filtroActivo;
  final String ordenActivo;
  final ValueChanged<String> onFiltroChanged;
  final ValueChanged<String> onOrdenChanged;

  const UsuariosFilters({
    super.key,
    required this.filtroActivo,
    required this.ordenActivo,
    required this.onFiltroChanged,
    required this.onOrdenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtros de estado
        Text(
          'Filtrar por estado',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filtrosOpciones.map((opcion) {
            final seleccionado = filtroActivo == opcion.valor;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(opcion.icono, size: 16),
                  const SizedBox(width: 6),
                  Text(opcion.label),
                ],
              ),
              selected: seleccionado,
              onSelected: (_) => onFiltroChanged(opcion.valor),
              selectedColor: opcion.color.withValues(alpha: 0.2),
              checkmarkColor: opcion.color,
              labelStyle: TextStyle(
                color: seleccionado ? opcion.color : colorScheme.onSurfaceVariant,
                fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: seleccionado ? opcion.color : colorScheme.outlineVariant,
              ),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Ordenamiento
        Text(
          'Ordenar por',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ordenOpciones.map((opcion) {
            final seleccionado = ordenActivo == opcion.valor;
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(opcion.icono, size: 16),
                  const SizedBox(width: 6),
                  Text(opcion.label),
                ],
              ),
              selected: seleccionado,
              onSelected: (_) => onOrdenChanged(opcion.valor),
              selectedColor: Tema.marca.withValues(alpha: 0.2),
              checkmarkColor: Tema.marca,
              labelStyle: TextStyle(
                color: seleccionado ? Tema.marca : colorScheme.onSurfaceVariant,
                fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: seleccionado ? Tema.marca : colorScheme.outlineVariant,
              ),
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static const List<_FiltroOpcion> _filtrosOpciones = [
    _FiltroOpcion('todos', 'Todos', Icons.filter_list_rounded, Colors.grey),
    _FiltroOpcion('verificados', 'Verificados', Icons.verified_rounded, Colors.blue),
    _FiltroOpcion('suspendidos', 'Suspendidos', Icons.block_rounded, Colors.red),
    _FiltroOpcion('con_foto', 'Con foto', Icons.image_rounded, Colors.green),
    _FiltroOpcion('perfil_completo', 'Perfil completo', Icons.check_circle_rounded, Colors.purple),
    _FiltroOpcion('recientes', 'Recientes (7d)', Icons.schedule_rounded, Colors.orange),
  ];

  static const List<_OrdenOpcion> _ordenOpciones = [
    _OrdenOpcion('recientes', 'Más recientes', Icons.new_releases_rounded),
    _OrdenOpcion('antiguos', 'Más antiguos', Icons.history_rounded),
    _OrdenOpcion('nombre_az', 'Nombre A-Z', Icons.sort_by_alpha_rounded),
    _OrdenOpcion('nombre_za', 'Nombre Z-A', Icons.sort_by_alpha_rounded),
    _OrdenOpcion('popularidad', 'Popularidad', Icons.trending_up_rounded),
    _OrdenOpcion('ultima_conexion', 'Última conexión', Icons.access_time_rounded),
  ];
}

class _FiltroOpcion {
  final String valor;
  final String label;
  final IconData icono;
  final Color color;

  const _FiltroOpcion(this.valor, this.label, this.icono, this.color);
}

class _OrdenOpcion {
  final String valor;
  final String label;
  final IconData icono;

  const _OrdenOpcion(this.valor, this.label, this.icono);
}