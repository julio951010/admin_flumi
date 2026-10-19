import 'package:flutter/material.dart';

/// Configuración para una tarjeta de estadística
class StatConfig {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool trendPositive;

  const StatConfig(
    this.title,
    this.value,
    this.icon,
    this.color, {
    this.trend,
    this.trendPositive = true,
  });
}