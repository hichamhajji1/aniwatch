import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ani/data/services/jikan_api_service.dart';
import 'package:ani/data/services/remote_config_service.dart';
import 'package:ani/data/services/storage_service.dart';
import 'package:ani/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Ani boots to the splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      AniApp(
        storage: StorageService(prefs),
        api: JikanApiService(),
        remoteConfig: RemoteConfigService(),
      ),
    );
    await tester.pump();

    expect(find.text('AnShow Anime show'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
