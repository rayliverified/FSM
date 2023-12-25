part of 'fsm.dart';

typedef StreamWidgetBuilder<T> = Widget Function(BuildContext context, T value);

typedef FunctionMap<T> = T Function(T value);

Type typeOf<T>() => T;

class LocalDocumentStream<T> extends StatefulWidget {
  final String document;
  final dynamic initialData;
  final FunctionMap<dynamic>? map;
  final StreamWidgetBuilder<T> builder;
  final String? database;

  const LocalDocumentStream({
    super.key,
    this.database,
    required this.document,
    required this.builder,
    this.initialData,
    this.map,
  });

  @override
  State<LocalDocumentStream<T>> createState() => _LocalDocumentStreamState<T>();
}

class _LocalDocumentStreamState<T> extends State<LocalDocumentStream<T>> {
  late ValueStream<DocumentSnapshotWrapper> stream;

  @override
  void initState() {
    super.initState();
    // Initialize DocumentSnapshot stream.
    stream = F.instance
        .database(widget.database)
        .doc(widget.document)
        .snapshots() as ValueStream<DocumentSnapshotWrapper>;
  }

  @override
  void dispose() {
    // Close document stream.
    F.instance.database(widget.database).doc(widget.document).close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: stream,
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshotWrapper> snapshot) {
        // First StreamBuilder data is empty. Return initial data immediately.
        T value = widget.initialData;
        // Return DocumentSnapshotWrapper directly and ignore type mapping.
        Type type = typeOf<T>();
        if (type == DocumentSnapshotWrapper) {
          value = snapshot.data as T;
          return widget.builder(context, value);
        }
        if (snapshot.hasData) {
          value = snapshot.data!.data;
          if (widget.map != null) {
            // Transpose typed value to dynamic to support mapping function.
            dynamic valueHolder = value;
            value = widget.map!.call(valueHolder);
          }
        }
        return widget.builder(context, value);
      },
    );
  }
}

class LocalEventStream<Object> extends StatefulWidget {
  final String event;
  final StreamWidgetBuilder<Object> builder;
  final dynamic initialData;
  final FunctionMap<dynamic>? map;
  final String? database;
  final String? eventDatabase;

  const LocalEventStream({
    super.key,
    required this.event,
    required this.builder,
    this.initialData,
    this.map,
    this.database,
    this.eventDatabase,
  });

  @override
  State<LocalEventStream<Object>> createState() =>
      _LocalEventStreamState<Object>();
}

class _LocalEventStreamState<T> extends State<LocalEventStream<T>> {
  late ValueStream<DocumentReferenceWrapper> stream;

  @override
  void initState() {
    super.initState();
    stream = F.instance
        .database(widget.database)
        .eventDatabase(widget.eventDatabase)
        .collection(widget.event)
        .snapshots() as ValueStream<DocumentReferenceWrapper>;
  }

  @override
  void dispose() {
    F.instance
        .database(widget.database)
        .eventDatabase(widget.eventDatabase)
        .collection(widget.event)
        .close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: stream,
        builder: (BuildContext context,
            AsyncSnapshot<DocumentReferenceWrapper> snapshot) {
          T value = widget.initialData;
          if (snapshot.hasData) {
            value = snapshot.data!.snapshot.data;
            // Map data to data model if mapping function exists.
            if (widget.map != null) value = widget.map!.call(value);
          }
          return widget.builder(context, value);
        });
  }
}

class MultiStreamBuilder extends StatefulWidget {
  final List<ReferenceWrapper> references;
  final StreamWidgetBuilder<Map<String, dynamic>> builder;

  const MultiStreamBuilder(
      {super.key, required this.references, required this.builder});

  @override
  State<MultiStreamBuilder> createState() => _MultiStreamBuilderState();
}

class _MultiStreamBuilderState extends State<MultiStreamBuilder> {
  Map<String, Stream> referenceStreams = {};
  List<StreamSubscription> referenceStreamSubscriptions = [];
  Map<String, dynamic> referenceSnapshot = {};
  BehaviorSubject<Map<String, dynamic>> referenceSnapshotStream =
      BehaviorSubject();

  @override
  void initState() {
    super.initState();
    // Initialize stream listeners for StreamReferences.
    for (ReferenceWrapper reference in widget.references) {
      // Get Stream and resolve ReferenceWrapper type.
      referenceStreams[reference.path] = getReferenceStream(reference);
      // Initialize stream listeners and save StreamSubscriptions.
      referenceStreamSubscriptions
          .add(referenceStreams[reference.path]!.listen((snapshot) {
        switch (snapshot.runtimeType) {
          case const (DocumentReferenceWrapper):
            // TODO: Handle collections.
            break;
          case const (DocumentSnapshotWrapper):
            dynamic value = snapshot.data;
            referenceSnapshot[reference.path] = value;
          default: // ValueReferenceWrapper dynamic value updates.
            referenceSnapshot[reference.path] = snapshot;
            break;
        }
        referenceSnapshotStream.add(referenceSnapshot);
      }));
    }
  }

  @override
  void dispose() {
    // Cancel active subscriptions when widget is disposed.
    for (StreamSubscription streamSubscription
        in referenceStreamSubscriptions) {
      streamSubscription.cancel();
    }
    referenceSnapshotStream.close();
    referenceSnapshot.clear();
    referenceStreams.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: referenceSnapshotStream.stream,
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        return widget.builder.call(context, snapshot.data ?? {});
      },
    );
  }
}

/// Get the [Stream] from a [ReferenceWrapper] [reference].
///
/// Resolves the [ReferenceWrapper] type to [CollectionReferenceWrapper],
/// [DocumentReferenceWrapper], or [ValueReferenceWrapper].
Stream getReferenceStream(ReferenceWrapper reference) {
  switch (reference.runtimeType) {
    case const (CollectionReferenceWrapper):
      return (reference as CollectionReferenceWrapper).snapshots();
    case const (DocumentReferenceWrapper):
      return (reference as DocumentReferenceWrapper).snapshots();
    case const (ValueReferenceWrapper):
      return (reference as ValueReferenceWrapper).values();
  }

  return const Stream.empty();
}
