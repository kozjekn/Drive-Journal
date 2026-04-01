import 'package:hive/hive.dart';
import 'package:drive_journal/domain/entities/route_point.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.millisecondsSinceEpoch,
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
