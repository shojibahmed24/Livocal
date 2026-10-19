import 'package:flutter/material.dart';

/// Global root navigator key for high-priority routing from background notifications,
/// CallKit incoming call accepts, and deep links.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
