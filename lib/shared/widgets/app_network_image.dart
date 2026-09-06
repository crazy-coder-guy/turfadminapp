import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/providers.dart';

class AppNetworkImage extends StatefulWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  bool get isBackendUrl => url.startsWith(AppConfig.apiBaseUrl);

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  Future<Uint8List>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  void _load() {
    if (!widget.isBackendUrl) return;
    final container = ProviderScope.containerOf(context, listen: false);
    _bytesFuture = container.read(apiClientProvider).getBytes(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isBackendUrl) {
      return CachedNetworkImage(
        imageUrl: widget.url,
        fit: widget.fit,
        placeholder: widget.placeholder != null ? (_, _) => widget.placeholder! : null,
        errorWidget: (_, _, _) => widget.errorWidget ?? const SizedBox.shrink(),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.placeholder ?? const SizedBox.shrink();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorWidget ?? const SizedBox.shrink();
        }
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          errorBuilder: (_, _, _) => widget.errorWidget ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
