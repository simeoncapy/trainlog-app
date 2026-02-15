import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppPlatform {
  static const bool isWeb = kIsWeb;

  static final bool isApple = 
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  static final bool isMaterial = !isApple;
}

class AdaptiveIcons {
  static final bool isA = AppPlatform.isApple; // condense writting

  // Nav bar
  static final IconData map =         isA ? CupertinoIcons.map_fill : Icons.map;
  static final IconData trips = Icons.commute;
  static final IconData ranking =     isA ? CupertinoIcons.rosette : Icons.emoji_events;
  static final IconData statistics =  isA ? CupertinoIcons.chart_bar_alt_fill : Icons.bar_chart;
  static final IconData other =       isA ? CupertinoIcons.ellipsis : Icons.more_horiz;

  // Drawer menu
  static final IconData coverage =    isA ? CupertinoIcons.percent : Icons.percent;
  static final IconData tags =        isA ? CupertinoIcons.tag_fill : Icons.label;
  static final IconData tickets =     isA ? CupertinoIcons.ticket_fill : Icons.confirmation_number;
  static final IconData friends =     isA ? CupertinoIcons.person_2_fill : Icons.people;
  static final IconData smartPrerecorder = Symbols.checkbook;
  static final IconData settings =    isA ? CupertinoIcons.settings_solid : Icons.settings;
  static final IconData info =        isA ? CupertinoIcons.info_circle_fill : Icons.info;

  // Header menu
  static final IconData logout =      isA ? CupertinoIcons.square_arrow_right_fill : Icons.logout;
  static final IconData inbox =       isA ? CupertinoIcons.mail_solid : Icons.inbox;
  static final IconData ok =          isA ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle;
  static final IconData warning =     isA ? CupertinoIcons.exclamationmark_triangle_fill : Icons.warning;
  static final IconData error =       isA ? CupertinoIcons.exclamationmark_octagon_fill : Icons.error;

  // Settings
  // TODO

  // Pages
  static final IconData add = isA ? CupertinoIcons.add : Icons.add;
  static final IconData filter = isA ? CupertinoIcons.slider_horizontal_3 : Icons.filter_alt;
  static final IconData edit = isA ? CupertinoIcons.pen : Icons.edit;
}
