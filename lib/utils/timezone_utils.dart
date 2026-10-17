import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Lazy loader for the IANA timezone database.
///
/// Decoding the database is synchronous and noticeably slow (especially in
/// debug builds), so it is kept off the startup path: main warms it up after
/// the first frame, and [timeZoneLocation] loads it on demand if a trip form
/// needs it before that.
class TimeZones {
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }
}

/// [tz.getLocation] that makes sure the timezone database is loaded first.
tz.Location timeZoneLocation(String name) {
  TimeZones.ensureInitialized();
  return tz.getLocation(name);
}
