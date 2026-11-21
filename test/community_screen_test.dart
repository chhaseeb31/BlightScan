import 'package:blightscan/core/services/auth_session_service.dart';
import 'package:blightscan/features/community/data/services/community_service.dart';
import 'package:blightscan/features/community/domain/models/community_post.dart';
import 'package:blightscan/features/community/presentation/screens/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Feed extends CommunityService {
  Feed(AuthSessionService auth) : super(authSession: auth);
  @override
  Future<void> loadPosts() async {}
  @override
  List<CommunityPost> get posts => [
        CommunityPost(
            id: '1',
            authorId: 'grower',
            authorName: 'Ayesha Khan',
            caption:
                'My first tomatoes of the season! Keeping the leaves dry and giving each plant a little more space has made such a difference.',
            imageUrls: [],
            createdAt: DateTime(2026, 11, 20),
            likeCount: 12)
      ];
}

void main() {
  testWidgets('compact feed filters and search work without overflow',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = AuthSessionService();
    final feed = Feed(auth);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider<CommunityService>.value(value: feed)
    ], child: const MaterialApp(home: CommunityScreen())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'no matching post');
    await tester.pumpAndSettle();
    expect(find.text('No posts here yet'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('With photos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('With photos'));
    await tester.pumpAndSettle();
    expect(find.text('No posts here yet'), findsOneWidget);
    await tester.ensureVisible(find.text('Latest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Latest'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    feed.dispose();
    auth.dispose();
  });
}
