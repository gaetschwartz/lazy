// ignore_for_file: unnecessary_statements
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:lazy/lazy.dart';

final r = Random();

Iterable<int> iterable(int n) sync* {
  for (var i = 0; i < n; i++) {
    yield r.nextInt(n);
  }
}

void main() {
  const n = 1000;
  const n1 = 10000;
  final s = Stopwatch()..stop();
  final iter = List.generate(n1, (e) => r.nextInt(n1))
      .map((e) => e * 2)
      .map((e) => e.toString());

  for (var shift = 0; shift < 4; shift++) {
    final d = 1 << shift;
    final n2 = n1 ~/ d;

    final b = Benchmark('lazy vs list w/ 1/$d of items');

    for (var i = 0; i < n; i++) {
      s.start();
      final l = iter.toList();
      s.stop();

      for (var j = 0; j < n2; j++) {
        s.start();
        l[j];
        s.stop();
      }
    }

    b.add(BenchmarkResult(
      name: 'classical list',
      ms: s.elapsedMilliseconds,
      runs: n,
      countInTop: true,
      isReference: true,
    ));
    s.reset();

    for (var i = 0; i < n; i++) {
      final l = LazyList(iter);

      for (var j = 0; j < n2; j++) {
        s.start();
        l[j];
        s.stop();
      }
    }

    b.add(BenchmarkResult(
      name: 'lazy list ascending walk',
      ms: s.elapsedMilliseconds,
      runs: n,
      countInTop: true,
    ));
    s.reset();

    for (var i = 0; i < n; i++) {
      final l = LazyList(iter, extent: 25);

      for (var j = 0; j < n2; j++) {
        s.start();
        l[j];
        s.stop();
      }
    }

    b.add(BenchmarkResult(
      name: 'lazy list ascending walk 25 extent',
      ms: s.elapsedMilliseconds,
      runs: n,
    ));
    s.reset();

    for (var i = 0; i < n; i++) {
      final l = LazyList(iter);

      for (var j = n2 - 1; j >= 0; j--) {
        s.start();
        l[j];
        s.stop();
      }
    }

    b.add(BenchmarkResult(
      name: 'lazy list descending walk',
      ms: s.elapsedMilliseconds,
      runs: n,
    ));
    s.reset();

    for (var i = 0; i < n; i++) {
      final l = LazyList(iter);

      for (var j = 0; j < n2; j++) {
        final i1 = r.nextInt(n1);
        s.start();
        l[i1];
        s.stop();
      }
    }

    b.add(BenchmarkResult(
        name: 'lazy list random walk', ms: s.elapsedMilliseconds, runs: n));
    s.reset();

    b.log(display: DisplayTopAndRef(top: 3));
  }
}

class BenchmarkResult {
  BenchmarkResult({
    required this.name,
    required this.ms,
    required this.runs,
    this.size,
    this.isReference = false,
    this.countInTop = false,
  });

  final String name;
  final int ms;
  final int runs;
  final bool isReference;
  final bool countInTop;

  /// Size in bytes.
  final int? size;

  @override
  String toString() {
    final b = StringBuffer('''$name:
  > time\t: ${(ms / runs).toStringAsFixed(3)} ms/run
  > freq\t: ${(1000 * runs) ~/ ms} runs/s
  > runs\t: $runs''');
    if (size != null) {
      b.write('\n  > size: ${byteSizeOf(size!)}');
    }
    return b.toString();
  }
}

class Benchmark {
  Benchmark(this.name);

  final String name;
  final results = <BenchmarkResult>[];

  void add(BenchmarkResult r) {
    //print('${r.name} finished in ${r.ms} ms.');
    results.add(r);
  }

  void log({DisplayMode display = const DisplayAll()}) {
    assert(results.where((e) => e.isReference).length <= 1);
    final ref = results.firstWhereOrNull((e) => e.isReference);
    final buffer = StringBuffer()..writeln('''

${'=' * (name.length + 4)}
  $name
${'=' * (name.length + 4)}''');

    buffer.writeln('Display: $display');
    buffer.writeln();

    final filtered = display.display(results);
    final join = filtered.map((e) {
      return e.toStringWith({
        if (ref != null && !e.result.isReference)
          "speed": "${(ref.ms / e.result.ms).toStringAsFixed(2)} ×"
      });
    }).join('\n');

    buffer.write(join);

    print(buffer.toString());
  }

  void addResult(String name, {required int elapsed, required int runs}) =>
      add(BenchmarkResult(name: name, ms: elapsed, runs: runs));
}

String byteSizeOf(int bytes, {int fixed = 0}) {
  const sizes = ['b', 'Kb', 'Mb', 'Gb'];
  var i = 0;
  var b = bytes;
  while (b > 1024 && i < sizes.length - 1) {
    b >>= 10;
    i++;
  }
  return '${b.toStringAsFixed(fixed)} ${sizes[i]}';
}

enum SortingStrategy { ascending, descending }

class ResultSection {
  final String? title;
  final BenchmarkResult result;

  ResultSection(
    this.result, {
    this.title,
  });

  String toStringWith(Map<String, String> args) {
    final b = StringBuffer();
    String s = result.toString() +
        (args.isNotEmpty ? '\n' : '') +
        args.entries.map((e) => '  > ${e.key} \t: ${e.value}').join('\n');
    if (title != null) {
      b
        ..write(title)
        ..writeln(':');
      s = s.split('\n').map((e) => '  ' + e).join('\n');
    }

    b.writeln(s);

    return b.toString();
  }
}

abstract class DisplayMode {
  Iterable<ResultSection> display(Iterable<BenchmarkResult> results);
}

class DisplayAll implements DisplayMode {
  const DisplayAll();

  @override
  Iterable<ResultSection> display(Iterable<BenchmarkResult> results) =>
      results.map((e) => ResultSection(e));
}

class Sorted implements DisplayMode {
  final SortingStrategy strategy;

  const Sorted([this.strategy = SortingStrategy.descending]);

  @override
  Iterable<ResultSection> display(Iterable<BenchmarkResult> results) {
    final l = List.of(results);

    switch (strategy) {
      case SortingStrategy.ascending:
        l.sort((a, b) => b.ms.compareTo(a.ms));
        break;
      case SortingStrategy.descending:
        l.sort((a, b) => a.ms.compareTo(b.ms));
        break;
    }

    return l.map((e) => ResultSection(e));
  }
}

class DisplayTopAndRef implements DisplayMode {
  final int top;
  final bool displayRef;
  const DisplayTopAndRef({this.displayRef = false, this.top = 1});

  @override
  Iterable<ResultSection> display(Iterable<BenchmarkResult> results) sync* {
    if (displayRef) {
      final ref = results.firstWhereOrNull((e) => e.isReference);
      if (ref != null) {
        yield ResultSection(ref, title: 'Reference');
      }
    }
    final l = List.of(results);
    l.sort((a, b) => a.ms.compareTo(b.ms));

    var i = 1;
    for (final e in l.where((e) => e.countInTop).take(top)) {
      yield ResultSection(e, title: 'Top $i');
      i++;
    }
  }
}
