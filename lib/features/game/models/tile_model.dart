import 'package:flutter/material.dart';

enum TileType {
  red,    // Kırmızı -> Bomba / Yıkım
  blue,   // Mavi -> Ekstra Hamle
  green,  // Yeşil -> Taş Dönüştürücü
  yellow, // Sarı -> Puan Çarpanı
  purple; // Mor -> Renk Temizleme

  Color get color {
    switch (this) {
      case TileType.red:
        return Colors.redAccent;
      case TileType.blue:
        return Colors.blueAccent;
      case TileType.green:
        return Colors.greenAccent;
      case TileType.yellow:
        return Colors.amber;
      case TileType.purple:
        return Colors.purpleAccent;
    }
  }
}

class TileModel {
  final String id;
  final int row;
  final int col;
  final TileType type;
  final bool isFalling; // Yalnızca en tepeden doğan yeni taşlar için

  TileModel({
    required this.id,
    required this.row,
    required this.col,
    required this.type,
    this.isFalling = false,
  });

  TileModel copyWith({
    String? id,
    int? row,
    int? col,
    TileType? type,
    bool? isFalling,
  }) {
    return TileModel(
      id: id ?? this.id,
      row: row ?? this.row,
      col: col ?? this.col,
      type: type ?? this.type,
      isFalling: isFalling ?? this.isFalling,
    );
  }
}