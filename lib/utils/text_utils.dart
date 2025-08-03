String countryCodeToEmoji(String code) {
  return String.fromCharCodes(
    code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + (c - 65)),
  );
}