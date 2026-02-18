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

  // General
  static final IconData delete =      isA ? CupertinoIcons.delete : Icons.delete;
  static final IconData copy =        isA ? CupertinoIcons.doc_on_doc : Icons.copy;
  static final IconData share =       isA ? CupertinoIcons.share : Icons.share;
  static final IconData mail =        isA ? CupertinoIcons.mail : Icons.mail;

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
  static final IconData smartPrerecorder = isA ? CupertinoIcons.pencil_ellipsis_rectangle : Symbols.checkbook;
  static final IconData settings =    isA ? CupertinoIcons.settings_solid : Icons.settings;
  static final IconData info =        isA ? CupertinoIcons.info_circle_fill : Icons.info;

  // Header menu
  static final IconData logout =      isA ? CupertinoIcons.square_arrow_right_fill : Icons.logout;
  static final IconData inbox =       isA ? CupertinoIcons.tray : Icons.inbox;
  static final IconData ok =          isA ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle;
  static final IconData warning =     isA ? CupertinoIcons.exclamationmark_triangle_fill : Icons.warning;
  static final IconData error =       isA ? CupertinoIcons.exclamationmark_octagon_fill : Icons.error;

  // Settings
  static final IconData theme =       isA ? CupertinoIcons.moon : Icons.dark_mode;
  static final IconData language =    isA ? CupertinoIcons.globe : Icons.language;
  static final IconData date =        isA ? CupertinoIcons.calendar : Icons.date_range;
  static final IconData hour =        isA ? CupertinoIcons.clock : Icons.watch;
  static final IconData currency =    isA ? CupertinoIcons.money_dollar_circle : Icons.currency_exchange;
  static final IconData radar =       isA ? CupertinoIcons.location_circle : Icons.radar;
  static final IconData warningMsg =  isA ? CupertinoIcons.exclamationmark_triangle : Icons.warning;
  static final IconData layers =      isA ? CupertinoIcons.layers : Icons.layers;
  static final IconData palette =     isA ? CupertinoIcons.paintbrush : Icons.palette;
  static final IconData position =    isA ? CupertinoIcons.location : Icons.my_location;
  static final IconData visibility =  isA ? CupertinoIcons.eye : Icons.visibility;
  static final IconData world =       isA ? CupertinoIcons.map : Icons.public;
  static final IconData cache =       isA ? CupertinoIcons.cloud_download : Icons.cloud_download;
  static final IconData deleteAccount =isA ? CupertinoIcons.person_crop_circle_badge_xmark : Icons.no_accounts;
  static final IconData version =     isA ? CupertinoIcons.info_circle : Icons.info_outline;
  static final IconData instance =    isA ? CupertinoIcons.link : Icons.http;

  // Pages
  static final IconData add = isA ? CupertinoIcons.add : Icons.add;
  static final IconData filter = isA ? CupertinoIcons.line_horizontal_3_decrease : Icons.filter_alt;
  static final IconData edit = isA ? CupertinoIcons.pen : Icons.edit;
}
