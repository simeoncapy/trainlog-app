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
  String get loginButton => 'ログイン';

  @override
  String get logoutButton => 'ログアウト';

  @override
  String get createAccountButton => 'アカウントを作成';

  @override
  String get emailLabel => 'メールアドレス';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailHelper => 'パスワードを忘れたときのため';

  @override
  String get emailRequiredLabel => 'メールアドレスは必須です';

  @override
  String get emailValidLabel => '有効なメールアドレスを入力してください';

  @override
  String get usernameLabel => 'ユーザー名';

  @override
  String get usernameRequiredLabel => 'ユーザー名は必須です';

  @override
  String get passwordLabel => 'パスワード';

  @override
  String get passwordShowLabel => 'パスワードを表示';

  @override
  String get passwordHideLabel => 'パスワードを非表示';

  @override
  String get passwordRequiredLabel => 'パスワードは必須です';

  @override
  String get createAccountButtonShort => '作成';

  @override
  String get loginToYourAccount => 'アカウントにログイン';

  @override
  String menuHello(Object username) {
    return 'こんにちは $usernameさん';
  }

  @override
  String get connectionError => 'ログインに失敗しました。資格情報を確認してください。';

  @override
  String get refreshCompleted => '更新が完了しました';

  @override
  String get nextButton => '次へ';

  @override
  String get previousButton => '戻る';

  @override
  String get validateButton => '確認';

  @override
  String get nameField => '名前';

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
  String settingsCache(Object size) {
    return 'キャッシュされたデータ ($size MiB)';
  }

  @override
  String get settingsCacheClearButton => '消す';

  @override
  String get settingsCacheClearConfirmTitle => 'キャッシュを消しますか?';

  @override
  String get settingsCacheClearConfirmMessage =>
      'キャッシュデータを削除してもよろしいですか？この操作は元に戻せません。次回のアプリの読み込みに時間がかかる可能性があります。';

  @override
  String get settingsCacheClearedMessage => 'キャッシュが正常に消されました。';

  @override
  String get settingsDisplayUserMarker => '現在の位置を表示する';

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
  String get typeTrain => '列車';

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
  String get typeAerialway => '索道';

  @override
  String get typeWalk => '散歩';

  @override
  String get typePoi => '地点';

  @override
  String get typeCycle => '自転車';

  @override
  String get typeHelicopter => 'ヘリコプター';

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

  @override
  String tripsDetailTitle(Object vehicle) {
    return '$vehicleでの旅行';
  }

  @override
  String get tripsDetailsTitleOperator => '事業者: ';

  @override
  String get tripsDetailsTitleVehicle => '車両名: ';

  @override
  String get tripsDetailsTitleSeat => '座席: ';

  @override
  String get tripsDetailsTitlePrice => '価格: ';

  @override
  String tripsDetailPurchasedDate(Object date) {
    return '$dateに購入';
  }

  @override
  String get tripsDetailsTitleNotes => 'メモ: ';

  @override
  String get tripsDetailsEditButton => '編集';

  @override
  String get tripsDetailsDeleteButton => '消す';

  @override
  String get tripsFilterAllCountry => '全て';

  @override
  String get tripsFilterAllOperator => '全て';

  @override
  String get tripsFilterAllYears => '全ての年';

  @override
  String get tripsFilterKeyword => 'キーワード';

  @override
  String get tripsFilterDateFrom => '日付';

  @override
  String get tripsFilterDateTo => 'まで (任意)';

  @override
  String get tripsFilterCountry => '国';

  @override
  String get tripsFilterOperator => '事業者';

  @override
  String get tripsFilterType => '乗り物のタイプ';

  @override
  String get filterClearButton => 'フィルターを消す';

  @override
  String get graphTypeOperator => '事業者';

  @override
  String get graphTypeCountry => '国';

  @override
  String get graphTypeYears => '年';

  @override
  String get graphTypeMaterial => '車両名';

  @override
  String get graphTypeItinerary => '道順';

  @override
  String graphTypeStations(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': '駅',
      'plane': '空港',
      'bus': '停留場',
      'tram': '停留場',
      'metro': '駅',
      'ferry': '港',
      'helicopter': 'ヘリポート',
      'aerialway': '駅',
      'other': '場所',
    });
    return '$_temp0';
  }

  @override
  String get statisticsGraphUnitTrips => '旅行';

  @override
  String get statisticsGraphUnitDistance => '距離';

  @override
  String get statisticsGraphUnitDuration => '時間';

  @override
  String get statisticsGraphUnitCo2 => 'CO2';

  @override
  String get statisticsDisplayFilters => 'フィルターを表示';

  @override
  String get statisticsHideFilters => 'フィルターを非表示';

  @override
  String get statisticsTripsUnitBase => '回';

  @override
  String get statisticsTripsUnitKilo => '千回';

  @override
  String get statisticsTripsUnitMega => '百万回';

  @override
  String get statisticsTripsUnitGiga => '十億回';

  @override
  String get statisticsOtherLabel => 'その他';

  @override
  String get statisticsTotalLabel => '総計';

  @override
  String get statisticsUnitLabel => '単位：';

  @override
  String get statisticsNoDataLabel => 'データがありません';

  @override
  String get internationalWaters => '公海';

  @override
  String get addTripPageTitle => '旅行を加える';

  @override
  String get addTripStepBasics => '基本';

  @override
  String get addTripStepDate => '日付';

  @override
  String get addTripStepDetails => '詳細';

  @override
  String get addTripStepPath => '道筋';

  @override
  String get addTripStepValidate => '確認';

  @override
  String get addTripTransportationMode => 'Transportation mode';

  @override
  String get addTripManualDeparture => '出発地を手動で設定';

  @override
  String get addTripManualArrival => '到着地を手動で設定';

  @override
  String get addTripDeparture => '出発地';

  @override
  String get addTripArrival => '到着地';

  @override
  String get addTripLatitudeShort => '緯度';

  @override
  String get addTripLongitudeShort => '経度';

  @override
  String get addTripOperator => '事業者';

  @override
  String get addTripOperatorHelper => '複数はカンマで区切ります';

  @override
  String get addTripOperatorPlaceholderLogo => '事業者を選択してください';

  @override
  String get addTripLine => '路線';

  @override
  String get addTripDateTypePrecise => '精密';

  @override
  String get addTripDateTypeUnknown => '不明';

  @override
  String get addTripDateTypeDate => '日付';

  @override
  String get addTripStartDate => '出発日';

  @override
  String get addTripEndDate => '到着日';

  @override
  String get addTripDuration => '時間';

  @override
  String get addTripPast => '過去';

  @override
  String get addTripFuture => '未来';

  @override
  String get addTripFacultative => '任意項目';

  @override
  String get addTripMaterial => '車両名';

  @override
  String get addTripRegistration => '登録番号';

  @override
  String get addTripSeat => '座席';

  @override
  String get addTripNotes => 'メモ';

  @override
  String get addTripTicketTitle => '乗車券';

  @override
  String get addTripTicketPrice => '運賃';

  @override
  String get addTripPurchaseDate => '購入日';
}
