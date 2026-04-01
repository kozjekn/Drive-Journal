import 'package:hive/hive.dart';
import 'package:drive_journal/data/models/route_point_model.dart';
import 'package:drive_journal/domain/entities/ride.dart';

class RideModel extends Ride {
  const RideModel({
    required super.id,
    required super.name,
    required super.distanceMeters,
    required super.duration,
    required super.avgSpeedKmh,
    required super.maxSpeedKmh,
    required super.elevationGainMeters,
    required super.startTime,
    super.endTime,
    required super.routePoints,
  });

  factory RideModel.fromEntity(Ride ride) {
    return RideModel(
      id: ride.id,
      name: ride.name,
      distanceMeters: ride.distanceMeters,
      duration: ride.duration,
      avgSpeedKmh: ride.avgSpeedKmh,
      maxSpeedKmh: ride.maxSpeedKmh,
      elevationGainMeters: ride.elevationGainMeters,
      startTime: ride.startTime,
      endTime: ride.endTime,
      routePoints: ride.routePoints,
    );
  }

  factory RideModel.fromMap(Map<dynamic, dynamic> map) {
    final routePointsList =
        (map['routePoints'] as List<dynamic>?)
            ?.map((e) => RoutePointModel.fromMap(e as Map<dynamic, dynamic>))
            .toList() ??
        [];

    return RideModel(
      id: map['id'] as String,
      name: map['name'] as String,
      distanceMeters: (map['distanceMeters'] as num).toDouble(),
      duration: Duration(milliseconds: map['durationMs'] as int),
      avgSpeedKmh: (map['avgSpeedKmh'] as num).toDouble(),
      maxSpeedKmh: (map['maxSpeedKmh'] as num).toDouble(),
      elevationGainMeters: (map['elevationGainMeters'] as num).toDouble(),
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int)
          : null,
      routePoints: routePointsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'distanceMeters': distanceMeters,
      'durationMs': duration.inMilliseconds,
      'avgSpeedKmh': avgSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'elevationGainMeters': elevationGainMeters,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'routePoints': routePoints
          .map((p) => RoutePointModel.fromEntity(p).toMap())
          .toList(),
    };
  }

  Ride toEntity() {
    return Ride(
      id: id,
      name: name,
      distanceMeters: distanceMeters,
      duration: duration,
      avgSpeedKmh: avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh,
      elevationGainMeters: elevationGainMeters,
      startTime: startTime,
      endTime: endTime,
      routePoints: routePoints,
    );
  }
}

class RideAdapter extends TypeAdapter<RideModel> {
  @override
  final int typeId = 0;

  @override
  RideModel read(BinaryReader reader) {
    final map = reader.readMap();
    return RideModel.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, RideModel obj) {
    writer.writeMap(obj.toMap());
  }
}
