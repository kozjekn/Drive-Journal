import 'package:hive/hive.dart';
import 'package:ride_journal/data/models/route_point_model.dart';
import 'package:ride_journal/domain/entities/ride.dart';

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
    super.visibility,
    required super.updatedAt,
    super.syncedAt,
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
      visibility: ride.visibility,
      updatedAt: ride.updatedAt,
      syncedAt: ride.syncedAt,
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
      visibility: RideVisibility.values[map['visibility'] as int? ?? 0],
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
      syncedAt: map['syncedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['syncedAt'] as int)
          : null,
    );
  }

  factory RideModel.fromJson(Map<String, dynamic> json) {
    final routePointsList =
        (json['routePoints'] as List<dynamic>?)
            ?.map((e) => RoutePointModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RideModel(
      id: json['id'] as String,
      name: json['name'] as String,
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      duration: Duration(milliseconds: (json['durationMs'] as num).toInt()),
      avgSpeedKmh: (json['avgSpeedKmh'] as num).toDouble(),
      maxSpeedKmh: (json['maxSpeedKmh'] as num).toDouble(),
      elevationGainMeters: (json['elevationGainMeters'] as num).toDouble(),
      // .toLocal(): the server sends UTC, and without this every ride would
      // render in UTC on the receiving device.
      startTime: DateTime.parse(json['startTime'] as String).toLocal(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String).toLocal()
          : null,
      routePoints: routePointsList,
      visibility: _parseVisibility(json['visibility']),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String).toLocal()
          : null,
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
      'visibility': visibility.index,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'syncedAt': syncedAt?.millisecondsSinceEpoch,
    };
  }

  /// Wire format. All timestamps are UTC with a trailing `Z`.
  ///
  /// Sending local time with no offset made the server parse it as `Unspecified`
  /// and compare it against `DateTime.UtcNow` — and sync conflict resolution is
  /// built entirely on these timestamps.
  ///
  /// `syncedAt` is deliberately omitted (device-local state) and so is `userId`
  /// (server-authoritative, taken from the JWT).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'distanceMeters': distanceMeters,
      'durationMs': duration.inMilliseconds,
      'avgSpeedKmh': avgSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'elevationGainMeters': elevationGainMeters,
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime?.toUtc().toIso8601String(),
      'routePoints': routePoints
          .map((p) => RoutePointModel.fromEntity(p).toJson())
          .toList(),
      'visibility': _visibilityToString(visibility),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
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
      visibility: visibility,
      updatedAt: updatedAt,
      syncedAt: syncedAt,
    );
  }

  static RideVisibility _parseVisibility(dynamic value) {
    if (value is int) return RideVisibility.values[value];
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'private':
          return RideVisibility.private_;
        case 'followers':
          return RideVisibility.followers;
        case 'public':
          return RideVisibility.public_;
      }
    }
    return RideVisibility.private_;
  }

  static String _visibilityToString(RideVisibility v) {
    switch (v) {
      case RideVisibility.private_:
        return 'Private';
      case RideVisibility.followers:
        return 'Followers';
      case RideVisibility.public_:
        return 'Public';
    }
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
