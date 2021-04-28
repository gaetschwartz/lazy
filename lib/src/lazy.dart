import 'dart:collection';

class LazyList<T> with ListMixin<T> {
  final Iterator<T> _iter;
  final int? _length;
  final int extent;
  LazyList(
    Iterable<T> iterable, {
    int? length,
    int extent = 1,
  })  : _iter = iterable.iterator,
        _length = length,
        assert(extent > 0),
        this.extent = extent - 1;
  var _i = -1;
  final List<T> _list = [];

  @override

  /// Querrying the length involves computing all elements from the LazyList.
  /// Prefer using another method to compute the length as it defeats the whole purpose of a LazyList
  /// unless you've already computed all values.
  int get length => _length == null
      ? throw UnsupportedError('This lazy list doesn\'t have a length.')
      : _length!;

  set length(int l) =>
      throw UnsupportedError('Dont set the length of a lazy list.');

  @override
  T get first {
    _resolve(0);
    return _list[0];
  }

  @override

  /// **TLDR; Don't use it unless you've already computed all values.**
  ///
  /// Querrying the last element involves computing all elements from the LazyList.
  /// Prefer using another method to compute the last element as it defeats the whole purpose of a LazyList.

  T get last {
    while (_iter.moveNext()) {
      _list.add(_iter.current);
      _i++;
    }
    return _list.last;
  }

  int get computed => _i + 1;

  void _resolve(int index) {
    for (var i = _i; i < index + extent; i++) {
      if (_iter.moveNext()) {
        _list.add(_iter.current);
        _i++;
        assert(_i + 1 == _list.length);
      } else {
        throw RangeError.range(index, 0, _i);
      }
    }
  }

  @override
  T operator [](int index) {
    if (index < 0) throw StateError('Index must be greater than 0');
    if (index > _i) _resolve(index);
    return _list[index];
  }

  @override
  void operator []=(int index, T value) {
    if (index <= _i) {
      _list[index] = value;
    } else {
      throw RangeError.range(index, 0, _i);
    }
  }

  @override
  void add(T element) {
    throw UnsupportedError('Lazy lists are not growable.');
  }

  @override
  void addAll(Iterable<T> iterable) {
    throw UnsupportedError('Lazy lists are not growable.');
  }
}

extension ListX<T> on Iterable<T> {
  LazyList<T> get list => LazyList(this);
}
