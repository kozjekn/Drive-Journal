import 'package:drive_journal/domain/repositories/ride_repository.dart';

class DeleteRide {
  final RideRepository repository;

  const DeleteRide(this.repository);

  Future<void> call(String id) async {
    return repository.deleteRide(id);
  }
}
