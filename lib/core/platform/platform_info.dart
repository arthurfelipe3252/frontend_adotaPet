import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class PlatformInfo {
  PlatformInfo._();

  static const double desktopBreakpoint = 900;

  static bool get isWeb => kIsWeb;

  static bool isDesktopWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }
}
