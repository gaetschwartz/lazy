import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lazy/lazy.dart';

void main() {
  final r = Random();

  test('1 length lazy list', () {
    final i = Iterable.generate(1);
    final l = LazyList(i);
    expect(l[0], i.first);
    expect(l.first, i.first);
  });

  group('10\'000 length lazy list', () {
    const n = 10000;

    Iterable<int> iter() => Iterable.generate(n, (_) => _);

    test('incremental walk', () {
      final list = iter().toList();
      final lazy = LazyList(iter());
      for (var i = 0; i < n; i++) {
        expect(lazy[i], list[i], reason: 'at index $i');
      }
    });

    test('decremental walk', () {
      final list = iter().toList();
      final lazy = LazyList(iter());
      for (var i = n - 1; i >= 0; i--) {
        expect(lazy[i], list[i]);
      }
    });

    test('random walk', () {
      final list = iter().toList();
      final lazy = LazyList(iter());
      for (var i = 0; i < n; i++) {
        final i1 = r.nextInt(n);
        expect(i1, lessThan(list.length));
        expect(lazy[i1], list[i1]);
      }
    });

    test('8 extent', () {
      final list = iter().toList();
      final lazy = LazyList(iter(), extent: 8);
      for (var i = 0; i < n; i++) {
        expect(lazy[i], list[i], reason: 'at index $i');
      }
    });
  });
}
