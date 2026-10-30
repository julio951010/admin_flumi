import 'package:flutter/material.dart';

/// Acciones rápidas del dashboard
class QuickActions extends StatelessWidget {
  final int reportesPendientes;
  final int soportesPendientes;
  final int pagosPendientes;

  const QuickActions({
    super.key,
    required this.reportesPendientes,
    required this.soportesPendientes,
    required this.pagosPendientes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones rápidas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final tarjetas = [
              _QuickActionCard(
                icon: Icons.flag_rounded,
                label: 'Reportes',
                subtitle: '$reportesPendientes pendientes',
                color: reportesPendientes > 0 ? Colors.red : Colors.green,
                count: reportesPendientes,
                onTap: () => _navigate(context, '/reportes'),
              ),
              _QuickActionCard(
                icon: Icons.support_agent_rounded,
                label: 'Soporte',
                subtitle: '$soportesPendientes pendientes',
                color: soportesPendientes > 0 ? Colors.deepOrange : Colors.green,
                count: soportesPendientes,
                onTap: () => _navigate(context, '/soporte'),
              ),
              _QuickActionCard(
                icon: Icons.payments_rounded,
                label: 'Pagos',
                subtitle: '$pagosPendientes pendientes',
                color: pagosPendientes > 0 ? Colors.blue : Colors.green,
                count: pagosPendientes,
                onTap: () => _navigate(context, '/pagos'),
              ),
            ];

            // En móvil las 3 tarjetas no caben en una fila sin desbordar:
            // se apilan verticalmente.
            if (constraints.maxWidth < 480) {
              return Column(
                children: [
                  for (var i = 0; i < tarjetas.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    tarjetas[i],
                  ],
                ],
              );
            }

            return Row(
              children: [
                for (var i = 0; i < tarjetas.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: tarjetas[i]),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final int count;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPending = count > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: hasPending ? 0.3 : 0.15),
              width: hasPending ? 1.5 : 1,
            ),
            boxShadow: hasPending
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  if (hasPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasPending ? 'Revisar ahora' : 'Todo al día',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasPending ? color : Colors.green,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}