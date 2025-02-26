class Coordinates {
  final int x;
  final int y;

  Coordinates(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinates &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Coordinates{x: $x, y: $y}';
}

class TheatreSeat {
  final String row;
  final int count;
  final Coordinates coordinates;

  TheatreSeat(this.row, this.count, this.coordinates);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TheatreSeat &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          count == other.count &&
          coordinates == other.coordinates;

  @override
  int get hashCode => row.hashCode ^ count.hashCode ^ coordinates.hashCode;

  @override
  String toString() =>
      'TheatreSeat{row: $row, count: $count, coordinates: $coordinates}';
}
