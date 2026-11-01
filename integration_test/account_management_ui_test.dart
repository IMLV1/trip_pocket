import 'package:integration_test/integration_test.dart';
import '../test/account_and_trip_management_test.dart' as scenarios;

// Run the same user journeys on Android, with explicitly fake repositories.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  scenarios.main();
}
