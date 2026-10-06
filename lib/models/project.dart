import 'package:flutter/material.dart';

class Project {
  const Project({
    this.id,
    required this.name,
    required this.client,
    required this.status,
    required this.progress,
    required this.color,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String client;
  final String status;
  final double progress;
  final Color color;
  final String? updatedAt;

  factory Project.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'];
    final progress = rawProgress is num ? rawProgress.toDouble() : 0.0;
    return Project(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      client: json['client']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Planning',
      progress: progress > 1 ? progress / 100 : progress,
      color: const Color(0xFF3157D5),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'client': client,
    'status': status,
    'progress': progress,
  };

  Project copyWith({
    String? id,
    String? name,
    String? client,
    String? status,
    double? progress,
    Color? color,
    String? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      client: client ?? this.client,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      color: color ?? this.color,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
