import 'package:flutter_test/flutter_test.dart';
import 'package:fsm/fsm.dart';

void main() {
  group('CollectionReference', () {
    Map<String, dynamic> data1 = {'field_1': 'value_1'};
    Map<String, dynamic> data2 = {'field_1': 'value_2'};
    Map<String, dynamic> data3 = {'field_1': 'value_3'};
    List<Map<String, dynamic>> dataList = [data1, data2, data3];
    String path = 'collection_1';

    test('Add', () {
      F.instance.destroy();
      int eventCounter = 0;
      F.instance.collection(path).snapshots().listen((event) {
        expect(event.snapshot.data, dataList[eventCounter]);
        eventCounter += 1;
      });
      F.instance.collection(path).add(data1);
      F.instance.collection(path).add(data2);
      F.instance.collection(path).add(data3);
    });

    test('GetDocuments', () async {
      F.instance.destroy();
      String? documentID;
      // Add and get new document.
      await F.instance.collection(path).add(data1).then((value) {
        documentID = value.documentID;
      });
      F.instance.collection(path).getDocuments().then((value) {
        expect(value.documentID, documentID);
      });
      // Add another document and verify update.
      await F.instance.collection(path).add(data2).then((value) {
        documentID = value.documentID;
      });
      F.instance.collection(path).getDocuments().then((value) {
        expect(value.documentID, documentID);
        expect(value.snapshot.data, data2);
      });
    });
  });

  group('DatabaseReference', () {
    test('Path', () {
      F.instance.destroy();
      // Database and event database path.
      DocumentReferenceWrapper documentReferenceWrapper = F.instance
          .database('database_1')
          .eventDatabase('event_1')
          .collection('collection_1')
          .doc('document_1');
      expect(documentReferenceWrapper.path,
          'database_1/event_1/collection_1/document_1');
      // DocumentSnapshot reference path.
      F.instance
          .database('database_1')
          .eventDatabase('event_1')
          .collection('collection_1')
          .doc('document_1')
          .get()
          .then((value) {
        expect(value.documentID, 'document_1');
        expect(
            value.reference.path, 'database_1/event_1/collection_1/document_1');
      });
      // Database document path.
      expect(
          F.instance.database('database_1').doc('collection_1/document_1').path,
          'database_1/collection_1/document_1');
      // Database collection path.
      expect(F.instance.database('database_1').collection('collection_1').path,
          'database_1/collection_1');
      // Events database default.
      expect(F.instance.eventDatabase().doc('collection_1/document_1').path,
          'default/e/collection_1/document_1');
      // Events database document path.
      expect(
          F.instance
              .eventDatabase('event_1')
              .doc('collection_1/document_1')
              .path,
          'default/event_1/collection_1/document_1');
      // Events database document path.
      expect(
          F.instance
              .database()
              .eventDatabase()
              .doc('collection_1/document_1')
              .path,
          'default/e/collection_1/document_1');
    });
  });

  group('ReferenceWrapper', () {
    test('Types', () {
      expect(F.instance.collection('collection_1'), isA<ReferenceWrapper>());
      expect(
          F.instance.doc('collection_1/document_1'), isA<ReferenceWrapper>());
      expect(F.instance.doc('collection_1/document_1').value('value_1'),
          isA<ReferenceWrapper>());
    });
  });
}
