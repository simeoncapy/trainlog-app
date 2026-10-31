import 'package:trainlog_app/data/models/geolog_note.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';

/// A trip field both Geolog notes fill in with different values, which the
/// user has to settle before the trip form is built.
enum GeologNoteConflict { price, energy, visibility }

/// Which Geolog of the pair a conflicting value is taken from.
enum GeologNoteSide { departure, arrival }

/// Merges the notes of a departure and an arrival Geolog into a trip form.
///
/// - The delays go to their own endpoint.
/// - Operators are merged into one list, departure first, without repeats.
/// - Free-text fields are concatenated, departure first; a value both notes
///   share is kept once. Short fields are joined with ", ", the memo with a
///   line break.
/// - The ticket price (with its currency and purchase date), the energy and
///   the visibility are taken from whichever note has them; when both have
///   different values the user picks a side (see [conflicts]).
///
/// The date and time of each note are applied with the endpoint itself (see
/// `PreRecordModel.effectiveDateTime`).
abstract final class GeologNoteMerger {
  static const shortFieldSeparator = ', ';
  static const memoSeparator = '\n';

  /// Fields where both notes carry a value and the values differ.
  static List<GeologNoteConflict> conflicts(
    GeologNote? departure,
    GeologNote? arrival,
  ) {
    if (departure == null || arrival == null) return const [];
    return [
      if (departure.price != null &&
          arrival.price != null &&
          (departure.price != arrival.price ||
              departure.currency != arrival.currency))
        GeologNoteConflict.price,
      if (departure.energy != null &&
          arrival.energy != null &&
          departure.energy != arrival.energy)
        GeologNoteConflict.energy,
      if (departure.visibility != null &&
          arrival.visibility != null &&
          departure.visibility != arrival.visibility)
        GeologNoteConflict.visibility,
    ];
  }

  /// Writes the merged notes into [model]. [choices] settles each field
  /// returned by [conflicts]; a conflict left out falls back to the
  /// departure.
  static void apply(
    TripFormModel model, {
    required GeologNote? departure,
    required GeologNote? arrival,
    Map<GeologNoteConflict, GeologNoteSide> choices = const {},
  }) {
    if (departure == null && arrival == null) return;

    model.delayDepartureMinute = departure?.delayMinutes;
    model.delayDepartureMinuteMode = departure?.delayMinutes != null;
    model.delayArrivalMinute = arrival?.delayMinutes;
    model.delayArrivalMinuteMode = arrival?.delayMinutes != null;

    final operators = <String>[
      ...?departure?.operators,
      ...?arrival?.operators,
    ];
    model.selectedOperators = operators.toSet().toList();

    model.line = join(departure?.line, arrival?.line, shortFieldSeparator);
    model.material = join(
      departure?.material,
      arrival?.material,
      shortFieldSeparator,
    );
    model.registration = join(
      departure?.registration,
      arrival?.registration,
      shortFieldSeparator,
    );
    model.seat = join(departure?.seat, arrival?.seat, shortFieldSeparator);
    model.notes = join(departure?.memo, arrival?.memo, memoSeparator);

    // The ticket: price, currency and purchase date travel together.
    final ticket = _pick(
      departure,
      arrival,
      has: (n) => n.price != null,
      conflict: GeologNoteConflict.price,
      choices: choices,
    );
    if (ticket != null) {
      model.price = ticket.price;
      model.currencyCode = ticket.currency;
      model.purchaseDate =
          ticket.purchaseDate ??
          // Same ticket on both sides: either purchase date will do.
          (_sameTicket(departure, arrival)
              ? (departure?.purchaseDate ?? arrival?.purchaseDate)
              : null);
    }

    final energy = _pick(
      departure,
      arrival,
      has: (n) => n.energy != null,
      conflict: GeologNoteConflict.energy,
      choices: choices,
    )?.energy;
    if (energy != null) model.energyType = energy;

    final visibility = _pick(
      departure,
      arrival,
      has: (n) => n.visibility != null,
      conflict: GeologNoteConflict.visibility,
      choices: choices,
    )?.visibility;
    if (visibility != null) model.tripVisibility = visibility;
  }

  /// [a] and [b] concatenated with [separator], departure first. A value
  /// only one side has is kept as is, and one both share is kept once.
  static String? join(String? a, String? b, String separator) {
    final first = GeologNote.clean(a);
    final second = GeologNote.clean(b);
    if (first == null) return second;
    if (second == null || second == first) return first;
    return '$first$separator$second';
  }

  /// The note to read a single-valued field from: the only one that [has] it,
  /// or the side the user chose when both do.
  static GeologNote? _pick(
    GeologNote? departure,
    GeologNote? arrival, {
    required bool Function(GeologNote) has,
    required GeologNoteConflict conflict,
    required Map<GeologNoteConflict, GeologNoteSide> choices,
  }) {
    final depHas = departure != null && has(departure);
    final arrHas = arrival != null && has(arrival);
    if (depHas && arrHas) {
      return choices[conflict] == GeologNoteSide.arrival ? arrival : departure;
    }
    if (depHas) return departure;
    if (arrHas) return arrival;
    return null;
  }

  static bool _sameTicket(GeologNote? departure, GeologNote? arrival) =>
      departure?.price != null &&
      departure?.price == arrival?.price &&
      departure?.currency == arrival?.currency;
}
