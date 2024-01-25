import 'package:flutter_test/flutter_test.dart';
import 'package:fsm/fsm.dart';

void main() {
  group('DocumentReference', () {
    Map<String, dynamic> data1 = {'field_1': 'value_1'};
    Map<String, dynamic> data2 = {'field_1': 'value_2'};
    Map<String, dynamic> data3 = {'field_1': 'value_3'};
    List<Map<String, dynamic>> dataList = [data1, data2, data3];
    String path = 'collection_1/document_1';

    test('SetData', () {
      F.instance.destroy();
      F.instance.doc(path).setData(data1);
      // Access value directly.
      expect(F.instance.doc(path).snapshot.data, data1);
      // Access value from future.
      F.instance.doc(path).get().then((value) => expect(value.data, data1));
    });

    test('SetData Stream', () {
      F.instance.destroy();
      int eventCounter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        expect(event.data, dataList[eventCounter]);
        eventCounter += 1;
      });
      F.instance.doc(path).setData(data1);
      F.instance.doc(path).setData(data2);
      F.instance.doc(path).setData(data3);
    });

    test('Path', () {
      F.instance.destroy();
      // Document path.
      expect(F.instance.doc(path).path, 'default/$path');
      // Document id.
      expect(F.instance.doc(path).documentID, 'document_1');
      // Collection path.
      expect(F.instance.doc(path).parent().id, 'collection_1');
      // Document path.
      expect(F.instance.collection('collection_1').doc('document_1').path,
          'default/collection_1/document_1');
      // Nested document path.
      expect(
          F.instance
              .collection('collection_1')
              .doc('document_1')
              .collection('collection_2')
              .doc('document_2')
              .collection('collection_3')
              .doc('document_3')
              .path,
          'default/'
          'collection_1/document_1/collection_2/document_2/collection_3/document_3');
      // Nested document id;
      expect(
          F.instance
              .collection('collection_1')
              .doc('document_1')
              .collection('collection_2')
              .doc('document_2')
              .collection('collection_3')
              .doc('document_3')
              .documentID,
          'document_3');
      // Nested parent id.
      expect(
          F.instance
              .collection('collection_1')
              .doc('document_1')
              .collection('collection_2')
              .doc('document_2')
              .collection('collection_3')
              .doc('document_3')
              .parent()
              .id,
          'collection_3');
      // New document reference from parent().
      expect(
          F.instance
              .collection('collection_1')
              .doc('document_1')
              .collection('collection_2')
              .doc('document_2')
              .collection('collection_3')
              .doc('document_3')
              .parent()
              .doc('document_3_1')
              .documentID,
          'document_3_1');
      // Chained parent() calls to move up the document tree.
      expect(
          F.instance
              .collection('collection_1')
              .doc('document_1')
              .collection('collection_2')
              .doc('document_2')
              .collection('collection_3')
              .doc('document_3')
              .parent()
              .parent()!
              .parent()
              .parent()!
              .documentID,
          'document_1');
      // Invalid document reference. Odd path.
      try {
        expect(F.instance.doc('document_1').path, throwsA(AssertionError));
      } catch (e) {
        print(e);
      }
    });
    test('UpdateData', () {
      F.instance.destroy();
      // Update field does not exist.
      F.instance.doc(path).updateData(data1);
      expect(F.instance.doc(path).snapshot.data, null);
      // Update overwrite.
      F.instance.doc(path).setData(data1);
      F.instance.doc(path).updateData(data2);
      expect(F.instance.doc(path).snapshot.data, data2);
      // Update append.
      F.instance.doc(path).setData({'field_1': 'value_1'});
      F.instance.doc(path).updateData({'field_2': 'value_2'});
      expect(F.instance.doc(path).snapshot.data,
          {'field_1': 'value_1', 'field_2': 'value_2'});
      // Update overlap.
      F.instance
          .doc(path)
          .setData({'field_1': 'value_1', 'field_2': 'value_2'});
      F.instance
          .doc(path)
          .updateData({'field_2': 'value_2_1', 'field_3': 'value_3'});
      expect(F.instance.doc(path).snapshot.data,
          {'field_1': 'value_1', 'field_2': 'value_2_1', 'field_3': 'value_3'});
      // Update dynamic data.
      F.instance.doc(path).setData('value_1');
      F.instance.doc(path).updateData('value_2');
      expect(F.instance.doc(path).snapshot.data, 'value_2');
    });
    test('MergeData', () {
      // Merge nonexistant.
      F.instance.destroy();
      F.instance.doc(path).setData(data1, merge: true);
      expect(F.instance.doc(path).snapshot.data, data1);
      // Merge null.
      F.instance.destroy();
      F.instance.doc(path).setData(data1);
      F.instance.doc(path).setData({'field_2': null}, merge: true);
      expect(F.instance.doc(path).snapshot.data,
          {'field_1': 'value_1', 'field_2': null});
      F.instance.doc(path).setData(null, merge: true);
      expect(F.instance.doc(path).snapshot.data, null);
      // Merge existing duplicate.
      F.instance.destroy();
      F.instance.doc(path).setData(data1);
      F.instance.doc(path).setData(data2, merge: true);
      expect(F.instance.doc(path).snapshot.data, data2);
      // Merge add all.
      F.instance.destroy();
      Map<String, dynamic> originalData = {'field_1': 'value_1'};
      Map<String, dynamic> mergeData = {'field_2': 'value_2'};
      F.instance.doc(path).setData(originalData);
      F.instance.doc(path).setData(mergeData, merge: true);
      originalData.addAll(mergeData);
      expect(F.instance.doc(path).snapshot.data, originalData);
      // Merge overlap.
      F.instance.destroy();
      F.instance
          .doc(path)
          .setData({'field_1': 'value_1', 'field_2': 'value_2'});
      F.instance
          .doc(path)
          .setData({'field_2': 'value_2_1', 'field_3': 'value_3'}, merge: true);
      expect(F.instance.doc(path).snapshot.data,
          {'field_1': 'value_1', 'field_2': 'value_2_1', 'field_3': 'value_3'});
      // Merge dynamic data.
      F.instance.destroy();
      F.instance.doc(path).setData('value_1');
      F.instance.doc(path).setData('value_2', merge: true);
      expect(F.instance.doc(path).snapshot.data, 'value_2');
    });
    test('DynamicData', () async {
      // Set String value.
      F.instance.destroy();
      F.instance.doc(path).setData('value_1');
      expect(F.instance.doc(path).snapshot.data, 'value_1');
      // Set class value.
      F.instance.destroy();
      FTimestamp now = FTimestamp.now();
      F.instance.doc(path).setData(now);
      expect(F.instance.doc(path).snapshot.data, now);
      // Update dynamic value.
      F.instance.destroy();
      now = FTimestamp.now();
      F.instance.doc(path).setData(now);
      await Future.delayed(const Duration(milliseconds: 100), () {});
      FTimestamp now2 = FTimestamp.now();
      F.instance.doc(path).updateData(now2);
      expect(F.instance.doc(path).snapshot.data, now2);
      // Update different types.
      F.instance.destroy();
      F.instance.doc(path).setData('value_1');
      F.instance.doc(path).updateData(320);
      expect(F.instance.doc(path).snapshot.data, 320);
      // Merge different types.
      F.instance.destroy();
      F.instance.doc(path).setData('value_1');
      F.instance.doc(path).setData(320, merge: true);
      expect(F.instance.doc(path).snapshot.data, 320);
      // Update dynamic and map.
      F.instance.destroy();
      F.instance.doc(path).setData('value_1');
      F.instance.doc(path).updateData({'field_1': 'value_1'});
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_1'});
      F.instance.doc(path).updateData({'field_1': 'value_1_1'});
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_1_1'});
      // Merge dynamic and map.
      F.instance.destroy();
      F.instance.doc(path).setData('value_1');
      F.instance.doc(path).setData({'field_1': 'value_1'}, merge: true);
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_1'});
      F.instance.doc(path).setData({'field_1': 'value_1_1'}, merge: true);
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_1_1'});
    });
    test('SnapshotNull', () async {
      F.instance.destroy();
      expect(F.instance.doc(path).snapshot.data, null);
      // Initialize null stream.
      F.instance.destroy();
      F.instance.doc(path).snapshots();
      expect(F.instance.doc(path).snapshot.data, null);
      // Null stream update.
      int counter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        switch (counter) {
          case 0:
            expect(event.data, data1);
          case 1:
            expect(event.data, null);
          case 2:
            throw Exception('Duplicate Value');
        }
        counter += 1;
      });
      F.instance.doc(path).setData(data1);
      F.instance.doc(path).setData(null);
      // Duplicate value is skipped.
      F.instance.doc(path).setData(null);
    });
    test('SetData Duplicate Map Notification Behavior', () async {
      F.instance.destroy();
      int counter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        switch (counter) {
          case 0:
            expect(event.data, data1);
          case 1:
            expect(event.data, data1);
          case 2:
            expect(event.data, data1);
          case 3:
            expect(event.data, {
              ...data1,
              ...{'field_2': 'value_1'},
            });
          default:
            break;
        }
        counter += 1;
      });

      // Setting the same variable, even though the variable
      // is a Map, is treated as equality.
      F.instance.doc(path).setData(data1);
      // Duplicate call should be ignored.
      F.instance.doc(path).setData(data1);
      // Merge call ignored because duplicate.
      F.instance.doc(path).setData(data1, merge: true);

      // Setting a new Map which is not treated as equal to the old Map will notify.
      F.instance.doc(path).setData({'field_1': 'value_1'});
      F.instance.doc(path).setData({'field_1': 'value_1'}, merge: true);
      F.instance.doc(path).setData({'field_2': 'value_1'}, merge: true);
    });

    test('SetData Merge No Notification Behavior', () async {
      F.instance.destroy();
      int counter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        switch (counter) {
          case 0:
            expect(event.data, 'Test');
          case 1:
            expect(event.data, null);
          default:
            break;
        }
        counter += 1;
      });

      F.instance.doc(path).setData('Test');
      F.instance.doc(path).setData('Test');
      F.instance.doc(path).setData('Test', merge: true);
    });

    test('SetData Notify Behavior', () async {
      F.instance.destroy();
      int counter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        switch (counter) {
          case 0:
            expect(event.data, 'Test');
          case 1:
            expect(event.data, 'Test');
          case 2:
            expect(event.data, 'Test 1');
          case 3:
            expect(event.data, 'Test 1');
          default:
            break;
        }
        counter += 1;
      });

      F.instance.doc(path).setData('Test');
      F.instance.doc(path).setData('Test', notify: true);
      F.instance.doc(path).setData('Test 1', merge: true);
      F.instance.doc(path).setData('Test 1', merge: true, notify: true);
    });

    test('UpdateData No Value Update', () async {
      F.instance.destroy();
      F.instance.doc(path).snapshots().listen((event) {
        expect(event.data, null);
      });

      F.instance.doc(path).updateData('Test');
      F.instance.doc(path).updateData('Test');
      F.instance.doc(path).updateData('Test');
    });

    test('UpdateData No Notification Behavior', () async {
      F.instance.destroy();
      int counter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        switch (counter) {
          case 0:
            expect(event.data, 'Test');
          case 1:
            expect(event.data, null);
          default:
            break;
        }
        counter += 1;
      });

      F.instance.doc(path).setData('Test');
      F.instance.doc(path).updateData('Test');
      F.instance.doc(path).updateData('Test');
    });

    test('UpdateData Notify Behavior', () async {
      F.instance.destroy();
      int counter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        switch (counter) {
          case 0:
            expect(event.data, 'Test');
          case 1:
            expect(event.data, 'Test');
          case 2:
            expect(event.data, 'Test 1');
          case 3:
            expect(event.data, 'Test 1');
          default:
            break;
        }
        counter += 1;
      });

      F.instance.doc(path).setData('Test');
      F.instance.doc(path).updateData('Test', notify: true);
      F.instance.doc(path).updateData('Test 1');
      F.instance.doc(path).setData('Test 1', notify: true);
    });

    test('Equality Test - Double', () async {
      F.instance.destroy();
      int counter = 0;
      F.instance.doc(path).snapshots().listen((event) {
        switch (counter) {
          case 0:
            expect(event.data, 5.0);
            expect(event.data, 5);
          case 1:
            expect(event.data, 5.0);
            expect(event.data, 5);
          case 2:
            expect(event.data, 10.0);
          case 3:
            expect(event.data, 'Should not be called.');
          default:
            break;
        }
        counter += 1;
      });

      F.instance.doc(path).setData(5.0);
      // Force update.
      F.instance.doc(path).updateData(5.0, notify: true);
      // Update naturally because values are different.
      F.instance.doc(path).setData(10.0);
      // Update integer instead of double.
      F.instance.doc(path).setData(10);
    });
  });
}
