import 'package:air_time_manager/app/firebase/firebase_bootstrap.dart';
import 'package:air_time_manager/data/repositories/air_time_repository.dart';
import 'package:air_time_manager/data/repositories/firestore_air_time_repository.dart';
import 'package:air_time_manager/data/repositories/in_memory_air_time_repository.dart';

class RepositoryFactory {
  static Future<AirTimeRepository> create() async {
    if (!FirebaseBootstrap.initialized) {
      return InMemoryAirTimeRepository();
    }

    try {
      final repo = FirestoreAirTimeRepository();
      await repo.ensureSignedIn();
      await repo.ensureSeedData();
      return repo;
    } catch (_) {
      return InMemoryAirTimeRepository();
    }
  }
}
