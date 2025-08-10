import 'dart:collection';

class StatisticsCalculator {

  Future<LinkedHashMap<String, double>> getTop9WithOther({
    required Map<String, double> original,
    double factor = 1_000, // divide by this
  }) async {
    // Sort descending by value
    final sortedEntries = original.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Keep top 9
    final top9 = sortedEntries.take(9).toList();
    final rest = sortedEntries.skip(9);

    // Sum the rest
    final otherValue = rest.fold<double>(0, (sum, e) => sum + e.value);

    // Create LinkedHashMap to preserve order
    final result = LinkedHashMap<String, double>();

    // Add scaled top 9
    for (final e in top9) {
      result[e.key] = e.value / factor;
    }

    // Add "Other" if there was anything to sum
    if (otherValue > 0) {
      result["Other"] = otherValue / factor;
    }

    return result;
  }

  Future<LinkedHashMap<String, ({double past, double future})>> getTop9WithOtherPF({
    required Map<String, ({num past, num future})> original,
    double factor = 1_000, // divide by this
    String otherLabel = 'Other',
  }) async {
    // Sort by (past + future) descending
    final sortedEntries = original.entries.toList()
      ..sort((a, b) =>
          (b.value.past + b.value.future).compareTo(a.value.past + a.value.future));

    // Take top 9 and the rest
    final top9 = sortedEntries.take(9).toList();
    final rest = sortedEntries.skip(9);

    // Sum the rest into "Other"
    double otherPast = 0;
    double otherFuture = 0;
    for (final e in rest) {
      otherPast  += e.value.past.toDouble();
      otherFuture+= e.value.future.toDouble();
    }

    // Build result (preserve order) and apply scaling
    final result = LinkedHashMap<String, ({double past, double future})>();

    for (final e in top9) {
      result[e.key] = (
        past:   e.value.past.toDouble()   / factor,
        future: e.value.future.toDouble() / factor,
      );
    }

    if (otherPast > 0 || otherFuture > 0) {
      result[otherLabel] = (
        past:   otherPast   / factor,
        future: otherFuture / factor,
      );
    }

    return result;
  }
}