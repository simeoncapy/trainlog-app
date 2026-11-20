import 'dart:convert';
import 'dart:typed_data';

/// Solver for the ALTCHA v2 proof-of-work captcha that protects the Trainlog
/// signup (see `src/captcha.py` on the server).
///
/// The server sends a signed challenge (`GET /signup/challenge`); the client
/// must find the counter `c` such that
/// `PBKDF2-HMAC-SHA256(password: nonce ‖ uint32be(c), salt, cost, keyLength)`
/// starts with `keyPrefix`, then posts the challenge and the solution back,
/// base64-encoded, as the `altcha` form field.
///
/// Pure Dart (no Flutter import) so it can run in a background isolate and be
/// unit-tested on its own. PBKDF2 is hand-rolled on top of a SHA-256 whose
/// HMAC pads are hashed once per counter: about 5x faster than going through
/// `package:crypto`'s `Hmac`, which matters as a challenge costs a few million
/// SHA-256 blocks.
class AltchaChallenge {
  /// The `parameters` object exactly as received: it is signed by the server,
  /// so it is sent back untouched.
  final Map<String, dynamic> parameters;
  final String? signature;

  const AltchaChallenge({required this.parameters, this.signature});

  factory AltchaChallenge.fromJson(Map<String, dynamic> json) {
    final params = json['parameters'];
    if (params is! Map) {
      throw const FormatException('ALTCHA challenge without parameters');
    }
    return AltchaChallenge(
      parameters: Map<String, dynamic>.from(params),
      signature: json['signature'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'parameters': parameters,
        if (signature != null) 'signature': signature,
      };

  String get algorithm => parameters['algorithm'] as String;
  String get nonce => parameters['nonce'] as String;
  String get salt => parameters['salt'] as String;
  int get cost => (parameters['cost'] as num).toInt();
  int get keyLength => (parameters['keyLength'] as num?)?.toInt() ?? 32;
  String get keyPrefix => ((parameters['keyPrefix'] as String?) ?? '00').toLowerCase();

  /// Unix time (seconds) after which the server refuses the solution.
  int? get expiresAt => (parameters['expiresAt'] as num?)?.toInt();

  bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
  }
}

class AltchaSolution {
  final int counter;
  final String derivedKey;
  final int timeMs;

  const AltchaSolution({
    required this.counter,
    required this.derivedKey,
    required this.timeMs,
  });

  Map<String, dynamic> toJson() => {
        'counter': counter,
        'derivedKey': derivedKey,
        'time': timeMs,
      };
}

/// The value of the `altcha` form field: challenge and solution, as base64
/// JSON.
String buildAltchaPayload(AltchaChallenge challenge, AltchaSolution solution) {
  final json = jsonEncode({
    'challenge': challenge.toJson(),
    'solution': solution.toJson(),
  });
  return base64.encode(utf8.encode(json));
}

/// Brute-forces the counter of [challenge], trying counters from
/// [counterStart] (inclusive) to [counterEnd] (exclusive). Returns null when
/// none matches. Ranges let callers split the search between isolates.
/// CPU bound: run it off the UI isolate.
AltchaSolution? solveAltcha(
  AltchaChallenge challenge, {
  int counterStart = 0,
  int counterEnd = 10000000,
}) {
  final algo = challenge.algorithm.toUpperCase();
  if (algo != 'PBKDF2/SHA-256' && algo != 'PBKDF2') {
    throw UnsupportedError('Unsupported ALTCHA algorithm ${challenge.algorithm}');
  }
  final keyLength = challenge.keyLength;
  if (keyLength < 1 || keyLength > 32) {
    throw UnsupportedError('Unsupported ALTCHA key length $keyLength');
  }

  final nonce = _hexToBytes(challenge.nonce);
  final salt = _hexToBytes(challenge.salt);
  final prefixHex = challenge.keyPrefix;
  final prefixBytes = prefixHex.length.isEven ? _hexToBytes(prefixHex) : null;
  if (prefixBytes != null && prefixBytes.length > keyLength) return null;

  final kdf = _Pbkdf2Sha256(salt);
  final password = Uint8List(nonce.length + 4)..setRange(0, nonce.length, nonce);
  final stopwatch = Stopwatch()..start();

  for (var counter = counterStart; counter < counterEnd; counter++) {
    final n = nonce.length;
    password[n] = (counter >> 24) & 0xff;
    password[n + 1] = (counter >> 16) & 0xff;
    password[n + 2] = (counter >> 8) & 0xff;
    password[n + 3] = counter & 0xff;

    final key = kdf.derive(password, challenge.cost);
    final bool matched;
    if (prefixBytes != null) {
      var ok = true;
      for (var i = 0; i < prefixBytes.length; i++) {
        if (key[i] != prefixBytes[i]) {
          ok = false;
          break;
        }
      }
      matched = ok;
    } else {
      matched = _bytesToHex(key, keyLength).startsWith(prefixHex);
    }

    if (matched) {
      return AltchaSolution(
        counter: counter,
        derivedKey: _bytesToHex(key, keyLength),
        timeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
  return null;
}

/// Test hook: PBKDF2-HMAC-SHA256 with a 32-byte output.
Uint8List pbkdf2Sha256ForTest(List<int> password, List<int> salt, int iterations) =>
    _Pbkdf2Sha256(Uint8List.fromList(salt))
        .derive(Uint8List.fromList(password), iterations);

// ---------------------------------------------------------------------------
// PBKDF2-HMAC-SHA256, first (and only) 32-byte block
// ---------------------------------------------------------------------------

class _Pbkdf2Sha256 {
  final Uint8List salt;

  final _ipad = Uint32List(8);
  final _opad = Uint32List(8);
  final _state = Uint32List(8);
  final _block = Uint32List(16);
  final _w = Uint32List(64);
  final _u = Uint32List(8);
  final _t = Uint32List(8);
  final _keyBlock = Uint8List(64);

  /// First inner block: salt ‖ INT(1) ‖ SHA-256 padding, when it fits in one
  /// block (true for ALTCHA's 16-byte salts).
  final Uint32List? _firstBlock;

  _Pbkdf2Sha256(this.salt) : _firstBlock = _saltBlock(salt);

  static Uint32List? _saltBlock(Uint8List salt) {
    final len = salt.length + 4;
    if (len > 55) return null;
    final bytes = Uint8List(64)..setRange(0, salt.length, salt);
    bytes[salt.length + 3] = 1;
    bytes[len] = 0x80;
    final bits = (64 + len) * 8;
    bytes[62] = (bits >> 8) & 0xff;
    bytes[63] = bits & 0xff;
    return _bytesToWords(bytes);
  }

  Uint8List derive(Uint8List password, int iterations) {
    _hmacPads(password);

    // U1 = HMAC(P, salt ‖ INT(1))
    final first = _firstBlock;
    if (first != null) {
      _state.setAll(0, _ipad);
      _compress(_state, first);
    } else {
      _innerLong();
    }
    _outer();
    _t.setAll(0, _u);

    // Ui = HMAC(P, U(i-1)), 32-byte messages: one block each side
    for (var i = 1; i < iterations; i++) {
      _state.setAll(0, _ipad);
      _loadDigestBlock(_u);
      _compress(_state, _block);
      _outer();
      for (var j = 0; j < 8; j++) {
        _t[j] ^= _u[j];
      }
    }

    final out = Uint8List(32);
    for (var j = 0; j < 8; j++) {
      final v = _t[j];
      out[j * 4] = (v >> 24) & 0xff;
      out[j * 4 + 1] = (v >> 16) & 0xff;
      out[j * 4 + 2] = (v >> 8) & 0xff;
      out[j * 4 + 3] = v & 0xff;
    }
    return out;
  }

  void _hmacPads(Uint8List password) {
    List<int> key = password;
    if (key.length > 64) key = _sha256(key);
    _keyBlock.fillRange(0, 64, 0);
    _keyBlock.setRange(0, key.length, key);

    final pad = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      pad[i] = _keyBlock[i] ^ 0x36;
    }
    _ipad.setAll(0, _h0);
    _compress(_ipad, _bytesToWords(pad));
    for (var i = 0; i < 64; i++) {
      pad[i] = _keyBlock[i] ^ 0x5c;
    }
    _opad.setAll(0, _h0);
    _compress(_opad, _bytesToWords(pad));
  }

  /// Inner hash of salt ‖ INT(1) for salts too long for a single block.
  void _innerLong() {
    final msg = Uint8List(salt.length + 4)..setRange(0, salt.length, salt);
    msg[salt.length + 3] = 1;
    _state.setAll(0, _ipad);
    _hashTail(_state, msg, 64);
  }

  /// _u = outer hash of the 32-byte inner digest held in _state.
  void _outer() {
    _loadDigestBlock(_state);
    _u.setAll(0, _opad);
    _compress(_u, _block);
  }

  /// _block = digest (8 words) ‖ 0x80 ‖ zeros ‖ bit length of 64 + 32 bytes.
  void _loadDigestBlock(Uint32List digest) {
    for (var j = 0; j < 8; j++) {
      _block[j] = digest[j];
    }
    _block[8] = 0x80000000;
    for (var j = 9; j < 15; j++) {
      _block[j] = 0;
    }
    _block[15] = (64 + 32) * 8;
  }

  void _compress(Uint32List h, Uint32List block) => _sha256Compress(h, block, _w);
}

// ---------------------------------------------------------------------------
// SHA-256
// ---------------------------------------------------------------------------

const List<int> _h0 = [
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

final Uint32List _k = Uint32List.fromList(const [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
]);

const int _mask = 0xffffffff;

void _sha256Compress(Uint32List h, Uint32List block, Uint32List w) {
  // Rotations are written out inline: this function is the whole cost of a
  // challenge, and the AOT compiler does not always inline a helper.
  for (var i = 0; i < 16; i++) {
    w[i] = block[i];
  }
  for (var i = 16; i < 64; i++) {
    final x = w[i - 15];
    final y = w[i - 2];
    final s0 = (((x >> 7) | (x << 25)) ^ ((x >> 18) | (x << 14)) ^ (x >> 3)) & _mask;
    final s1 = (((y >> 17) | (y << 15)) ^ ((y >> 19) | (y << 13)) ^ (y >> 10)) & _mask;
    w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & _mask;
  }

  var a = h[0], b = h[1], c = h[2], d = h[3];
  var e = h[4], f = h[5], g = h[6], hh = h[7];

  for (var i = 0; i < 64; i++) {
    final s1 = (((e >> 6) | (e << 26)) ^ ((e >> 11) | (e << 21)) ^ ((e >> 25) | (e << 7))) & _mask;
    final ch = (e & f) ^ (~e & g);
    final t1 = (hh + s1 + ch + _k[i] + w[i]) & _mask;
    final s0 = (((a >> 2) | (a << 30)) ^ ((a >> 13) | (a << 19)) ^ ((a >> 22) | (a << 10))) & _mask;
    final maj = (a & b) ^ (a & c) ^ (b & c);
    hh = g;
    g = f;
    f = e;
    e = (d + t1) & _mask;
    d = c;
    c = b;
    b = a;
    a = (t1 + s0 + maj) & _mask;
  }

  h[0] = (h[0] + a) & _mask;
  h[1] = (h[1] + b) & _mask;
  h[2] = (h[2] + c) & _mask;
  h[3] = (h[3] + d) & _mask;
  h[4] = (h[4] + e) & _mask;
  h[5] = (h[5] + f) & _mask;
  h[6] = (h[6] + g) & _mask;
  h[7] = (h[7] + hh) & _mask;
}

/// Hashes [msg] into [h], [prefixLen] bytes having already been absorbed.
void _hashTail(Uint32List h, List<int> msg, int prefixLen) {
  final total = msg.length + 1 + 8;
  final padded = Uint8List(((total + 63) ~/ 64) * 64)..setRange(0, msg.length, msg);
  padded[msg.length] = 0x80;
  final bits = (prefixLen + msg.length) * 8;
  for (var i = 0; i < 8; i++) {
    // Messages here are far below 2^32 bits: the high word stays 0.
    padded[padded.length - 1 - i] = i < 4 ? (bits >> (8 * i)) & 0xff : 0;
  }
  final w = Uint32List(64);
  for (var off = 0; off < padded.length; off += 64) {
    _sha256Compress(h, _bytesToWords(Uint8List.sublistView(padded, off, off + 64)), w);
  }
}

Uint8List _sha256(List<int> msg) {
  final h = Uint32List.fromList(_h0);
  _hashTail(h, msg, 0);
  final out = Uint8List(32);
  for (var j = 0; j < 8; j++) {
    out[j * 4] = (h[j] >> 24) & 0xff;
    out[j * 4 + 1] = (h[j] >> 16) & 0xff;
    out[j * 4 + 2] = (h[j] >> 8) & 0xff;
    out[j * 4 + 3] = h[j] & 0xff;
  }
  return out;
}

Uint32List _bytesToWords(Uint8List bytes) {
  final words = Uint32List(bytes.length ~/ 4);
  for (var i = 0; i < words.length; i++) {
    words[i] = (bytes[i * 4] << 24) |
        (bytes[i * 4 + 1] << 16) |
        (bytes[i * 4 + 2] << 8) |
        bytes[i * 4 + 3];
  }
  return words;
}

Uint8List _hexToBytes(String hex) {
  if (hex.length.isOdd) throw FormatException('Odd-length hex', hex);
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

String _bytesToHex(Uint8List bytes, int length) {
  final sb = StringBuffer();
  for (var i = 0; i < length; i++) {
    sb.write(bytes[i].toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}
