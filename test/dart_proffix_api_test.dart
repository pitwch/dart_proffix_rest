import 'package:dart_proffix_rest/dart_proffix_api.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart' show load, isEveryDefined, env;

// Generating code coverage:
// 1. `dart pub global activate coverage`
// 2. `dart test --coverage="coverage"`
// 3. `dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage.lcov --packages=.packages --report-on=lib`

// Upload code coverage to codecov.io
// `./codecov -t ${CODECOV_TOKEN}`

void main() {
  // Load the environment variables into memory
  // I recommend using envify for a production app, this way is just simpler for an example app
  load();
  setUp(() {
    // Create client with Creds key from a .env file in the root package directory
    if (!isEveryDefined(['API'])) {
      print('API key not provided, can not run tests');
      return;
    }

    final String? _apiKey = env['API'];
    if (_apiKey == null) {
      print('API key not provided, can not run tests');
      return;
    }

    final tempClient = ProffixClient(
        httpClient: http.Client(),
        database: 'DEMODB',
        restURL: 'https://remote.proffix.net:11011',
        username: 'Gast',
        password: 'gast123');
    tempClient.close();
  });
}
