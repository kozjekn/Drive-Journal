import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ride_journal/data/datasources/local/active_ride_local_data_source.dart';
import 'package:ride_journal/domain/entities/route_point.dart';

/// Exercises the real Hive-backed store, since the point of this box is its
/// on-disk layout: append-only chunks that a flush never rewrites.
void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late ActiveRideLocalDataSourceImpl store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('active_ride_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>('active_ride_test');
    store = ActiveRideLocalDataSourceImpl(box);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  RoutePoint point(int i) => RoutePoint(
        latitude: 46.0 + i * 0.001,
        longitude: 14.5,
        altitude: 300 + i.toDouble(),
        speed: 10,
        timestamp: DateTime(2026, 8, 3, 12, 0, i),
      );

  test('returns null when nothing is in progress', () async {
    expect(await store.load(), isNull);
  });

  test('round-trips points across several chunks in order', () async {
    await store.begin(
      id: 'ride-1',
      name: 'Morning Ride',
      startTime: DateTime(2026, 8, 3, 12),
    );
    await store.appendPoints([point(0), point(1)]);
    await store.appendPoints([point(2)]);
    await store.appendPoints([point(3), point(4)]);

    final snapshot = await store.load();

    expect(snapshot, isNotNull);
    expect(snapshot!.id, 'ride-1');
    expect(snapshot.name, 'Morning Ride');
    expect(snapshot.points, hasLength(5));
    expect(snapshot.chunkCount, 3);
    // Order matters: the track is a path, not a set.
    expect(
      snapshot.points.map((p) => p.altitude).toList(),
      [300, 301, 302, 303, 304],
    );
    expect(snapshot.lastPointTime, point(4).timestamp);
  });

  test('a flush does not rewrite earlier chunks', () async {
    await store.begin(
      id: 'ride-1',
      name: 'Ride',
      startTime: DateTime(2026, 8, 3, 12),
    );
    await store.appendPoints([point(0)]);
    final firstChunk = box.get('p0');

    await store.appendPoints([point(1)]);
    await store.appendPoints([point(2)]);

    // Identity of the earliest chunk is untouched — this is what keeps the cost
    // per flush constant instead of growing with the ride.
    expect(box.get('p0'), same(firstChunk));
  });

  test('survives a crash between writing a chunk and bumping the count',
      () async {
    await store.begin(
      id: 'ride-1',
      name: 'Ride',
      startTime: DateTime(2026, 8, 3, 12),
    );
    await store.appendPoints([point(0)]);
    await store.appendPoints([point(1)]);

    // Simulate the interrupted append: the chunk landed, the meta bump did not.
    await box.put('p2', [
      {
        'latitude': 46.5,
        'longitude': 14.5,
        'altitude': 400.0,
        'speed': 11.0,
        'timestamp': DateTime(2026, 8, 3, 12, 5).millisecondsSinceEpoch,
      }
    ]);

    final snapshot = await store.load();

    // load() walks chunks rather than trusting chunkCount, so the newest chunk is
    // recovered instead of silently dropped.
    expect(snapshot!.points, hasLength(3));
    expect(snapshot.chunkCount, 3);
  });

  test('stops at the first missing chunk rather than throwing', () async {
    await store.begin(
      id: 'ride-1',
      name: 'Ride',
      startTime: DateTime(2026, 8, 3, 12),
    );
    await store.appendPoints([point(0)]);
    await store.appendPoints([point(1)]);
    // A hole: p1 is gone but the meta still claims two chunks.
    await box.delete('p1');

    final snapshot = await store.load();

    expect(snapshot!.points, hasLength(1));
    expect(snapshot.chunkCount, 1);
  });

  test('resuming continues chunk numbering so loaded chunks survive', () async {
    await store.begin(
      id: 'ride-1',
      name: 'Ride',
      startTime: DateTime(2026, 8, 3, 12),
    );
    await store.appendPoints([point(0)]);
    await store.appendPoints([point(1)]);

    // Resume path: same id, continuing from the chunks already on disk.
    await store.begin(
      id: 'ride-1',
      name: 'Ride',
      startTime: DateTime(2026, 8, 3, 12),
      startingChunk: 2,
    );
    await store.appendPoints([point(2)]);

    final snapshot = await store.load();
    expect(snapshot!.points, hasLength(3));
  });

  test('a fresh begin clears a previous recording', () async {
    await store.begin(
      id: 'old',
      name: 'Old',
      startTime: DateTime(2026, 8, 3, 10),
    );
    await store.appendPoints([point(0), point(1)]);

    await store.begin(
      id: 'new',
      name: 'New',
      startTime: DateTime(2026, 8, 3, 12),
    );

    final snapshot = await store.load();
    expect(snapshot!.id, 'new');
    expect(snapshot.points, isEmpty);
  });

  test('appendPoints is a no-op before begin', () async {
    await store.appendPoints([point(0)]);
    expect(await store.load(), isNull);
  });

  test('clear removes everything', () async {
    await store.begin(
      id: 'ride-1',
      name: 'Ride',
      startTime: DateTime(2026, 8, 3, 12),
    );
    await store.appendPoints([point(0)]);

    await store.clear();

    expect(await store.load(), isNull);
    expect(box.isEmpty, isTrue);
  });
}
