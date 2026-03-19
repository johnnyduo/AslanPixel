import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/features/auth/view/forgot_password_page.dart';

void main() {
  Widget buildTestWidget() {
    return AppColors(
      scheme: AppColorScheme.dark,
      child: Sizer(
        builder: (context, orientation, screenType) {
          return MaterialApp(
            theme: ThemeData.dark(),
            home: const ForgotPasswordPage(),
          );
        },
      ),
    );
  }

  group('ForgotPasswordPage — widget rendering', () {
    testWidgets('renders page title and email field', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('ลืมรหัสผ่าน'), findsOneWidget);

      // Heading
      expect(find.text('รีเซ็ตรหัสผ่าน'), findsOneWidget);

      // Email hint
      expect(find.text('อีเมล'), findsOneWidget);

      // Submit button
      expect(find.text('ส่งลิงก์รีเซ็ต'), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('กรอกอีเมลของคุณ เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่'),
        findsOneWidget,
      );
    });

    testWidgets('renders lock icon', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_reset_rounded), findsOneWidget);
    });

    testWidgets('has a TextFormField for email input', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('has an ElevatedButton for submit', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('routeName is /forgot-password', (tester) async {
      expect(ForgotPasswordPage.routeName, '/forgot-password');
    });
  });
}
