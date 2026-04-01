import 'package:equatable/equatable.dart';
import 'package:drive_journal/domain/entities/route_point.dart';

class Ride extends Equatable {
  final String id;
  final String name;
  final double distanceMeters;
  final Duration duration;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double elevationGainMeters;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RoutePoint> routePoints;

  const Ride({
    required this.id,
    required this.name,
    required this.distanceMeters,
    required this.duration,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.elevationGainMeters,
    required this.startTime,
    this.endTime,
    required this.routePoints,
  });

  bool get isActive => endTime == null;

  Ride copyWith({
    String? id,
    String? name,
    double? distanceMeters,
    Duration? duration,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    double? elevationGainMeters,
    DateTime? startTime,
    DateTime? endTime,
    List<RoutePoint>? routePoints,
  }) {
    return Ride(
      id: id ?? this.id,
      name: name ?? this.name,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      duration: duration ?? this.duration,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      elevationGainMeters: elevationGainMeters ?? this.elevationGainMeters,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      routePoints: routePoints ?? this.routePoints,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    distanceMeters,
    duration,
    avgSpeedKmh,
    maxSpeedKmh,
    elevationGainMeters,
    startTime,
    endTime,
    routePoints,
  ];
}
