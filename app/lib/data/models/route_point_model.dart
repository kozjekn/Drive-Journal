import 'package:hive/hive.dart';
import 'package:ride_journal/domain/entities/route_point.dart';

class RoutePointModel extends RoutePoint {
  const RoutePointModel({
    required super.latitude,
    required super.longitude,
    required super.altitude,
    required super.speed,
    required super.timestamp,
  });

  factory RoutePointModel.fromEntity(RoutePoint point) {
    return RoutePointModel(
      latitude: point.latitude,
      longitude: point.longitude,
      altitude: point.altitude,
      speed: point.speed,
      timestamp: point.timestamp,
    );
  }

  factory RoutePointModel.fromMap(Map<dynamic, dynamic> map) {
    return RoutePointModel(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  factory RoutePointModel.fromJson(Map<String, dynamic> json) {
    return RoutePointModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      // UTC with a trailing Z, matching RideModel.toJson.
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  RoutePoint toEntity() {
    return RoutePoint(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speed: speed,
      timestamp: timestamp,
    );
  }
}

class RoutePointAdapter extends TypeAdapter<RoutePointModel> {
  @override
  final int typeId = 1;

  @override
  RoutePointModel read(BinaryReader reader) {
    final map = reader.readMap();
    return RoutePointModel.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, RoutePointModel obj) {
    writer.writeMap(obj.toMap());
  }
}
