// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'トレインログ';

  @override
  String get language => '日本語';

  @override
  String get appVersion => 'アプリバージョン:';

  @override
  String get appVersionCopied => 'バージョン番号をコピーしました。';

  @override
  String get mainMenuButtonTooltip => 'メニューを開く';

  @override
  String get filterButton => 'フィルター';

  @override
  String get descendingOrder => '降順';

  @override
  String get ascendingOrder => '昇順';

  @override
  String get deleteAll => 'すべて削除';

  @override
  String get deleteSelection => '選択を削除';

  @override
  String get loginButton => 'ログイン';

  @override
  String get logoutButton => 'ログアウト';

  @override
  String get loggedOut => 'ログアウトしました';

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
  String get continueButton => '続く';

  @override
  String get nameField => '名前';

  @override
  String get auto => '自動';

  @override
  String get energy => 'エネルギー';

  @override
  String get energyElectric => '電動';

  @override
  String get energyElectricShort => '電動';

  @override
  String get energyThermic => 'ガソリン';

  @override
  String get energyThermicShort => 'ガソリン';

  @override
  String get energyHydrogen => '水素';

  @override
  String get energyHydrogenShort => 'H2';

  @override
  String get manual => '手動';

  @override
  String get fillRequiredFields => '必須項目を入力してください';

  @override
  String get facultative => '任意';

  @override
  String get visibility => '公開範囲';

  @override
  String get visibilityPublic => '公開';

  @override
  String get visibilityFriends => 'フレンドのみ';

  @override
  String get visibilityPrivate => '非公開';

  @override
  String get visibilityRestricted => '制限付き';

  @override
  String get helpTitle => '使い方';

  @override
  String get pageNotImplementedYet =>
      'このページはまだアプリに実装されていません。そのため、Webサイト版が表示されます。ユーザーインターフェースが最適でない場合があります。';

  @override
  String get departureSingleCharacter => '発';

  @override
  String get arrivalSingleCharacter => '着';

  @override
  String get locationServicesDisabled => '位置情報サービスが無効になっています';

  @override
  String get locationPermissionDenied => '位置情報の許可が拒否されました';

  @override
  String get duplicateBtnLabel => '複製';

  @override
  String get settingsAppCategory => 'アプリ設定';

  @override
  String get settingsMapCategory => '地図設定';

  @override
  String get settingsAccountCategory => 'アカウント設定';

  @override
  String get settingsDangerZoneCategory => '危険地帯';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsThemeMode => 'テーマモード';

  @override
  String get settingsDark => 'ダーク';

  @override
  String get settingsLight => 'ライト';

  @override
  String get settingsDateFormat => '年月日の順序';

  @override
  String get settingsHourFormat12 => '12時間形式';

  @override
  String get settingsExampleShort => '例:';

  @override
  String get settingsCurrency => 'デフォルト通貨';

  @override
  String get settingsSprRadius => 'ジオログの駅検索の最大半径';

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
  String get settingsMapColorPaletteColourBlind => '色覚異常者用パレット';

  @override
  String get settingsMapColorPaletteTrainlogRed => '赤';

  @override
  String get settingsMapColorPaletteTrainlogGreen => '緑';

  @override
  String get settingsMapColorPaletteTrainlogBlue => '青';

  @override
  String get settingsMapColorPaletteVibrantTones => '鮮やかな色合い';

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
  String get settingsDeleteAccount => 'アカウントを削除する';

  @override
  String get settingsDeleteAccountRequest => '申請';

  @override
  String settingsDeleteAccountError(Object email) {
    return 'メールクライアントを開けません。$email に申請してください';
  }

  @override
  String get settingsHideWarningMessage => '警告メッセージを非表示にする';

  @override
  String get settingsAccountLeaderboard => '公開ランキングに表示する';

  @override
  String get settingsAccountFriendSearch => 'フレンド検索に表示する';

  @override
  String get settingsAccountAppearGlobal => 'グローバルライブマップに表示する';

  @override
  String get settingsAccountAppearGlobalSubtitle => '(公共交通機関のみ、個人の旅行は除外されます)';

  @override
  String get settingsAccountVisibility => '他の人への公開範囲';

  @override
  String get settingsAccountVisibilitPrivateHelper =>
      'あなたのアカウントは完全に非公開のままです。誰も詳細やコンテンツを見ることはできません。';

  @override
  String get settingsAccountVisibilitRestrictedHelper =>
      '個々の旅行は、旅行IDを使用して共有できますが、個人データは非表示になります。ただし、公開プロフィールにはアクセスできません。';

  @override
  String get settingsAccountVisibilitPublicHelper =>
      'あなたの公開プロフィールは、あなたのユーザー名を通じてアクセスできます。';

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
  String get menuSmartPrerecorderTitle => 'ジオログ';

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
  String get tripsDetailsDeleteDialogTitle => 'この旅行を削除しますか？';

  @override
  String get tripsDetailsDeleteDialogMessage => 'この旅行を削除してもよろしいですか？';

  @override
  String get tripsDetailsDeleteDialogConfirmButton => '削除';

  @override
  String get tripsDetailsDeleteFailed => '旅行の削除に失敗しました';

  @override
  String get tripsDetailsDeleteSuccess => '旅行が正常に削除されました';

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
  String typeStation(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': '駅',
      'plane': '空港',
      'bus': '停留所',
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
  String typeStations(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': '駅',
      'plane': '空港',
      'bus': '停留所',
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
  String typeStationAddress(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': '駅の住所',
      'plane': '空港の住所',
      'bus': '停留所の住所',
      'tram': '停留場の住所',
      'metro': '駅の住所',
      'ferry': '港の住所',
      'helicopter': 'ヘリポートの住所',
      'aerialway': '駅の住所',
      'other': '場所の住所',
    });
    return '$_temp0';
  }

  @override
  String enterStation(String direction, String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': '出発駅を入力してください',
      'plane': '出発空港を入力してください',
      'bus': '出発停留所を入力してください',
      'tram': '出発停留場を入力してください',
      'metro': '出発駅を入力してください',
      'ferry': '出発港を入力してください',
      'helicopter': '出発ヘリポートを入力してください',
      'aerialway': '出発駅を入力してください',
      'other': '出発場所を入力してください',
    });
    String _temp1 = intl.Intl.selectLogic(type, {
      'train': '到着駅を入力してください',
      'plane': '到着空港を入力してください',
      'bus': '到着停留所を入力してください',
      'tram': '到着停留場を入力してください',
      'metro': '到着駅を入力してください',
      'ferry': '到着港を入力してください',
      'helicopter': '到着ヘリポートを入力してください',
      'aerialway': '到着駅を入力してください',
      'other': '到着場所を入力してください',
    });
    String _temp2 = intl.Intl.selectLogic(type, {
      'train': '駅を入力してください',
      'plane': '空港を入力してください',
      'bus': '停留所を入力してください',
      'tram': '停留場を入力してください',
      'metro': '駅を入力してください',
      'ferry': '港を入力してください',
      'helicopter': 'ヘリポートを入力してください',
      'aerialway': '駅を入力してください',
      'other': '場所を入力してください',
    });
    String _temp3 = intl.Intl.selectLogic(direction, {
      'departure': '$_temp0',
      'arrival': '$_temp1',
      'other': '$_temp2',
    });
    return '$_temp3';
  }

  @override
  String manualNameStation(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': '駅の手動名称',
      'plane': '空港の手動名称',
      'bus': '停留所の手動名称',
      'tram': '停留場の手動名称',
      'metro': '駅の手動名称',
      'ferry': '港の手動名称',
      'helicopter': 'ヘリポートの手動名称',
      'aerialway': '駅の手動名称',
      'other': '場所の手動名称',
    });
    return '$_temp0';
  }

  @override
  String searchStationHint(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': '駅を検索...',
      'plane': '空港を検索...',
      'bus': '停留所を検索...',
      'tram': '停留場を検索...',
      'metro': '駅を検索...',
      'ferry': '港を検索...',
      'helicopter': 'ヘリポートを検索...',
      'aerialway': '駅を検索...',
      'other': '場所を検索...',
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
  String get statisticsPieWip => '円グラフは仕掛品です';

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
  String get addTripTransportationMode => '交通手段';

  @override
  String get addTripImportFr24 => 'FR24からフライトデータをインポートする';

  @override
  String get addTipSearchStation => 'Search ';

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
  String get addTripMapUsageHelper =>
      '手動モードでは座標を直接入力することも、地図を拡大してマーカーを目的の位置まで移動することもできます。';

  @override
  String get addTripOperator => '事業者';

  @override
  String get addTripOperatorHelper => '不明な事業者は、カンマまたはEnterで確定';

  @override
  String get addTripOperatorHint => '事業者を検索';

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
  String get timezoneInformation => 'タイムゾーンは、出発地点と到着地点の座標に基づいて決定されます。';

  @override
  String get addTripDepartureAfterArrival => '出発時間は到着時間より後です!';

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

  @override
  String get continueTripButton => '確認して旅行を続ける';

  @override
  String get addTripPathUseNewRouter => '新しいルーターを使用する';

  @override
  String addTripNameEnd(String departure, String arrival) {
    return '$departureから$arrivalまで';
  }

  @override
  String get addTripPathHelp =>
      '新しいルーターはベータ版で、電化を示しています。\n\nルーター（新旧）は、電車、路面電車、地下鉄で同じです。希望の経路にルートを設定するには、ピンの配置を微調整する必要があるかもしれません。';

  @override
  String get addTicketPageTitle => '新しい乗車券';

  @override
  String get addTagPageTitle => '新しいタグ';

  @override
  String get addTripPathRoutingErrorBannerMessage =>
      'ルーティングエラーが検出されました。旅行の経路を確認し、必要に応じてピンポイントを調整してください。';

  @override
  String get addTripRecordingMsg => '旅行が記録されています。お待ちください';

  @override
  String get addTripFinishMsg => '旅行が正常に追加されました';

  @override
  String addTripFinishErrorMsg(String errorCode) {
    return '旅行の追加中にエラーが発生しました。もう一度お試しください（エラー：$errorCode）。';
  }

  @override
  String get addTripFinishFeedbackWarning =>
      '旅行は追加されましたが、サーバーからのフィードバックが不完全です。旅行をリフレッシュして、詳細を確認してください。';

  @override
  String get aboutPageAboutSubPageTitle => 'Trainlog';

  @override
  String get aboutPageHowToSubPageTitle => '使い方';

  @override
  String get aboutPagePrivacySubPageTitle => 'プライバシ';

  @override
  String get supportTrainlogButton => 'トレインログをサポートする';

  @override
  String get joinDiscordButton => 'Discordでコミュニティに参加しましょう';

  @override
  String get websiteRepoButton => 'ウェブサイトのリポジトリ';

  @override
  String get applicationRepoButton => 'アプリケーションのリポジトリ';

  @override
  String get pageNotAvailableInUserLanguage =>
      'このページは現在、日本語ではご利用いただけないため、英語で表示されています。';

  @override
  String get tableOfContents => '目次';

  @override
  String get prerecorderExplanationTitle => 'ジオログとは';

  @override
  String get prerecorderExplanation =>
      'ジオログツールは、スマートな事前記録ツールです。記録ボタンをクリックすると、現在の座標と日時が自動的に保存されます。その後、2つのログを選択して、保存したデータを使って新しい旅程を作成できます。';

  @override
  String get prerecorderExplanationStation =>
      'このツールは駅名を自動的に検索し、見つかった場合は表示します（鉄道・バス・フェリーのみ対応）。最も近い駅（設定で半径を変更できます）が表示され、最適な駅を選択できます。';

  @override
  String get prerecorderExplanationDelete => '旅行が作成されると、2つのログは自動的に削除されます。';

  @override
  String get prerecorderExplanationPrivacy => 'データはデバイスにのみ保存されます。';

  @override
  String get prerecorderRecordButton => '記録';

  @override
  String get prerecorderCreateTripButton => '旅行を作成する';

  @override
  String get prerecorderNoData => 'データは記録されていません';

  @override
  String get prerecorderUnknownStation => '不明な駅';

  @override
  String get prerecorderDeleteSelectionConfirm =>
      '選択内容を削除してもよろしいですか? この操作は元に戻せません。';

  @override
  String get prerecorderDeleteAllConfirm =>
      '記録されたログをすべて削除してもよろしいですか? この操作は元に戻せません。';

  @override
  String get prerecorderSelectStation => '駅を選択する';

  @override
  String get prerecorderSelectClosest => '最も近い駅を選択する';

  @override
  String get prerecorderNoStationReachable => '近くに駅がありません';

  @override
  String prerecorderAway(String distance) {
    return '$distanceメートル離れたところ';
  }

  @override
  String prerecorderStationsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countの駅が見つかりました',
      one: '1つの駅が見つかりました',
      zero: '駅が見つかりません',
    );
    return '$_temp0';
  }
}
