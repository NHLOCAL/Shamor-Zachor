import 'package:mockito/annotations.dart';
import 'package:shamor_vezachor/services/progress_service.dart';
import 'package:shamor_vezachor/providers/data_provider.dart';
import 'package:shamor_vezachor/providers/progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Use the @GenerateMocks annotation to generate mocks for specific classes.
// The names provided in the list will be the names of the generated mock classes.
@GenerateMocks([
  ProgressService,
  DataProvider,
  ProgressProvider, // If we need to mock ProgressProvider itself for some widget tests
  SharedPreferences, // If ProgressService directly uses SharedPreferences and it needs to be mocked
])
void main() {
  // This file doesn't need a main function for build_runner to work.
  // It's just here to hold the annotations.
  // After adding annotations, run:
  // flutter pub run build_runner build --delete-conflicting-outputs
}
