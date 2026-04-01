import 'package:drive_journal/domain/entities/ride.dart';
import 'package:drive_journal/domain/repositories/ride_repository.dart';

class GetAllRides {
  final RideRepository repository;

  const GetAllRides(this.repository);

  Future<List<Ride>> call() async {
    return repository.getAllRides();
  }
}
