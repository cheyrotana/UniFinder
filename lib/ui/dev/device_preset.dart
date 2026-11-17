import 'package:flutter/widgets.dart';

/// What sits in the top of the screen.
enum DeviceCutout { none, notch, island, punchHole }

/// The system navigation drawn at the bottom of the screen.
enum DeviceNav {
  /// iPhone's bar (34 pt inset).
  homeIndicator,

  /// Android gesture navigation: a short pill (24 dp).
  gestureBar,

  /// Android ◁ ○ □ buttons (48 dp).
  threeButton,

  /// A physical home button (iPhone SE): no inset.
  none;

  double get inset => switch (this) {
    DeviceNav.homeIndicator => 34,
    DeviceNav.gestureBar => 24,
    DeviceNav.threeButton => 48,
    DeviceNav.none => 0,
  };
}

/// A phone the web preview can pretend to be: its screen in logical
/// pixels, status bar height, cutout, default navigation and corners.
class DevicePreset {
  const DevicePreset({
    required this.id,
    required this.name,
    required this.size,
    required this.platform,
    required this.statusBar,
    required this.cutout,
    required this.nav,
    required this.radius,
  });

  final String id;
  final String name;
  final Size size;
  final TargetPlatform platform;
  final double statusBar;
  final DeviceCutout cutout;
  final DeviceNav nav;

  /// Screen corner radius.
  final double radius;

  bool get isApple => platform == TargetPlatform.iOS;

  /// iPads and Android tablets (600 dp or more on the short side).
  bool get isTablet => size.shortestSide >= 600;
}

/// The phones in the preview's device list. The first one matches the
/// Figma frames (430 × 932) and is the default.
const devicePresets = [
  DevicePreset(
    id: 'iphone16plus',
    name: 'iPhone 16 Plus',
    size: Size(430, 932),
    platform: TargetPlatform.iOS,
    statusBar: 54,
    cutout: DeviceCutout.island,
    nav: DeviceNav.homeIndicator,
    radius: 55,
  ),
  DevicePreset(
    id: 'iphone16promax',
    name: 'iPhone 16 Pro Max',
    size: Size(440, 956),
    platform: TargetPlatform.iOS,
    statusBar: 62,
    cutout: DeviceCutout.island,
    nav: DeviceNav.homeIndicator,
    radius: 55,
  ),
  DevicePreset(
    id: 'iphone16',
    name: 'iPhone 16',
    size: Size(393, 852),
    platform: TargetPlatform.iOS,
    statusBar: 54,
    cutout: DeviceCutout.island,
    nav: DeviceNav.homeIndicator,
    radius: 50,
  ),
  DevicePreset(
    id: 'iphone13mini',
    name: 'iPhone 13 mini',
    size: Size(375, 812),
    platform: TargetPlatform.iOS,
    statusBar: 50,
    cutout: DeviceCutout.notch,
    nav: DeviceNav.homeIndicator,
    radius: 44,
  ),
  DevicePreset(
    id: 'iphonese',
    name: 'iPhone SE',
    size: Size(375, 667),
    platform: TargetPlatform.iOS,
    statusBar: 20,
    cutout: DeviceCutout.none,
    nav: DeviceNav.none,
    radius: 0,
  ),
  DevicePreset(
    id: 'pixel9',
    name: 'Pixel 9',
    size: Size(412, 923),
    platform: TargetPlatform.android,
    statusBar: 44,
    cutout: DeviceCutout.punchHole,
    nav: DeviceNav.gestureBar,
    radius: 42,
  ),
  DevicePreset(
    id: 'galaxys24',
    name: 'Galaxy S24',
    size: Size(360, 780),
    platform: TargetPlatform.android,
    statusBar: 36,
    cutout: DeviceCutout.punchHole,
    nav: DeviceNav.threeButton,
    radius: 36,
  ),
  DevicePreset(
    id: 'galaxya05',
    name: 'Galaxy A05 (small)',
    size: Size(360, 640),
    platform: TargetPlatform.android,
    statusBar: 24,
    cutout: DeviceCutout.none,
    nav: DeviceNav.threeButton,
    radius: 12,
  ),
  // Tablets, portrait. Their system bars are slimmer than a phone's.
  DevicePreset(
    id: 'ipadmini',
    name: 'iPad mini',
    size: Size(744, 1133),
    platform: TargetPlatform.iOS,
    statusBar: 24,
    cutout: DeviceCutout.none,
    nav: DeviceNav.homeIndicator,
    radius: 21,
  ),
  DevicePreset(
    id: 'ipadair11',
    name: 'iPad Air 11"',
    size: Size(820, 1180),
    platform: TargetPlatform.iOS,
    statusBar: 24,
    cutout: DeviceCutout.none,
    nav: DeviceNav.homeIndicator,
    radius: 18,
  ),
  DevicePreset(
    id: 'ipadpro13',
    name: 'iPad Pro 13"',
    size: Size(1032, 1376),
    platform: TargetPlatform.iOS,
    statusBar: 24,
    cutout: DeviceCutout.none,
    nav: DeviceNav.homeIndicator,
    radius: 30,
  ),
  DevicePreset(
    id: 'galaxytabs9',
    name: 'Galaxy Tab S9',
    size: Size(800, 1280),
    platform: TargetPlatform.android,
    statusBar: 28,
    cutout: DeviceCutout.none,
    nav: DeviceNav.threeButton,
    radius: 18,
  ),
  DevicePreset(
    id: 'pixeltablet',
    name: 'Pixel Tablet',
    size: Size(800, 1280),
    platform: TargetPlatform.android,
    statusBar: 28,
    cutout: DeviceCutout.punchHole,
    nav: DeviceNav.gestureBar,
    radius: 24,
  ),
];

/// How the preview draws the phone: a preset plus the panel's overrides.
class DeviceLook {
  const DeviceLook({
    required this.preset,
    required this.cutout,
    required this.nav,
    this.statusBar = true,
    this.bezel = false,
  });

  /// The first preset as it comes.
  static final standard = DeviceLook(
    preset: devicePresets.first,
    cutout: devicePresets.first.cutout,
    nav: devicePresets.first.nav,
  );

  final DevicePreset preset;
  final DeviceCutout cutout;
  final DeviceNav nav;
  final bool statusBar;
  final bool bezel;

  /// The safe areas the app sees. Without the status bar, a cutout still
  /// keeps its space.
  EdgeInsets get insets => EdgeInsets.only(
    top: statusBar || cutout != DeviceCutout.none ? preset.statusBar : 0,
    bottom: navInset,
  );

  /// The bottom inset: an iPad's home indicator takes 20, not 34.
  double get navInset =>
      preset.isTablet && nav == DeviceNav.homeIndicator ? 20 : nav.inset;
}
