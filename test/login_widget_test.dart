import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/auth/login_screen.dart';

void main() {
  testWidgets(
      'Màn hình Login hiển thị đủ trường nhập liệu và báo lỗi khi để trống',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Kiểm tra sự tồn tại của ô nhập Email, Password và nút Đăng nhập
    expect(find.byKey(const ValueKey('email_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('password_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('submit_button')), findsOneWidget);

    // 2. Nhấn nút Đăng nhập khi chưa nhập gì
    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pumpAndSettle();

    // 3. Xác nhận hiển thị thông báo lỗi Validation tiếng Việt
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Mật khẩu phải từ 6 ký tự trở lên'), findsOneWidget);
  });

  testWidgets(
      'Màn hình Đăng ký hiển thị ô Xác nhận mật khẩu và báo lỗi khi mật khẩu không khớp',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Chuyển sang sang tab Đăng ký
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    // Kiểm tra các ô nhập liệu của Đăng ký
    expect(find.byKey(const ValueKey('name_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('email_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('password_field')), findsOneWidget);
    expect(find.byKey(const ValueKey('confirm_password_field')), findsOneWidget);

    // Nhập mật khẩu không khớp
    await tester.enterText(find.byKey(const ValueKey('password_field')), '123456');
    await tester.enterText(find.byKey(const ValueKey('confirm_password_field')), '654321');

    await tester.tap(find.byKey(const ValueKey('submit_button')));
    await tester.pumpAndSettle();

    expect(find.text('Mật khẩu xác nhận không khớp'), findsOneWidget);
  });
}
