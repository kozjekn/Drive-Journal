import 'package:ride_journal/domain/entities/sync_outcome.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';

class SyncRides {
  final RideRepository repository;

  SyncRides(this.repository);

  Future<SyncOutcome> call() => repository.syncRides();
}
