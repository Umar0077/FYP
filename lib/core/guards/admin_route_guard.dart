import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/admin/admin_auth_service.dart';

class AdminRouteGuard extends GetMiddleware {
  AdminRouteGuard() : super(priority: 1);

  @override
  RouteSettings? redirect(String? route) {
    final isAdmin = AdminAuthService.isAdminLoggedIn;
    if (!isAdmin) {
      log('Blocked non-admin access to $route', name: 'AdminRouteGuard');
      return const RouteSettings(name: '/admin/login');
    }

    return null;
  }
}
