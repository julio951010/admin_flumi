import 'package:flutter/material.dart';

/// Avatar circular con ícono de respaldo si no hay URL.
class AvatarConFallback extends StatelessWidget {
  final String url;
  final double radius;
  const AvatarConFallback({super.key, required this.url, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty ? Icon(Icons.person, size: radius) : null,
    );
  }
}

/// Etiqueta de estado con color e icono (verificado, suspendido, etc.).
class ChipEstado extends StatelessWidget {
  final String texto;
  final Color color;
  final IconData icono;
  const ChipEstado({
    super.key,
    required this.texto,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
