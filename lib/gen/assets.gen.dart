/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsAudioGen {
  const $AssetsAudioGen();

  /// File path: assets/audio/background.mp3
  String get background => 'assets/audio/background.mp3';

  /// File path: assets/audio/boost_gravity.mp3
  String get boostGravity => 'assets/audio/boost_gravity.mp3';

  /// File path: assets/audio/boost_jump.mp3
  String get boostJump => 'assets/audio/boost_jump.mp3';

  /// File path: assets/audio/boost_speed.mp3
  String get boostSpeed => 'assets/audio/boost_speed.mp3';

  /// File path: assets/audio/jump.mp3
  String get jump => 'assets/audio/jump.mp3';

  /// List of all assets
  List<String> get values => [
    background,
    boostGravity,
    boostJump,
    boostSpeed,
    jump,
  ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/catalonia_flag.png
  AssetGenImage get cataloniaFlag =>
      const AssetGenImage('assets/images/catalonia_flag.png');

  /// Directory path: assets/images/components
  $AssetsImagesComponentsGen get components =>
      const $AssetsImagesComponentsGen();

  /// File path: assets/images/icon.png
  AssetGenImage get icon => const AssetGenImage('assets/images/icon.png');

  /// File path: assets/images/loading_ball.png
  AssetGenImage get loadingBall =>
      const AssetGenImage('assets/images/loading_ball.png');

  /// Directory path: assets/images/parallax
  $AssetsImagesParallaxGen get parallax => const $AssetsImagesParallaxGen();

  /// File path: assets/images/splash_screen.png
  AssetGenImage get splashScreen =>
      const AssetGenImage('assets/images/splash_screen.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    cataloniaFlag,
    icon,
    loadingBall,
    splashScreen,
  ];
}

class $AssetsLicensesGen {
  const $AssetsLicensesGen();

  /// Directory path: assets/licenses/poppins
  $AssetsLicensesPoppinsGen get poppins => const $AssetsLicensesPoppinsGen();
}

class $AssetsImagesComponentsGen {
  const $AssetsImagesComponentsGen();

  /// File path: assets/images/components/ball.png
  AssetGenImage get ball =>
      const AssetGenImage('assets/images/components/ball.png');

  /// File path: assets/images/components/floor.png
  AssetGenImage get floor =>
      const AssetGenImage('assets/images/components/floor.png');

  /// File path: assets/images/components/goal.png
  AssetGenImage get goal =>
      const AssetGenImage('assets/images/components/goal.png');

  /// File path: assets/images/components/gravity_boost.png
  AssetGenImage get gravityBoost =>
      const AssetGenImage('assets/images/components/gravity_boost.png');

  /// File path: assets/images/components/jump_boost.png
  AssetGenImage get jumpBoost =>
      const AssetGenImage('assets/images/components/jump_boost.png');

  /// File path: assets/images/components/speed_boost.png
  AssetGenImage get speedBoost =>
      const AssetGenImage('assets/images/components/speed_boost.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    ball,
    floor,
    goal,
    gravityBoost,
    jumpBoost,
    speedBoost,
  ];
}

class $AssetsImagesParallaxGen {
  const $AssetsImagesParallaxGen();

  /// File path: assets/images/parallax/layer1.png
  AssetGenImage get layer1 =>
      const AssetGenImage('assets/images/parallax/layer1.png');

  /// File path: assets/images/parallax/layer2.png
  AssetGenImage get layer2 =>
      const AssetGenImage('assets/images/parallax/layer2.png');

  /// File path: assets/images/parallax/layer3.png
  AssetGenImage get layer3 =>
      const AssetGenImage('assets/images/parallax/layer3.png');

  /// List of all assets
  List<AssetGenImage> get values => [layer1, layer2, layer3];
}

class $AssetsLicensesPoppinsGen {
  const $AssetsLicensesPoppinsGen();

  /// File path: assets/licenses/poppins/OFL.txt
  String get ofl => 'assets/licenses/poppins/OFL.txt';

  /// List of all assets
  List<String> get values => [ofl];
}

class Assets {
  const Assets._();

  static const $AssetsAudioGen audio = $AssetsAudioGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsLicensesGen licenses = $AssetsLicensesGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName, {this.size, this.flavors = const {}});

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
