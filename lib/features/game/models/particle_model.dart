import 'package:flutter/material.dart';

class ParticleModel {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double opacity;

  ParticleModel({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    this.opacity = 1.0,
  });
}