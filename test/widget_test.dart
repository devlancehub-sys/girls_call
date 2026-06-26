import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:love_call_girls/core/services/api_service.dart';
import 'package:love_call_girls/core/services/socket_service.dart';
import 'package:love_call_girls/core/services/storage_service.dart';
import 'package:love_call_girls/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Get.putAsync<StorageService>(() async => StorageService().init());
    await Get.putAsync<ApiService>(() async => ApiService().init());
    Get.put(SocketService());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LoveCallGirlsApp());
    await tester.pump();

    expect(find.text('Love Call Girls'), findsOneWidget);
  });
}
