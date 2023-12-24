part of 'fsm.dart';

class PathDelegate {
  String database = 'default';
  String eventDatabase = '';

  String get databasePath => [database, eventDatabase]
      .where((element) => element.isNotEmpty)
      .join('/');
  List<String> documentPathComponents = [];

  String get documentPath => documentPathComponents.join('/');
  List<String> valuePathComponents = [];

  String get valuePath => valuePathComponents.join('/');

  String get valuePathFull => [databasePath, documentPath, valuePath]
      .where((element) => element.isNotEmpty)
      .join('/');

  String get path => [databasePath, documentPath]
      .where((element) => element.isNotEmpty)
      .join('/');

  String get parentPath =>
      path.split('/').sublist(0, path.split('/').length - 1).join('/');

  void add(String path) => documentPathComponents.addAll(path.split('/'));

  void addAll(List<String> pathComponents) =>
      documentPathComponents.addAll(pathComponents);

  void clearDocumentPaths() {
    documentPathComponents = [];
  }

  void addValuePath(String path) => valuePathComponents.addAll(path.split('/'));
}

const bool debugMode = false;

void _printStackTrace(DocumentSnapshotWrapper snapshot) {
  if (!debugMode) return;
  print('    F: $snapshot');
  print(
      'Trace:\n${StackTrace.current.toString().split('\n').take(8).join('\n')}\n');
}

class F {
  static const String defaultEventDatabaseName = 'e';
  PathDelegate pathDelegate = PathDelegate();

  /// Internal global listener that streams all FSM updates.
  /// Use via [globalObserverListener].
  static PublishSubject<dynamic> _globalObserverStream =
      PublishSubject<dynamic>();
  static Map<String, BehaviorSubject<DocumentReferenceWrapper>> collections =
      {};
  static Map<String, BehaviorSubject<DocumentSnapshotWrapper>> snapshots = {};
  static Map<String, BehaviorSubject<dynamic>> values = {};

  static F get instance => F._();

  F._();

  void destroy() {
    snapshots.forEach((_, value) => value.close());
    snapshots.clear();
    collections.forEach((_, value) => value.close());
    collections.clear();
    values.forEach((_, value) => value.close());
    values.clear();
    _globalObserverStream.close();
    _globalObserverStream = PublishSubject<dynamic>();
  }

  FirestoreDatabaseReference database([String? database]) {
    if (database != null) {
      assert(database.isNotEmpty, 'Database name cannot be empty.');
      pathDelegate.database = database;
    }
    return FirestoreDatabaseReference._(pathDelegate, this);
  }

  FirestoreEventDatabaseReference eventDatabase([String? database]) {
    if (database != null) {
      assert(database.isNotEmpty, 'Database name cannot be empty.');
      pathDelegate.eventDatabase = database;
    } else {
      pathDelegate.eventDatabase = defaultEventDatabaseName;
    }
    print('Inline: ${pathDelegate.path}');
    return FirestoreEventDatabaseReference._(pathDelegate, this);
  }

  CollectionReferenceWrapper collection(String path) {
    assert(path.isNotEmpty);
    pathDelegate.add(path);
    return CollectionReferenceWrapper._(pathDelegate, this);
  }

  DocumentReferenceWrapper doc(String path) {
    assert(path.isNotEmpty);
    pathDelegate.add(path);
    assert(pathDelegate.documentPathComponents.length.isEven,
        'Documents must be referenced from a collection');
    return DocumentReferenceWrapper._(pathDelegate, this);
  }

  ValueReferenceWrapper _value(String path) {
    assert(path.isNotEmpty);
    pathDelegate.addValuePath(path);
    return ValueReferenceWrapper._(pathDelegate, this);
  }

  DocumentSnapshotWrapper _snapshot([DocumentEvent? documentEvent]) {
    return DocumentSnapshotWrapper._(pathDelegate, this, documentEvent);
  }

  Future<void> _setDocumentData(
    DocumentReferenceWrapper documentReference,
    dynamic data, {
    bool merge = false,
    bool notify = false,
  }) async {
    // Initialize collection stream.
    if (!collections.containsKey(pathDelegate.parentPath)) {
      collections[pathDelegate.parentPath] =
          BehaviorSubject<DocumentReferenceWrapper>();
    }
    // Initialize document stream.
    if (!snapshots.containsKey(pathDelegate.path)) {
      snapshots[pathDelegate.path] = BehaviorSubject<DocumentSnapshotWrapper>();
    }
    // Initialize value stream.
    bool isValue = (pathDelegate.valuePathComponents.isNotEmpty);
    if (isValue) {
      if (!values.containsKey(pathDelegate.valuePathFull)) {
        values[pathDelegate.valuePathFull] = BehaviorSubject<dynamic>();
      }
    }

    // Get old snapshot value or empty snapshot.
    DocumentSnapshotWrapper snapshot =
        snapshots[pathDelegate.path]?.valueOrNull ?? _snapshot();

    // If notify is false, check if data has changed and skip update if data hasn't changed.
    // Else if notify is true, the notify event is either:
    // 1. Signal Only (No Data Change)
    // 2. Data Update and Notify
    if (notify) {
      // If this is a notify operation, notify listeners directly.
      if (data == null) {
        snapshots[pathDelegate.path]?.add(snapshot);
        if (isValue) {
          values[pathDelegate.valuePathFull]?.add(data);
        }
        collections[pathDelegate.parentPath]?.add(documentReference);
        _globalObserverStream.add(snapshot);
        // _printStackTrace(snapshot);
        return;
      }
    } else {
      // Data is unchanged. Do not update.
      // Exclude collections because collection references
      // are equal even if contents change. Collections must
      // be deep compared to determine equality.
      if (snapshot.data is! Set &&
          snapshot.data is! List) if (snapshot.data == data && !isValue) return;
      // Value is unchanged. Do not update.
      if (isValue) {
        dynamic oldValue = getValue(snapshot.data, pathDelegate.valuePath);
        if (oldValue == data) return;
      }
    }

    if (merge) {
      // Build Map if value exists. Else, default to data.
      dynamic dataHolder =
          buildValueMap(data, pathDelegate.valuePathComponents);
      // Merge old and new data if both are Maps and can be merged.
      if (snapshot.data is Map && dataHolder is Map) {
        dataHolder = updateData(snapshot.data, dataHolder);
      }
      // Package data as DocumentEvent.
      DocumentEvent documentEvent = DocumentEvent(dataHolder);
      // Create a new snapshot with the merged data.
      DocumentSnapshotWrapper snapshotHolder = _snapshot(documentEvent);
      // Update snapshot stream with the new snapshot.
      snapshots[pathDelegate.path]?.add(snapshotHolder);
      // Update value stream if necessary.
      if (isValue) {
        values[pathDelegate.valuePathFull]
            ?.add(getValue(dataHolder, pathDelegate.valuePath));
      }
      _globalObserverStream.add(snapshotHolder);
      // _printStackTrace(snapshot);
    } else {
      // Set mutable data holder.
      dynamic dataHolder = data;
      // Set value in Map if value exists.
      if (isValue) {
        dataHolder =
            setData(snapshot.data, data, pathDelegate.valuePathComponents);
      }
      // Package data as DocumentEvent.
      DocumentEvent documentEvent = DocumentEvent(dataHolder);
      DocumentSnapshotWrapper snapshotHolder = _snapshot(documentEvent);
      // Create new snapshot and add to snapshot stream.
      snapshots[pathDelegate.path]?.add(snapshotHolder);
      // Update value stream.
      if (isValue) {
        values[pathDelegate.valuePathFull]?.add(data);
      }
      _globalObserverStream.add(snapshotHolder);
      // _printStackTrace(snapshotHolder);
    }
    // Add document to collection stream.
    collections[pathDelegate.parentPath]?.add(documentReference);
    return;
  }

  Future<void> _updateDocumentData(
      DocumentReferenceWrapper documentReference, dynamic data,
      {bool notify = false}) async {
    if (snapshots.containsKey(pathDelegate.path)) {
      if ((snapshots[pathDelegate.path]?.hasValue ?? false) &&
          getValue(snapshots[pathDelegate.path]?.value.data,
                  pathDelegate.valuePath) !=
              null) {
        _setDocumentData(documentReference, data, merge: true, notify: notify);
      }
    }
    return;
  }

  Future<DocumentSnapshotWrapper> _getDocumentData() {
    if (snapshots.containsKey(pathDelegate.path)) {
      return Future.value(snapshots[pathDelegate.path]?.value);
    }

    return Future.value(_snapshot());
  }

  DocumentSnapshotWrapper _getDocumentSnapshot() {
    if (snapshots.containsKey(pathDelegate.path)) {
      return snapshots[pathDelegate.path]?.valueOrNull ?? _snapshot();
    }

    return _snapshot();
  }

  DocumentReferenceWrapper _getCollectionSnapshot() {
    if (collections.containsKey(pathDelegate.path)) {
      return collections[pathDelegate.path]!.value;
    }

    return doc(AutoID.autoID);
  }

  Stream<DocumentReferenceWrapper> _collectionSnapshot(
      {bool includeMetadataChanges = false}) {
    if (!collections.containsKey(pathDelegate.path)) {
      collections[pathDelegate.path] =
          BehaviorSubject<DocumentReferenceWrapper>();
    }

    return collections[pathDelegate.path]!.stream;
  }

  Stream<DocumentSnapshotWrapper> _documentSnapshot(
      {bool includeMetadataChanges = false}) {
    if (!snapshots.containsKey(pathDelegate.path)) {
      snapshots[pathDelegate.path] = BehaviorSubject<DocumentSnapshotWrapper>();
    }

    return snapshots[pathDelegate.path]!.stream;
  }

  Stream<dynamic> _valueSnapshot({bool includeMetadataChanges = false}) {
    if (!values.containsKey(pathDelegate.valuePathFull)) {
      values[pathDelegate.valuePathFull] = BehaviorSubject<dynamic>();
    }

    return values[pathDelegate.valuePathFull]!.stream;
  }

  BehaviorSubject<DocumentSnapshotWrapper> _getDocumentController() {
    if (snapshots.containsKey(pathDelegate.path)) {
      return snapshots[pathDelegate.path]!;
    }

    return snapshots[pathDelegate.path] =
        BehaviorSubject<DocumentSnapshotWrapper>();
  }

  BehaviorSubject<DocumentReferenceWrapper> _getCollectionController() {
    if (collections.containsKey(pathDelegate.path)) {
      return collections[pathDelegate.path]!;
    }

    return collections[pathDelegate.path] =
        BehaviorSubject<DocumentReferenceWrapper>();
  }

  void _closeCollection() {
    if (collections.containsKey(pathDelegate.path) &&
        collections[pathDelegate.path]!.hasListener == false) {
      collections[pathDelegate.path]!.close();
    }
  }

  void _closeDocument() {
    if (snapshots.containsKey(pathDelegate.path) &&
        snapshots[pathDelegate.path]!.hasListener == false) {
      snapshots[pathDelegate.path]!.close();
    }
  }

  void _closeValue() {
    if (values.containsKey(pathDelegate.path) &&
        values[pathDelegate.path]!.hasListener == false) {
      snapshots[pathDelegate.path]!.close();
    }
  }

  /// A global listener that streams all FSM updates.
  ///
  /// The internal listener implementation is a static
  /// instance so this getter reinitializes the stream if
  /// it has been closed.
  ///
  /// This listener is useful for debugging FSM updates.
  /// ```dart
  ///     if (FlavorConfig.isDebug) {
  ///       F.instance.globalObserverListener.listen((value) {
  ///         print('Update: $value');
  ///       });
  ///    }
  /// ```
  PublishSubject<dynamic> get globalObserverListener {
    if (_globalObserverStream.isClosed) {
      _globalObserverStream = PublishSubject<dynamic>();
    }
    return _globalObserverStream;
  }
}

class FirestoreDatabaseReference {
  final PathDelegate pathDelegate;
  final F f;

  FirestoreDatabaseReference._(this.pathDelegate, this.f);

  FirestoreEventDatabaseReference eventDatabase([String? database]) {
    return f.eventDatabase(database);
  }

  DocumentReferenceWrapper doc(String path) {
    return f.doc(path);
  }

  CollectionReferenceWrapper collection(String path) {
    return f.collection(path);
  }
}

class FirestoreEventDatabaseReference {
  final PathDelegate pathDelegate;
  final F f;

  FirestoreEventDatabaseReference._(this.pathDelegate, this.f);

  DocumentReferenceWrapper doc(String path) {
    return f.doc(path);
  }

  CollectionReferenceWrapper collection(String path) {
    return f.collection(path);
  }
}

abstract class ReferenceWrapper {
  final PathDelegate pathDelegate;
  final F f;

  ReferenceWrapper(this.pathDelegate, this.f);

  String get path => pathDelegate.path;

  void close();
}

class CollectionReferenceWrapper extends ReferenceWrapper {
  CollectionReferenceWrapper._(super.pathDelegate, super.f);

  String? get id => pathDelegate.documentPathComponents.isEmpty
      ? null
      : pathDelegate.documentPathComponents.last;

  DocumentReferenceWrapper? parent() {
    if (pathDelegate.documentPathComponents.length < 2) {
      return null;
    }
    final parentPathComponents = pathDelegate.documentPathComponents
      ..removeLast();
    return f.doc(parentPathComponents.join('/'));
  }

  String get collectionPath => pathDelegate.documentPath;

  String get collectionID => pathDelegate.documentPathComponents.last;

  Future<DocumentReferenceWrapper> getDocuments() async {
    return f._getCollectionSnapshot();
  }

  Stream<DocumentReferenceWrapper> snapshots(
          {bool includeMetadataChanges = false}) =>
      f._collectionSnapshot(includeMetadataChanges: includeMetadataChanges);

  BehaviorSubject<DocumentReferenceWrapper> get streamController =>
      f._getCollectionController();

  DocumentReferenceWrapper doc([String? path]) {
    return f.doc(path ?? AutoID.autoID);
  }

  Future<DocumentReferenceWrapper> add(
    dynamic data, {
    bool merge = false,
  }) async {
    final DocumentReferenceWrapper newDocument = doc();
    await newDocument.setData(data, merge: merge);
    return newDocument;
  }

  @override
  void close() {
    f._closeCollection();
  }

  @override
  String toString() =>
      'CollectionReferenceWrapper("id": "$collectionID", "path": "$path")';

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(dynamic other) =>
      other is CollectionReferenceWrapper && other.path == path;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(pathDelegate.documentPathComponents);
}

class DocumentReferenceWrapper extends ReferenceWrapper {
  DocumentReferenceWrapper._(super.pathDelegate, super.f);

  CollectionReferenceWrapper parent() {
    List<String> pathComponents = pathDelegate.documentPathComponents
      ..removeLast();
    pathDelegate.clearDocumentPaths();
    return f.collection(pathComponents.join('/'));
  }

  String get documentPath => pathDelegate.documentPath;

  String get documentID => pathDelegate.documentPathComponents.last;

  Future<void> setData(
    dynamic data, {
    bool merge = false,
    bool notify = false,
  }) {
    return f._setDocumentData(this, data, merge: merge, notify: notify);
  }

  Future<void> updateData(dynamic data, {bool notify = false}) {
    return f._updateDocumentData(this, data, notify: notify);
  }

  // Causes linter warnings if we set the return type to Future<void>
  // ignore: avoid_void_async
  void notify() async {
    _printStackTrace(snapshot);
    return f._setDocumentData(this, null, notify: true);
  }

  Future<DocumentSnapshotWrapper> get() async {
    return f._getDocumentData();
  }

  CollectionReferenceWrapper collection(String path) {
    return f.collection(path);
  }

  ValueReferenceWrapper value(String path) {
    return f._value(path);
  }

  Stream<DocumentSnapshotWrapper> snapshots(
          {bool includeMetadataChanges = false}) =>
      f._documentSnapshot(includeMetadataChanges: includeMetadataChanges);

  DocumentSnapshotWrapper get snapshot => f._getDocumentSnapshot();

  BehaviorSubject<DocumentSnapshotWrapper> get streamController =>
      f._getDocumentController();

  @override
  void close() {
    f._closeDocument();
  }

  @override
  String toString() =>
      'DocumentReferenceWrapper("id": "$documentID", "path": "$path")';

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(dynamic other) =>
      other is DocumentReferenceWrapper && other.path == path;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(pathDelegate.documentPathComponents);
}

class ValueReferenceWrapper extends ReferenceWrapper {
  ValueReferenceWrapper._(super.pathDelegate, super.f);

  dynamic get data => getValue(
      f.doc(pathDelegate.documentPathComponents.removeLast()).snapshot.data,
      pathDelegate.valuePath);

  Future<void> setData(
    dynamic data, {
    bool merge = false,
    bool notify = false,
  }) {
    DocumentReferenceWrapper documentReferenceWrapper =
        f.doc(pathDelegate.documentPathComponents.removeLast());
    return f._setDocumentData(documentReferenceWrapper, data,
        merge: merge, notify: notify);
  }

  Future<void> updateData(dynamic data, {bool notify = false}) {
    DocumentReferenceWrapper documentReferenceWrapper =
        f.doc(pathDelegate.documentPathComponents.removeLast());
    return f._updateDocumentData(documentReferenceWrapper, data,
        notify: notify);
  }

  // ignore: avoid_void_async
  void notify() async {
    DocumentReferenceWrapper documentReferenceWrapper =
        f.doc(pathDelegate.documentPathComponents.removeLast());
    _printStackTrace(documentReferenceWrapper.snapshot);
    return f._setDocumentData(documentReferenceWrapper, null, notify: true);
  }

  @override
  String get path => pathDelegate.valuePathFull;

  @override
  void close() {
    f._closeValue();
  }

  /// Value data stream.
  ///
  /// Streams changes to the observed value.
  /// Updating a value only updates direct snapshot listeners.
  /// Any parent or child streams are not updated.
  /// This is a performance optimization and prevents
  /// complex dependencies. To observe all path updates,
  /// listen to the root [DocumentSnapshotWrapper].
  Stream<dynamic> values({bool includeMetadataChanges = false}) =>
      f._valueSnapshot(includeMetadataChanges: includeMetadataChanges);
}

class DocumentSnapshotWrapper {
  final PathDelegate pathDelegate;
  final F f;
  DocumentEvent? documentEvent;
  dynamic data;

  DocumentSnapshotWrapper._(this.pathDelegate, this.f, this.documentEvent)
      : data = documentEvent?.data;

  DocumentReferenceWrapper get reference =>
      f.doc(pathDelegate.documentPathComponents.removeLast());

  dynamic operator [](String key) => data[key];

  String get path => pathDelegate.path;

  String get documentPath => pathDelegate.documentPath;

  String get documentID => pathDelegate.documentPathComponents.last;

  dynamic value(String path) => getValue(data, path);

  bool get exists => data != null;

  void _updateDocumentEvent(DocumentEvent documentEvent) {
    this.documentEvent = documentEvent;
    data = documentEvent.data;
  }

  @override
  String toString() =>
      'DocumentSnapshotWrapper("id": "$documentID", "path": "$path", "documentEvent": $documentEvent, "data": $data)';

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(dynamic other) =>
      other is DocumentSnapshotWrapper && other.path == path;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll(pathDelegate.documentPathComponents);
}

class DocumentEvent {
  String? event;
  late FTimestamp timestamp;
  dynamic data;

  DocumentEvent(this.data, {this.event, FTimestamp? timestamp})
      : timestamp = timestamp ?? FTimestamp.now();

  Map<String, dynamic> toMap() => {
        'e': event,
        't': timestamp,
        'd': data,
      };

  @override
  String toString() => toMap().toString();

  Map<String, dynamic> get value => toMap();
}

dynamic getValue(dynamic value, String path) {
  List<String> pathComponents = path.split('/');
  dynamic valueHolder = value;
  // Empty path returns root value.
  if (pathComponents.length == 1 && pathComponents[0] == '') return valueHolder;
  for (int i = 0; i < pathComponents.length; i++) {
    if (valueHolder is Map) {
      String path = pathComponents[i];
      if (valueHolder.containsKey(path)) {
        valueHolder = valueHolder[path];
      } else {
        return null;
      }
    } else {
      // TODO: Additional special query support (i.e. lists).
      // Invalid path. Return no value.
      if (i < pathComponents.length - 1) {
        return null;
      }
    }
  }

  return valueHolder;
}

dynamic buildValueMap(dynamic value, List<String> pathComponents) {
  if (pathComponents.isEmpty) return value;
  List<String> pathComponentsHolder = [];
  pathComponentsHolder.addAll(pathComponents);
  Map<String, dynamic> dataHolder = {pathComponentsHolder.removeLast(): value};
  for (String path in pathComponentsHolder.reversed) {
    dataHolder = {path: dataHolder};
  }
  return dataHolder;
}

dynamic updateData(dynamic data, dynamic dataNew) {
  // Mutable original data holder.
  dynamic dataHolder = data;
  // Merge update if both old and new data are Maps.
  if (dataHolder is Map && dataNew is Map) {
    // Cast type to prevent invalid type error.
    dataHolder = Map<String, dynamic>.from(data);
    // Update each key value.
    for (String key in dataNew.keys) {
      // Recursively update key values.
      if (dataHolder[key] != null) {
        if (dataHolder[key] is Map) {
          dataHolder[key] = updateData(dataHolder[key], dataNew[key]);
          continue;
        }
      }

      // Key does not exist in data. Set to value directly.
      dataHolder[key] = dataNew[key];
    }
  } else {
    // Data cannot be merged. Overwrite existing data.
    dataHolder = dataNew;
  }

  return dataHolder;
}

dynamic setData(dynamic data, dynamic dataNew, List<String> pathComponents) {
  dynamic dataHolder = data;
  List<String> pathComponentsHolder = [];
  pathComponentsHolder.addAll(pathComponents);
  if (pathComponentsHolder.isEmpty) return dataHolder = dataNew;
  if (dataHolder == null) return buildValueMap(dataNew, pathComponentsHolder);
  if (dataHolder is Map) dataHolder = Map<String, dynamic>.from(dataHolder);
  String path = pathComponentsHolder.first;
  if (pathComponentsHolder.length > 1) {
    // Build path.
    if (dataHolder is Map && dataHolder.containsKey(path)) {
      dataHolder[path] =
          setData(dataHolder[path], dataNew, pathComponentsHolder.sublist(1));
    } else {
      // Create new Map that overrides existing
      // type if more path components exist.
      if (dataHolder is! Map) dataHolder = <String, dynamic>{};
      dataHolder[path] = <String, dynamic>{};
      dataHolder[path] =
          buildValueMap(dataNew, pathComponentsHolder.sublist(1));
    }
  } else {
    // Set final path value.
    if (dataHolder is Map) {
      // Set key to value.
      dataHolder[path] = dataNew;
    } else {
      // Set value.
      if (dataHolder is! Map) dataHolder = <String, dynamic>{};
      dataHolder[path] = <String, dynamic>{};
      dataHolder[path] = dataNew;
    }
  }

  return dataHolder;
}
