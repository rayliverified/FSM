part of 'fsm.dart';

mixin FListenerMixin {
  Map<String, ReferenceWrapper> _referenceWrappers = {};
  Map<String, StreamSubscription> _subscriptions = {};

  /// Allows to group subscriptions so that the group can be closed without
  /// calling [FListenerMixin.closeF]. This is useful when you want to cancel
  /// a specific set of stream listeners, just pass a custom box name when
  /// listening to the stream.
  Map<String, Set<String>> _boxes = {};

  /// Listens to a stream and saves it to the list of subscriptions.
  void listenF(ReferenceWrapper reference, void Function(dynamic data) onData,
      {Function? onError, String box = 'default'}) {
    Stream stream;
    Type type = reference.runtimeType;
    switch (type) {
      case const (CollectionReferenceWrapper):
        throw ('CollectionReferenceWrapper is not yet supported');
      case const (DocumentReferenceWrapper):
        stream = (reference as DocumentReferenceWrapper).snapshots();
      case const (ValueReferenceWrapper):
        stream = (reference as ValueReferenceWrapper).values();
      default:
        return;
    }

    _referenceWrappers[reference.path] = reference;
    _subscriptions[reference.path] = stream.listen(onData, onError: onError);
    _boxes[box] ??= {};
    _boxes[box]!.add(reference.path);
  }

  void addListenerF(ReferenceWrapper reference, StreamSubscription listener,
      {String box = 'default'}) {
    _referenceWrappers[reference.path] = reference;
    _subscriptions[reference.path] = listener;
    _boxes[box] ??= {};
    _boxes[box]!.add(reference.path);
  }

  /// Cancels all streams that were previously added with listen().
  void closeF() {
    _referenceWrappers.entries.forEach((element) => element.value.close());
    _subscriptions.entries.forEach((element) => element.value.cancel());
    _boxes.clear();
  }

  void closeBox(String box) {
    if (_boxes[box]?.isEmpty ?? true) return;
    for (final ref in _boxes[box]!) {
      _referenceWrappers.remove(ref)?.close();
      _subscriptions.remove(ref)?.cancel();
    }
    _boxes[box]?.clear();
  }
}

/// Imported from `firebase/ui/utils/stream_subscriber_mixin.dart`.
/// Mixin for classes that own `StreamSubscription`s and expose an API for
/// disposing of themselves by cancelling the subscriptions
mixin FStreamSubscriberMixin {
  List<StreamSubscription> _subscriptions = <StreamSubscription>[];

  /// Listens to a stream and saves it to the list of subscriptions.
  void listen<T>(
    Stream<T>? stream,
    void Function(T data) onData, {
    Function? onError,
  }) {
    if (stream != null) {
      _subscriptions.add(stream.listen(onData, onError: onError));
    }
  }

  /// Cancels all streams that were previously added with listen().
  void cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}

mixin FListenerChangeNotifierMixin on ChangeNotifier {
  Map<String, ReferenceWrapper> _referenceWrappers = {};
  Map<String, StreamSubscription> _subscriptions = {};

  @override
  void dispose() {
    closeF();
    super.dispose();
  }

  /// Listens to a stream and saves it to the list of subscriptions.
  void listenF(ReferenceWrapper reference, void Function(dynamic data) onData,
      {Function? onError}) {
    Stream stream;
    Type type = reference.runtimeType;
    switch (type) {
      case const (CollectionReferenceWrapper):
        throw ('CollectionReferenceWrapper is not yet supported');
      case const (DocumentReferenceWrapper):
        stream = (reference as DocumentReferenceWrapper).snapshots();
      case const (ValueReferenceWrapper):
        stream = (reference as ValueReferenceWrapper).values();
      default:
        return;
    }

    _referenceWrappers[reference.path] = reference;
    _subscriptions[reference.path] = stream.listen(onData, onError: onError);
  }

  void addListenerF(ReferenceWrapper reference, StreamSubscription listener) {
    _referenceWrappers[reference.path] = reference;
    _subscriptions[reference.path] = listener;
  }

  /// Cancels all streams that were previously added with listen().
  void closeF() {
    _referenceWrappers.entries.forEach((element) => element.value.close());
    _subscriptions.entries.forEach((element) => element.value.cancel());
  }
}
