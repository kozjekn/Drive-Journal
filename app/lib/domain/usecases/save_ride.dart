import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';

class SaveRide {
  final RideRepository repository;

  const SaveRide(this.repository);

  Future<void> call(Ride ride) async {
    return repository.saveRide(ride);
  }
}
