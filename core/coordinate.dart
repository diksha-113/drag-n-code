// lib/core/coordinate.dart

class Coordinate {
  double x;
  double y;

  /// Optional: connection object (used in snapping/dragging)
  dynamic connection;

  /// Optional: radius for closest snapping calculations
  double radius;

  /// Constructor
  Coordinate(this.x, this.y, {this.connection, this.radius = 0.0});

  /// Translate coordinate by dx and dy
  void translate(double dx, double dy) {
    x += dx;
    y += dy;
  }

  /// Return a new Coordinate translated by dx and dy
  Coordinate translated(double dx, double dy) =>
      Coordinate(x + dx, y + dy, connection: connection, radius: radius);

  /// Return a copy of this coordinate
  Coordinate copy() => Coordinate(x, y, connection: connection, radius: radius);

  /// Compare two coordinates
  bool equals(Coordinate? other) {
    if (other == null) return false;
    return x == other.x && y == other.y;
  }

  /// Operator overload for adding coordinates
  Coordinate operator +(Coordinate other) =>
      Coordinate(x + other.x, y + other.y,
          connection: connection, radius: radius);

  /// Operator overload for subtracting coordinates
  Coordinate operator -(Coordinate other) =>
      Coordinate(x - other.x, y - other.y,
          connection: connection, radius: radius);

  @override
  String toString() =>
      'Coordinate(x: $x, y: $y, radius: $radius, connection: $connection)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinate &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
