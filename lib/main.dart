import 'package:air_time_manager/app/app.dart';
import 'package:air_time_manager/app/firebase/firebase_bootstrap.dart';
import 'package:air_time_manager/app/repository_factory.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  final repo = await RepositoryFactory.create();
  runApp(AirTimeManagerApp(repo: repo));
}
