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
}
