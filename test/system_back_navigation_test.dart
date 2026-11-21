import 'package:blightscan/core/services/app_state_service.dart';
import 'package:blightscan/features/home/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  for (final path in ['/community', '/history', '/profile']) {
    testWidgets('Android Back from $path returns Home and persists Home',
        (tester) async {
      final router = makeRouter(path);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(
          await router.backButtonDispatcher.invokeCallback(Future.value(false)),
          isTrue);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/main');
      expect(AppStateService().getRouteToRestore(), '/main');
      expect(
          await router.backButtonDispatcher.invokeCallback(Future.value(false)),
          isFalse);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
    });
  }
  testWidgets(
      'detail, dialog and scan pop before the selected tab; resume preserves tab',
      (tester) async {
    final router = makeRouter('/profile');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    for (final path in ['/profile/detail', '/scan']) {
      router.push(path);
      await tester.pumpAndSettle();
      await router.backButtonDispatcher.invokeCallback(Future.value(false));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/profile');
    }
    showDialog<void>(
        context: tester.element(find.text('page /profile')),
        builder: (_) => const AlertDialog(title: Text('dialog')));
    await tester.pumpAndSettle();
    await router.backButtonDispatcher.invokeCallback(Future.value(false));
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/profile');
    await tester.pumpWidget(const SizedBox());
    router.dispose();
  });
}

GoRouter makeRouter(String initial) =>
    GoRouter(initialLocation: initial, routes: [
      StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => MainScreen(navigationShell: shell),
          branches: [
            for (final path in [
              '/main',
              '/community',
              '/scan-tab',
              '/history',
              '/profile'
            ])
              StatefulShellBranch(routes: [
                GoRoute(
                    path: path,
                    builder: (_, __) => Center(child: Text('page $path')),
                    routes: [
                      GoRoute(
                          path: 'detail',
                          builder: (_, __) =>
                              const Scaffold(body: Text('detail'))),
                    ])
              ]),
          ]),
      GoRoute(
          path: '/scan',
          builder: (_, __) => const Scaffold(body: Text('scan'))),
    ]);
