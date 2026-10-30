import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../config/tema.dart';
import '../dashboard_servicio.dart';

/// Gráfico interactivo de 7 días para usuarios, mensajes y matches
class Chart7D extends StatefulWidget {
  final List<SerieDia> serie;

  const Chart7D({super.key, required this.serie});

  @override
  State<Chart7D> createState() => _Chart7DEstado();
}

class _Chart7DEstado extends State<Chart7D> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  int _touchedIndex = -1;
  MetricaActiva _metricaActiva = MetricaActiva.usuarios;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.serie.isEmpty) {
      return _buildEmptyState(colorScheme);
    }

    final spots = _buildSpots();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con selector de métrica
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actividad 7 días',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMetricSelector(colorScheme),
                  ],
                );
              }
              return Row(
                children: [
                  Text(
                    'Actividad 7 días',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  _buildMetricSelector(colorScheme),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          // Gráfico
          SizedBox(
            height: 220,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: (widget.serie.length - 1).toDouble(),
                    minY: 0,
                    maxY: _getMaxY(spots) * 1.2,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getYInterval(_getMaxY(spots)),
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= widget.serie.length) {
                              return const SizedBox.shrink();
                            }
                            final dia = widget.serie[value.toInt()].fecha;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _formatDia(dia),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          interval: _getYInterval(_getMaxY(spots)),
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                _formatYValue(value),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.spotIndex;
                            if (idx >= widget.serie.length) return null;
                            final dia = widget.serie[idx];
                            return LineTooltipItem(
                              '',
                              const TextStyle(),
                              children: [
                                TextSpan(
                                  text: '${_getMetricaLabel(_metricaActiva)}: ',
                                  style: TextStyle(
                                    color: _getMetricaColor(_metricaActiva),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                TextSpan(
                                  text: _getValorMetrica(dia, _metricaActiva).toString(),
                                  style: TextStyle(
                                    color: colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                TextSpan(
                                  text: '\n${_formatFechaCompleta(dia.fecha)}',
                                  style: TextStyle(
                                    color: colorScheme.onInverseSurface.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            );
                          }).whereType<LineTooltipItem>().toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                      touchCallback: (event, response) {
                        if (response != null && response.lineBarSpots != null) {
                          setState(() {
                            _touchedIndex = response.lineBarSpots!.first.spotIndex;
                          });
                        } else {
                          setState(() => _touchedIndex = -1);
                        }
                      },
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots.map((s) => FlSpot(
                          s.x,
                          s.y * _animation.value,
                        )).toList(),
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: _getMetricaColor(_metricaActiva),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final isTouched = index == _touchedIndex;
                            return FlDotCirclePainter(
                              radius: isTouched ? 6 : 4,
                              color: _getMetricaColor(_metricaActiva),
                              strokeWidth: isTouched ? 3 : 2,
                              strokeColor: colorScheme.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _getMetricaColor(_metricaActiva).withValues(alpha: 0.3),
                              _getMetricaColor(_metricaActiva).withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Leyenda / resumen
          const SizedBox(height: 12),
          _buildLegend(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin datos para mostrar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'La serie de 7 días está vacía',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSelector(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: MetricaActiva.values.map((metrica) {
          final isSelected = _metricaActiva == metrica;
          return Padding(
            padding: const EdgeInsets.all(2),
            child: InkWell(
              onTap: () {
                setState(() {
                  _metricaActiva = metrica;
                  _animationController.reset();
                  _animationController.forward();
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _getMetricaColor(metrica) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getMetricaLabel(metrica),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(ColorScheme colorScheme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: MetricaActiva.values.map((metrica) {
        final color = _getMetricaColor(metrica);
        final valor = _getTotalMetrica(metrica);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${_getMetricaLabel(metrica)}: ${_formatNumber(valor)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<FlSpot> _buildSpots() {
    return widget.serie.asMap().entries.map((entry) {
      final index = entry.key;
      final dia = entry.value;
      double value;
      switch (_metricaActiva) {
        case MetricaActiva.usuarios:
          value = dia.usuarios.toDouble();
          break;
        case MetricaActiva.mensajes:
          value = dia.mensajes.toDouble();
          break;
        case MetricaActiva.matches:
          value = dia.matches.toDouble();
          break;
      }
      return FlSpot(index.toDouble(), value);
    }).toList();
  }

  double _getMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;
    return spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
  }

  double _getYInterval(double maxY) {
    if (maxY <= 10) return 2;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    return (maxY / 5).ceilToDouble();
  }

  int _getTotalMetrica(MetricaActiva metrica) {
    return widget.serie.fold(0, (sum, dia) {
      switch (metrica) {
        case MetricaActiva.usuarios:
          return sum + dia.usuarios;
        case MetricaActiva.mensajes:
          return sum + dia.mensajes;
        case MetricaActiva.matches:
          return sum + dia.matches;
      }
    });
  }

  int _getValorMetrica(SerieDia dia, MetricaActiva metrica) {
    switch (metrica) {
      case MetricaActiva.usuarios:
        return dia.usuarios;
      case MetricaActiva.mensajes:
        return dia.mensajes;
      case MetricaActiva.matches:
        return dia.matches;
    }
  }

  Color _getMetricaColor(MetricaActiva metrica) {
    switch (metrica) {
      case MetricaActiva.usuarios:
        return Tema.marca;
      case MetricaActiva.mensajes:
        return Colors.orange;
      case MetricaActiva.matches:
        return Colors.pink;
    }
  }

  String _getMetricaLabel(MetricaActiva metrica) {
    switch (metrica) {
      case MetricaActiva.usuarios:
        return 'Usuarios';
      case MetricaActiva.mensajes:
        return 'Mensajes';
      case MetricaActiva.matches:
        return 'Matches';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatYValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toInt().toString();
  }

  String _formatDia(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return dias[dt.weekday - 1];
    } catch (_) {
      return fecha.length > 3 ? fecha.substring(0, 3) : fecha;
    }
  }

  String _formatFechaCompleta(String fecha) {
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      return '${dt.day} ${meses[dt.month - 1]}';
    } catch (_) {
      return fecha;
    }
  }
}

enum MetricaActiva {
  usuarios,
  mensajes,
  matches,
}