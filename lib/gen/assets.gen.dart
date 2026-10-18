// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

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

class $AssetsImagesComponentsGen {
  const $AssetsImagesComponentsGen();

  /// File path: assets/images/components/ball.png
  AssetGenImage get ball =>
      const AssetGenImage('assets/images/components/ball.png');

  /// List of all assets
  List<AssetGenImage> get values => [ball];
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

abstract final class Assets {
  static const $AssetsAudioGen audio = $AssetsAudioGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

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

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
