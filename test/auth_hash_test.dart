import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/services/auth_service.dart';

void main() {
  test('hash de senha é determinístico por salt e muda com o salt', () {
    final a = AuthService.hashPassword('pikachu123', 'salt-a');
    expect(AuthService.hashPassword('pikachu123', 'salt-a'), a);
    expect(AuthService.hashPassword('pikachu123', 'salt-b'), isNot(a));
    expect(AuthService.hashPassword('outra', 'salt-a'), isNot(a));
  });
}
