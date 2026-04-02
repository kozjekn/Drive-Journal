import 'package:equatable/equatable.dart';
import 'package:ride_journal/domain/entities/route_point.dart';

enum RideVisibility { private_, followers, public_ }

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
  final RideVisibility visibility;
  final DateTime updatedAt;
  final DateTime? syncedAt;

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
    this.visibility = RideVisibility.private_,
    required this.updatedAt,
    this.syncedAt,
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
    RideVisibility? visibility,
    DateTime? updatedAt,
    DateTime? syncedAt,
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
      visibility: visibility ?? this.visibility,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
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
    visibility,
    updatedAt,
    syncedAt,
  ];
}
