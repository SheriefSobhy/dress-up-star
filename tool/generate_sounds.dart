// Creates the game's music and sound effects as WAV files.
//
// All sounds are synthesized here from scratch, so they are 100% original.
// Run from the project folder:   dart run tool/generate_sounds.dart
// The files are written to assets/sounds/.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 22050;

double midiToHz(num midi) => 440 * math.pow(2, (midi - 69) / 12).toDouble();

/// A mono audio buffer that tones can be mixed into.
class Mix {
  Mix(double seconds, {this.loop = false})
    : data = Float64List((seconds * sampleRate).round());

  final Float64List data;

  /// If true, sound that runs past the end wraps around to the start, so
  /// the file loops without a click.
  final bool loop;

  final _random = math.Random(7);

  void _add(int i, double v) {
    if (loop) {
      data[i % data.length] += v;
    } else if (i >= 0 && i < data.length) {
      data[i] += v;
    }
  }

  /// A plucked/bell-like tone that fades away.
  void tone({
    required double start,
    required double freq,
    required double dur,
    double? freqEnd,
    double vol = 0.3,
    double decay = 4,
    double attack = 0.005,
    List<double> harmonics = const [1],
  }) {
    final n = (dur * sampleRate).round();
    final s0 = (start * sampleRate).round();
    final fadeOut = 0.012 * sampleRate;
    var phase = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      final f = freqEnd == null ? freq : freq + (freqEnd - freq) * (i / n);
      phase += 2 * math.pi * f / sampleRate;
      final env =
          math.min(1.0, t / attack) *
          math.exp(-t * decay) *
          math.min(1.0, (n - i) / fadeOut);
      var v = 0.0;
      for (var h = 0; h < harmonics.length; h++) {
        v += harmonics[h] * math.sin(phase * (h + 1));
      }
      _add(s0 + i, v * env * vol);
    }
  }

  void note(
    double start,
    num midi,
    double dur, {
    double vol = 0.3,
    double decay = 4,
    List<double> harmonics = const [1],
  }) => tone(
    start: start,
    freq: midiToHz(midi),
    dur: dur,
    vol: vol,
    decay: decay,
    harmonics: harmonics,
  );

  /// A short burst of noise (for the camera click).
  void noise({
    required double start,
    required double dur,
    double vol = 0.3,
    double decay = 60,
  }) {
    final n = (dur * sampleRate).round();
    final s0 = (start * sampleRate).round();
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      _add(s0 + i, (_random.nextDouble() * 2 - 1) * vol * math.exp(-t * decay));
    }
  }

  /// Soft, smoothed noise that swells in and fades out (whoosh, water).
  /// [smooth] near 1 gives a deep rumble, near 0 a bright hiss.
  void softNoise({
    required double start,
    required double dur,
    double vol = 0.3,
    double smooth = 0.9,
    double attack = 0.05,
    double release = 0.15,
    double wobble = 0,
  }) {
    final n = (dur * sampleRate).round();
    final s0 = (start * sampleRate).round();
    var low = 0.0;
    for (var i = 0; i < n; i++) {
      final t = i / sampleRate;
      low = low * smooth + (_random.nextDouble() * 2 - 1) * (1 - smooth);
      final env =
          math.min(1.0, t / attack) * math.min(1.0, (dur - t) / release);
      final w = 1 + wobble * math.sin(2 * math.pi * 7 * t);
      _add(s0 + i, low * env * vol * w * 4);
    }
  }

  /// 16-bit mono WAV bytes, normalized so the loudest point is [peak].
  Uint8List toWav({double peak = 0.8}) {
    var max = 0.0;
    for (final v in data) {
      max = math.max(max, v.abs());
    }
    final scale = max > 0 ? peak / max : 1.0;
    final bytes = ByteData(44 + data.length * 2);
    void text(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    text(0, 'RIFF');
    bytes.setUint32(4, 36 + data.length * 2, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    text(36, 'data');
    bytes.setUint32(40, data.length * 2, Endian.little);
    for (var i = 0; i < data.length; i++) {
      final s = (data[i] * scale * 32767).round().clamp(-32768, 32767);
      bytes.setInt16(44 + i * 2, s, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}

const _bell = [1.0, 0.35, 0.15];

/// A happy, bouncy 8-bar tune in C major that loops forever.
Mix music() {
  const bpm = 140.0;
  const beat = 60 / bpm;
  final mix = Mix(32 * beat, loop: true);

  // Chords per bar: C G Am F C G F G
  const roots = [48, 43, 45, 41, 48, 43, 41, 43];
  const arps = [
    [60, 64, 67],
    [59, 62, 67],
    [60, 64, 69],
    [60, 65, 69],
    [60, 64, 67],
    [59, 62, 67],
    [60, 65, 69],
    [59, 62, 67],
  ];
  // Melody: (midi note, beats)
  const melody = [
    [
      [76, 1],
      [79, 1],
      [84, 1],
      [79, 1],
    ],
    [
      [74, 1],
      [79, 1],
      [83, 1],
      [79, 1],
    ],
    [
      [76, 1],
      [81, 1],
      [84, 1],
      [81, 1],
    ],
    [
      [77, 1],
      [81, 1],
      [79, 2],
    ],
    [
      [84, 0.5],
      [83, 0.5],
      [81, 0.5],
      [79, 0.5],
      [76, 1],
      [79, 1],
    ],
    [
      [74, 1],
      [79, 1],
      [83, 2],
    ],
    [
      [81, 1],
      [77, 1],
      [79, 1],
      [81, 1],
    ],
    [
      [79, 1],
      [83, 1],
      [74, 2],
    ],
  ];

  for (var bar = 0; bar < 8; bar++) {
    final barStart = bar * 4 * beat;

    // Melody: a soft music-box voice.
    var t = barStart;
    for (final n in melody[bar]) {
      final beats = n[1].toDouble();
      mix.note(
        t,
        n[0],
        beats * beat + 0.35,
        vol: 0.3,
        decay: 3,
        harmonics: _bell,
      );
      t += beats * beat;
    }

    // Bouncy bass on beats 1 and 3, fifth on beat 3.
    mix.note(
      barStart,
      roots[bar],
      beat * 1.8,
      vol: 0.32,
      decay: 3,
      harmonics: const [1, 0.4],
    );
    mix.note(
      barStart + 2 * beat,
      roots[bar] + 7,
      beat * 1.8,
      vol: 0.26,
      decay: 3,
      harmonics: const [1, 0.4],
    );

    // Gentle eighth-note arpeggio.
    const pattern = [0, 1, 2, 1, 0, 1, 2, 1];
    for (var e = 0; e < 8; e++) {
      mix.note(
        barStart + e * beat / 2,
        arps[bar][pattern[e]],
        beat * 0.7,
        vol: 0.09,
        decay: 6,
        harmonics: const [1, 0.5, 0.3, 0.15],
      );
    }

    // Soft "boom" on every beat 1 and 3.
    for (final b in [0, 2]) {
      mix.tone(
        start: barStart + b * beat,
        freq: 130,
        freqEnd: 50,
        dur: 0.14,
        vol: 0.3,
        decay: 22,
      );
    }
  }
  return mix;
}

Mix tap() => Mix(0.12)
  ..tone(
    start: 0,
    freq: 660,
    freqEnd: 990,
    dur: 0.1,
    vol: 0.5,
    decay: 30,
    harmonics: const [1, 0.2],
  );

Mix itemOn() {
  final mix = Mix(0.75);
  const notes = [84, 88, 91, 96];
  for (var i = 0; i < notes.length; i++) {
    mix.note(i * 0.06, notes[i], 0.5, vol: 0.3, decay: 6, harmonics: _bell);
  }
  mix.note(0.26, 100, 0.35, vol: 0.12, decay: 9, harmonics: _bell);
  mix.note(0.32, 103, 0.35, vol: 0.1, decay: 9, harmonics: _bell);
  return mix;
}

Mix itemOff() => Mix(0.35)
  ..tone(
    start: 0,
    freq: 560,
    freqEnd: 260,
    dur: 0.28,
    vol: 0.45,
    decay: 8,
    harmonics: const [1, 0.3],
  );

Mix camera() => Mix(0.85)
  ..noise(start: 0, dur: 0.04, vol: 0.5, decay: 90)
  ..tone(start: 0, freq: 1800, dur: 0.02, vol: 0.25, decay: 120)
  ..noise(start: 0.09, dur: 0.05, vol: 0.4, decay: 70)
  ..note(0.2, 91, 0.55, vol: 0.3, decay: 5, harmonics: _bell)
  ..note(0.3, 96, 0.55, vol: 0.3, decay: 5, harmonics: _bell);

/// A soft twinkle while a brush, lipstick or polish paints.
Mix brush() => Mix(0.3)
  ..softNoise(start: 0, dur: 0.16, vol: 0.12, smooth: 0.55, attack: 0.03)
  ..note(0.02, 96, 0.22, vol: 0.18, decay: 14, harmonics: _bell)
  ..note(0.07, 100, 0.2, vol: 0.13, decay: 16, harmonics: _bell);

/// A magic "ta-da" shimmer when something is finished.
Mix sparkle() {
  final mix = Mix(1.0);
  const notes = [79, 84, 88, 91, 96, 100];
  for (var i = 0; i < notes.length; i++) {
    mix.note(i * 0.05, notes[i], 0.6, vol: 0.24, decay: 5, harmonics: _bell);
  }
  for (var i = 0; i < 6; i++) {
    mix.note(
      0.3 + i * 0.07,
      103 - (i.isEven ? 0 : 3),
      0.3,
      vol: 0.07,
      decay: 10,
      harmonics: _bell,
    );
  }
  return mix;
}

/// Scissors: two quick metal clicks.
Mix snip() => Mix(0.3)
  ..noise(start: 0, dur: 0.03, vol: 0.35, decay: 140)
  ..tone(start: 0, freq: 3200, freqEnd: 2600, dur: 0.05, vol: 0.18, decay: 70)
  ..noise(start: 0.09, dur: 0.03, vol: 0.3, decay: 150)
  ..tone(
    start: 0.09,
    freq: 3600,
    freqEnd: 3000,
    dur: 0.05,
    vol: 0.16,
    decay: 80,
  );

/// Splashy shower water with a few bubbly bloops.
Mix water() {
  final mix = Mix(0.6)
    ..softNoise(start: 0, dur: 0.55, vol: 0.22, smooth: 0.35, wobble: 0.35);
  const blips = [0.04, 0.16, 0.27, 0.39];
  for (var i = 0; i < blips.length; i++) {
    mix.tone(
      start: blips[i],
      freq: 380 + i * 90,
      freqEnd: 900 + i * 120,
      dur: 0.07,
      vol: 0.2,
      decay: 30,
    );
  }
  return mix;
}

/// A warm whoosh of air (hair dryer, nail dryer).
Mix blow() => Mix(0.6)
  ..softNoise(
    start: 0,
    dur: 0.58,
    vol: 0.3,
    smooth: 0.82,
    attack: 0.12,
    release: 0.25,
    wobble: 0.15,
  );

/// A bubble popping.
Mix bubble() => Mix(0.16)
  ..tone(start: 0, freq: 320, freqEnd: 1100, dur: 0.07, vol: 0.4, decay: 25)
  ..tone(
    start: 0.06,
    freq: 900,
    freqEnd: 1500,
    dur: 0.06,
    vol: 0.18,
    decay: 40,
  );

/// A happy "ta-da!" when a Star Shop item is unlocked (and the daily gift).
Mix unlock() {
  final mix = Mix(1.3);
  const run = [72, 76, 79, 84, 88];
  for (var i = 0; i < run.length; i++) {
    mix.note(i * 0.07, run[i], 0.3, vol: 0.22, decay: 8, harmonics: _bell);
  }
  for (final n in [84, 88, 91, 96]) {
    mix.note(0.38, n, 0.85, vol: 0.16, decay: 3.2, harmonics: _bell);
  }
  for (var i = 0; i < 5; i++) {
    mix.note(
      0.5 + i * 0.09,
      100 + (i.isEven ? 0 : 3),
      0.25,
      vol: 0.06,
      decay: 10,
      harmonics: _bell,
    );
  }
  return mix;
}

/// A soft, friendly "not yet" (two gentle notes, never a buzzer).
Mix notYet() => Mix(0.5)
  ..note(0, 79, 0.22, vol: 0.26, decay: 9, harmonics: const [1, 0.3])
  ..note(0.16, 76, 0.3, vol: 0.24, decay: 7, harmonics: const [1, 0.3]);

void main() {
  final dir = Directory('assets/sounds')..createSync(recursive: true);
  final files = <String, (Mix, double)>{
    'music.wav': (music(), 0.6),
    'tap.wav': (tap(), 0.7),
    'item_on.wav': (itemOn(), 0.8),
    'item_off.wav': (itemOff(), 0.75),
    'camera.wav': (camera(), 0.8),
    'brush.wav': (brush(), 0.5),
    'sparkle.wav': (sparkle(), 0.75),
    'snip.wav': (snip(), 0.65),
    'water.wav': (water(), 0.55),
    'blow.wav': (blow(), 0.5),
    'bubble.wav': (bubble(), 0.6),
    'unlock.wav': (unlock(), 0.8),
    'not_yet.wav': (notYet(), 0.55),
  };
  for (final entry in files.entries) {
    final bytes = entry.value.$1.toWav(peak: entry.value.$2);
    File('${dir.path}/${entry.key}').writeAsBytesSync(bytes);
    stdout.writeln(
      '${entry.key}: ${(bytes.length / 1024).toStringAsFixed(0)} KB',
    );
  }
}
