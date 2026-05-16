typedef MasonryWeight<T> = int Function(T item);

List<List<T>> buildBalancedMasonryColumns<T>(
  List<T> items, {
  required int columnCount,
  required MasonryWeight<T> weightOf,
}) {
  if (items.isEmpty || columnCount <= 0) {
    return const [];
  }

  final effectiveColumnCount =
      columnCount > items.length ? items.length : columnCount;
  final columns = List.generate(effectiveColumnCount, (_) => <T>[]);
  final columnWeights = List.filled(effectiveColumnCount, 0);

  for (final item in items) {
    var targetColumnIndex = 0;
    for (var i = 1; i < columnWeights.length; i++) {
      if (columnWeights[i] < columnWeights[targetColumnIndex]) {
        targetColumnIndex = i;
      }
    }

    columns[targetColumnIndex].add(item);
    columnWeights[targetColumnIndex] += weightOf(item);
  }

  return columns;
}
