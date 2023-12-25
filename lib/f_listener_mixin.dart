part of 'fsm.dart';

mixin FListenerMixin {
  final Map<String, ReferenceWrapper> _referenceWrappers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Allows to group subscriptions so that the group can be closed without
  /// calling [FListenerMixin.closeF]. This is useful when you want to cancel
  /// a specific set of stream listeners, just pass a custom group name when
  /// listening to the stream.
  final Map<String, Set<String>> _groups = {};

  /// Listens to a stream and saves it to the list of subscriptions.
  void listenF(ReferenceWrapper reference, void Function(dynamic data) onData,
      {Function? onError, String name = 'default'}) {
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
    (_groups[name] ?? {}).add(reference.path);
  }

  void addListenerF(ReferenceWrapper reference, StreamSubscription listener,
      {String name = 'default'}) {
    _referenceWrappers[reference.path] = reference;
    _subscriptions[reference.path] = listener;
    (_groups[name] ?? {}).add(reference.path);
  }

  /// Cancels all streams that were previously added with listen().
  void closeF() {
    for (var element in _referenceWrappers.entries) {
      element.value.close();
    }
    for (var element in _subscriptions.entries) {
      element.value.cancel();
    }
    _groups.clear();
  }

  void closeFGroup(String name) {
    if (_groups[name]?.isEmpty ?? true) return;
    for (final ref in _groups[name]!) {
      _referenceWrappers.remove(ref)?.close();
      _subscriptions.remove(ref)?.cancel();
    }
    _groups[name]!.clear();
  }
}

mixin FListenerStateMixin<T extends StatefulWidget> on State<T> {
  final Map<String, ReferenceWrapper> _referenceWrappers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Allows to group subscriptions so that the group can be closed without
  /// calling [FListenerMixin.closeF]. This is useful when you want to cancel
  /// a specific set of stream listeners, just pass a custom group name when
  /// listening to the stream.
  final Map<String, Set<String>> _groups = {};

  @override
  void dispose() {
    closeF();
    super.dispose();
  }

  /// Listens to a stream and saves it to the list of subscriptions.
  void listenF(ReferenceWrapper reference, void Function(dynamic data) onData,
      {Function? onError, String name = 'default'}) {
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
    (_groups[name] ?? {}).add(reference.path);
  }

  /// Cancels all streams that were previously added with listen().
  void closeF() {
    for (var element in _referenceWrappers.entries) {
      element.value.close();
    }
    for (var element in _subscriptions.entries) {
      element.value.cancel();
    }
    _groups.clear();
  }

  void closeFGroup(String name) {
    if (_groups[name]?.isEmpty ?? true) return;
    for (final ref in _groups[name]!) {
      _referenceWrappers.remove(ref)?.close();
      _subscriptions.remove(ref)?.cancel();
    }
    _groups[name]!.clear();
  }
}

mixin FListenerChangeNotifierMixin on ChangeNotifier {
  final Map<String, ReferenceWrapper> _referenceWrappers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Allows to group subscriptions so that the group can be closed without
  /// calling [FListenerMixin.closeF]. This is useful when you want to cancel
  /// a specific set of stream listeners, just pass a custom group name when
  /// listening to the stream.
  final Map<String, Set<String>> _groups = {};

  @override
  void dispose() {
    closeF();
    super.dispose();
  }

  /// Listens to a stream and saves it to the list of subscriptions.
  void listenF(ReferenceWrapper reference, void Function(dynamic data) onData,
      {Function? onError, String name = 'default'}) {
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
    (_groups[name] ?? {}).add(reference.path);
  }

  /// Cancels all streams that were previously added with listen().
  void closeF() {
    for (var element in _referenceWrappers.entries) {
      element.value.close();
    }
    for (var element in _subscriptions.entries) {
      element.value.cancel();
    }
    _groups.clear();
  }

  void closeFGroup(String name) {
    if (_groups[name]?.isEmpty ?? true) return;
    for (final ref in _groups[name]!) {
      _referenceWrappers.remove(ref)?.close();
      _subscriptions.remove(ref)?.cancel();
    }
    _groups[name]!.clear();
  }
}

/// Imported from `firebase/ui/utils/stream_subscriber_mixin.dart`.
/// Mixin for classes that own `StreamSubscription`s and expose an API for
/// disposing of themselves by cancelling the subscriptions
mixin FStreamSubscriberMixin {
  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];

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

/// Imported from `firebase/ui/utils/stream_subscriber_mixin.dart`.
/// Mixin for classes that own `StreamSubscription`s and expose an API for
/// disposing of themselves by cancelling the subscriptions
mixin FStreamSubscriberStateMixin<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];

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

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  /// Cancels all streams that were previously added with listen().
  void cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}

/// Imported from `firebase/ui/utils/stream_subscriber_mixin.dart`.
/// Mixin for classes that own `StreamSubscription`s and expose an API for
/// disposing of themselves by cancelling the subscriptions
mixin FStreamSubscriberChangeNotifierMixin on ChangeNotifier {
  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];

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

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }

  /// Cancels all streams that were previously added with listen().
  void cancelSubscriptions() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}
