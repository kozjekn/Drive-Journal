import 'package:ride_journal/domain/repositories/ride_repository.dart';

class GetPendingRideCount {
  final RideRepository repository;

  GetPendingRideCount(this.repository);

  Future<int> call() => repository.pendingRideCount();
}
