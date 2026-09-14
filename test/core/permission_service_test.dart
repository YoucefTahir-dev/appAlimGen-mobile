import 'package:app_alim_gen_mobile/core/permissions/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un administrateur voit les modules autorisés par le backend', () {
    const permissions = PermissionService({
      AppPermissions.dashboard,
      AppPermissions.products,
      AppPermissions.clients,
      AppPermissions.stock,
      AppPermissions.allLoadingOrders,
      AppPermissions.printers,
    });

    expect(permissions.allowsPath('/dashboard'), isTrue);
    expect(permissions.allowsPath('/products'), isTrue);
    expect(permissions.allowsPath('/stock'), isTrue);
    expect(permissions.allowsPath('/loading-orders'), isTrue);
    expect(permissions.allowsPath('/printers'), isTrue);
  });

  test('un opérateur voit son stock et ses chargements sans stock global', () {
    const permissions = PermissionService({
      AppPermissions.ownLoadingOrders,
      AppPermissions.sales,
    });

    expect(permissions.allowsPath('/operator-stock'), isTrue);
    expect(permissions.allowsPath('/loading-orders'), isTrue);
    expect(permissions.allowsPath('/stock'), isFalse);
  });

  test('un utilisateur sans permission ne voit que son profil', () {
    const permissions = PermissionService({});

    expect(permissions.allowsPath('/products'), isFalse);
    expect(permissions.allowsPath('/loading-orders'), isFalse);
    expect(permissions.allowsPath('/profile'), isTrue);
    expect(permissions.landingPath(), '/profile');
  });
}
