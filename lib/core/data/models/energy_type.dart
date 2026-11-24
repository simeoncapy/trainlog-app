/// Power of the vehicle of a trip, as the site spells it.
enum EnergyType {
  auto,
  electric,
  thermic;

  /// Parses the power type as the site spells it, falling back to [auto] —
  /// which is also what the site assumes when the trip has none.
  static EnergyType fromString(String? s) {
    switch (s?.toLowerCase().trim()) {
      case 'electric':
        return EnergyType.electric;
      case 'thermic':
      case 'thermal':
      case 'diesel':
      case 'fuel':
        return EnergyType.thermic;
      default:
        return EnergyType.auto;
    }
  }
}
