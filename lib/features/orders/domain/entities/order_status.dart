/// Lifecycle status of an [Order].
///
/// - [placed]: the order has been submitted but work has not started.
/// - [inProgress]: stitching is underway.
/// - [ready]: the item is finished and ready for pickup.
/// - [completed]: the order has been picked up / closed.
enum OrderStatus { placed, inProgress, ready, completed }
