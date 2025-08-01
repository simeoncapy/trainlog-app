// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'トレーンログ';

  @override
  String get language => '日本語';

  @override
  String get mainMenuButtonTooltip => 'メニューを開く';

  @override
  String get filterButton => 'フィルター';

  @override
  String get settingsAppCategory => 'アプリ設定';

  @override
  String get settingsMapCategory => '地図設定';

  @override
  String get settingsAccountCategory => 'アカウント設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsThemeMode => 'テーマモード';

  @override
  String get settingsDark => 'ダーク';

  @override
  String get settingsLight => 'ライト';

  @override
  String get settingsSystem => 'システム';

  @override
  String get settingsMapPathDisplayOrder => '地図上の経路の表示順';

  @override
  String get settingMapPathDisplayOrderByCreation => '作成日順';

  @override
  String get settingMapPathDisplayOrderByTrip => '旅行日順';

  @override
  String get settingMapPathDisplayOrderByTripAndPlane => '旅行日順（上空のフライトを優先）';

  @override
  String get settingsMapColorPalette => '旅行のカラーパレット';

  @override
  String get settingsMapColorPaletteTrainlogWeb => 'Trainlog Web';

  @override
  String get settingsMapColorPaletteTrainlogVariation => 'Trainlog バリエーション';

  @override
  String get settingsMapColorPaletteTrainlogRed => '赤';

  @override
  String get settingsMapColorPaletteTrainlogGreen => '緑';

  @override
  String get settingsMapColorPaletteTrainlogBlue => '青';

  @override
  String get menuMapTitle => '地図';

  @override
  String get menuTripsTitle => '旅行';

  @override
  String get menuRankingTitle => 'ランキング';

  @override
  String get menuStatisticsTitle => '統計';

  @override
  String get menuCoverageTitle => '走破率';

  @override
  String get menuTagsTitle => 'タグ';

  @override
  String get menuTicketsTitle => '乗車券';

  @override
  String get menuFriendsTitle => 'フレンド';

  @override
  String get menuSettingsTitle => '設定';

  @override
  String get menuAboutTitle => 'ついて';

  @override
  String get tripPathLoading => '旅行のパスを読み込んでいます。お待ちください';

  @override
  String get yearTitle => '年';

  @override
  String get yearAllList => '全て';

  @override
  String get yearPastList => '過去';

  @override
  String get yearFutureList => '未来';

  @override
  String get yearYearList => '年...';

  @override
  String get typeTitle => '乗り物のタイプ';

  @override
  String get typeTrain => '電車';

  @override
  String get typeTram => '路面電車';

  @override
  String get typeMetro => '地下鉄';

  @override
  String get typeBus => 'バス';

  @override
  String get typeCar => '車';

  @override
  String get typePlane => '飛行機';

  @override
  String get typeFerry => 'フェリー';

  @override
  String get tripsTableHeaderOriginDestination => '出発・到着駅';

  @override
  String get tripsTableHeaderOrigin => '出発駅';

  @override
  String get tripsTableHeaderDestination => '到着駅';

  @override
  String get tripsTableHeaderStartTime => '出発時刻';

  @override
  String get tripsTableHeaderEndTime => '到着時刻';

  @override
  String get tripsTableHeaderOperator => '事業者';

  @override
  String get tripsTableHeaderLineName => '路線';

  @override
  String get tripsTableHeaderTripLength => '距離';
}
