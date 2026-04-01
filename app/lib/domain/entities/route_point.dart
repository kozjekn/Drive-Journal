import 'package:equatable/equatable.dart';

class RoutePoint extends Equatable {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // m/s from GPS sensor
  final DateTime timestamp;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        altitude,
        speed,
        timestamp,
      ];
}
