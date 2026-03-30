import 'dart:math' as math;

/// Target row height — determines natural width at 1 item per row.
const kTargetRowHeight = 150.0;

/// Minimum note width for dynamic-width media grids.
const kMinDynamicWidth = 200.0;

/// Minimum acceptable cell dimension (width OR height) in pixels. Portrait
/// images are checked on width, landscape on height. When the smallest cell
/// dimension drops below this, the algorithm expands the note width or wraps
/// to more rows.
const kMinCellDimension = 130.0;

/// Concrete cell dimensions for rendering.
class CellLayout {
  final int itemIndex;
  final double width;
  final double height;
  const CellLayout({
    required this.itemIndex,
    required this.width,
    required this.height,
  });
}

/// Result of the layout algorithm: a partition + the width the grid should use.
class GridLayout {
  final List<int> rowCounts;
  final double width;
  const GridLayout({required this.rowCounts, required this.width});
}

/// Compute the optimal grid layout for [aspectRatios] items.
///
/// Algorithm: "grow width, then wrap"
/// 1. Start with all items in 1 row at [targetRowHeight] → natural width.
/// 2. Compute the required width so every cell's smallest dimension (width for
///    portrait, height for landscape) meets [minCellDim]. The note width is the
///    larger of natural width and required width.
/// 3. If this fits within [maxWidth], use it.
/// 4. If it exceeds [maxWidth], check cells at [maxWidth]. If acceptable, use
///    [maxWidth]. Otherwise try more rows until cells fit.
GridLayout computeLayout(
  List<double> aspectRatios, {
  required double maxWidth,
  double targetRowHeight = kTargetRowHeight,
  double minWidth = kMinDynamicWidth,
  double minCellDim = kMinCellDimension,
}) {
  final n = aspectRatios.length;
  if (n == 0) return GridLayout(rowCounts: const [], width: minWidth);
  if (n == 1) {
    final natW = (aspectRatios[0] * targetRowHeight).clamp(minWidth, maxWidth);
    return GridLayout(rowCounts: const [1], width: natW);
  }

  // Try increasing number of rows until the layout fits well.
  for (int rows = 1; rows <= n; rows++) {
    final rowCounts = _balancedPartition(n, rows);

    // For each row, compute the natural width (from targetRowHeight) and the
    // required width (from minCellDim). The note needs the wider of the two.
    double naturalWidth = 0;
    double requiredWidth = 0;
    int offset = 0;
    for (final count in rowCounts) {
      double sumAR = 0;
      double minAR = double.infinity;
      for (int i = offset; i < offset + count; i++) {
        sumAR += aspectRatios[i];
        minAR = math.min(minAR, aspectRatios[i]);
      }
      // Natural width: row at targetRowHeight.
      naturalWidth = math.max(naturalWidth, sumAR * targetRowHeight);
      // Required width so smallest cell dimension >= minCellDim.
      // height = W / sumAR, smallest dim = height * min(1, minAR).
      // We need W / sumAR * min(1, minAR) >= minCellDim
      // → W >= minCellDim * sumAR / min(1, minAR).
      final effAR = math.min(1.0, minAR);
      requiredWidth = math.max(requiredWidth, minCellDim * sumAR / effAR);
      offset += count;
    }

    final neededWidth = math.max(naturalWidth, requiredWidth);

    if (neededWidth <= maxWidth) {
      // If cell-minimum forced expansion beyond natural width (portrait
      // images), snap to full maxWidth so the note fills available space
      // instead of sitting at an awkward intermediate width.
      final w = requiredWidth > naturalWidth
          ? maxWidth
          : math.max(naturalWidth, minWidth);
      return GridLayout(rowCounts: rowCounts, width: w);
    }

    // Needs more than maxWidth. Check if cells are OK at maxWidth.
    if (_allCellsAcceptable(aspectRatios, rowCounts, maxWidth, minCellDim)) {
      return GridLayout(rowCounts: rowCounts, width: maxWidth);
    }

    // Cells too small even at maxWidth — try more rows.
  }

  // Fallback: all items stacked (1 per row).
  final w = (aspectRatios.reduce(math.max) * targetRowHeight).clamp(
    minWidth,
    maxWidth,
  );
  return GridLayout(
    rowCounts: List.filled(n, 1),
    width: w,
  );
}

/// Check that every cell's smallest dimension (width or height) is ≥ [minDim].
bool _allCellsAcceptable(
  List<double> aspectRatios,
  List<int> rowCounts,
  double containerWidth,
  double minDim,
) {
  int offset = 0;
  for (final count in rowCounts) {
    double sumAR = 0;
    double minAR = double.infinity;
    for (int i = offset; i < offset + count; i++) {
      sumAR += aspectRatios[i];
      minAR = math.min(minAR, aspectRatios[i]);
    }
    final rowHeight = containerWidth / sumAR;
    final smallestDim = rowHeight * math.min(1.0, minAR);
    if (smallestDim < minDim) return false;
    offset += count;
  }
  return true;
}

/// Convert a partition into concrete cell dimensions for rendering.
///
/// Returns rows of [CellLayout]. The last cell in each row absorbs
/// floating-point remainder to prevent overflow.
List<List<CellLayout>> finalizeRows(
  List<double> aspectRatios,
  List<int> rowCounts,
  double containerWidth, {
  double spacing = 0.0,
}) {
  final rows = <List<CellLayout>>[];
  int offset = 0;
  for (final count in rowCounts) {
    double sumAR = 0;
    for (int i = offset; i < offset + count; i++) {
      sumAR += aspectRatios[i];
    }
    final gaps = (count - 1) * spacing;
    final height = (containerWidth - gaps) / sumAR;

    double usedWidth = 0;
    final cells = <CellLayout>[];
    for (int i = 0; i < count; i++) {
      final isLast = i == count - 1;
      final w = isLast
          ? (containerWidth - gaps - usedWidth).clamp(0.0, double.infinity)
          : height * aspectRatios[offset + i];
      cells.add(CellLayout(itemIndex: offset + i, width: w, height: height));
      if (!isLast) usedWidth += w;
    }
    rows.add(cells);
    offset += count;
  }
  return rows;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Balanced partition of [n] items into [r] rows, heavier rows first.
/// E.g. balancedPartition(7, 3) => [3, 2, 2].
List<int> _balancedPartition(int n, int r) {
  final base = n ~/ r;
  final extra = n % r;
  return [
    for (int i = 0; i < r; i++) base + (i < extra ? 1 : 0),
  ];
}
