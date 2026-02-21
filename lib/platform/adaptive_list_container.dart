import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveListContainer extends StatelessWidget {
  final List<Widget>? children;

  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;

  /// If true, uses insetGrouped (iOS “Settings” style)
  final bool insetGrouped;

  /// If true, iOS uses CupertinoListSection for the grouped look.
  /// Note: CupertinoListSection requires a List<Widget>, so it builds items eagerly.
  /// If you want true lazy building on iOS too, set this to false.
  final bool iosUseCupertinoSection;

  // Common ListView parameters
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final bool? primary;

  const AdaptiveListContainer({
    super.key,
    required List<Widget> this.children,
    this.insetGrouped = true,
    this.iosUseCupertinoSection = true,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.primary,
  })  : itemCount = null,
        itemBuilder = null;

  const AdaptiveListContainer.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.insetGrouped = true,
    this.iosUseCupertinoSection = true,
    this.controller,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.primary,
  }) : children = null;

  bool get _usesBuilder => itemBuilder != null;

  List<Widget> _buildAllChildren(BuildContext context) {
    if (children != null) return children!;
    return List<Widget>.generate(
      itemCount!,
      (index) => itemBuilder!(context, index),
      growable: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isApple) {
      // Material: can be fully lazy with ListView.builder
      if (_usesBuilder) {
        return ListView.builder(
          controller: controller,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          primary: primary,
          itemCount: itemCount,
          itemBuilder: itemBuilder!,
        );
      }

      return ListView(
        controller: controller,
        physics: physics,
        padding: padding,
        shrinkWrap: shrinkWrap,
        primary: primary,
        children: children!,
      );
    }

    // iOS
    if (!iosUseCupertinoSection) {
      // True lazy building on iOS, but without CupertinoListSection grouped styling.
      if (_usesBuilder) {
        return ListView.builder(
          controller: controller,
          physics: physics,
          padding: padding,
          shrinkWrap: shrinkWrap,
          primary: primary,
          itemCount: itemCount,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: itemBuilder!(context, index),
          ),
        );
      }

      return ListView(
        controller: controller,
        physics: physics,
        padding: padding,
        shrinkWrap: shrinkWrap,
        primary: primary,
        children: children!
            .map((w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: w,
                ))
            .toList(growable: false),
      );
    }

    // iOS grouped style (CupertinoListSection needs a full List<Widget>)
    final sectionChildren = _buildAllChildren(context)
        .map((w) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: w,
            ))
        .toList(growable: false);

    final iosBlockColor =
      CupertinoColors.secondarySystemFill.resolveFrom(context);

    final section = insetGrouped
        ? CupertinoListSection.insetGrouped(
            backgroundColor: CupertinoColors.transparent,
            decoration: BoxDecoration(
              color: iosBlockColor
            ),
            children: sectionChildren
          )
        : CupertinoListSection(children: sectionChildren);

    return ListView(
      controller: controller,
      physics: physics,
      padding: padding,
      shrinkWrap: shrinkWrap,
      primary: primary,
      children: [section],
    );
  }
}