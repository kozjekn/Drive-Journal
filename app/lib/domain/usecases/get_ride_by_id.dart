import 'package:ride_journal/domain/entities/ride.dart';
import 'package:ride_journal/domain/repositories/ride_repository.dart';

class GetRideById {
  final RideRepository repository;

  const GetRideById(this.repository);

  Future<Ride?> call(String id) async {
    return repository.getRideById(id);
  }
}
