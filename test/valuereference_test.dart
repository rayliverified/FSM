import 'package:flutter_test/flutter_test.dart';
import 'package:fsm/fsm.dart';

void main() {
  group('ValueReference', () {
    String path = 'collection_1/document_1';
    test('SetData', () {
      F.instance.destroy();
      // Set top level value.
      F.instance.doc(path).value('field_1').setData('value_1');
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_1'});
      expect(F.instance.doc(path).snapshot.value('field_1'), 'value_1');
      // Set nested value.
      F.instance.destroy();
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      expect(F.instance.doc(path).snapshot.value('field_1/field_2/field_3'),
          'value_1');
      // Overwrite nested value.
      F.instance.destroy();
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_2');
      expect(F.instance.doc(path).snapshot.value('field_1/field_2/field_3'),
          'value_2');
      // Set different value type.
      F.instance.destroy();
      F.instance.doc(path).setData({'field_1': 'value_1'});
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      expect(F.instance.doc(path).snapshot.value('field_1/field_2/field_3'),
          'value_1');
      // Preserve alternate keys.
      F.instance.destroy();
      F.instance
          .doc(path)
          .setData({'field_1': 'value_1', 'field_1_1': 'value_1_1'});
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {'field_3': 'value_1'}
        },
        'field_1_1': 'value_1_1'
      });
      // Set middle value.
      F.instance.destroy();
      F.instance.doc(path).setData({
        'field_1': {
          'field_2': {
            'field_3': {'field_4': 'value_4'},
            'field_3_2': {'field_4': 'value_4_2'}
          },
          'field_2_2': {'field_3': 'value_3_2'},
          'field_2_3': 'value_2_3'
        }
      });
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {
            'field_3': 'value_1',
            'field_3_2': {'field_4': 'value_4_2'}
          },
          'field_2_2': {'field_3': 'value_3_2'},
          'field_2_3': 'value_2_3'
        }
      });
    });
    test('SetDataMerge', () {
      F.instance.destroy();
      // Set top level value.
      F.instance.doc(path).value('field_1').setData('value_1', merge: true);
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_1'});
      expect(F.instance.doc(path).snapshot.value('field_1'), 'value_1');
      // Set nested value.
      F.instance.destroy();
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData('value_1', merge: true);
      expect(F.instance.doc(path).snapshot.value('field_1/field_2/field_3'),
          'value_1');
      // Overwrite nested value.
      F.instance.destroy();
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData('value_1', merge: true);
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData('value_2', merge: true);
      expect(F.instance.doc(path).snapshot.value('field_1/field_2/field_3'),
          'value_2');
      // Merge different type.
      F.instance.destroy();
      F.instance.doc(path).setData({
        'field_1': {'field_2': 'value_1'}
      });
      F.instance.doc(path).value('field_1').setData(320, merge: true);
      expect(F.instance.doc(path).snapshot.value('field_1'), 320);
      // Preserve alternate keys.
      F.instance.destroy();
      F.instance.doc(path).setData(
          {'field_1': 'value_1', 'field_1_1': 'value_1_1'},
          merge: true);
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData('value_1', merge: true);
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {'field_3': 'value_1'}
        },
        'field_1_1': 'value_1_1'
      });
      // Merge with existing data.
      F.instance.destroy();
      F.instance.doc(path).setData({
        'field_1': {
          'field_2': {'field_3': 'value_1', 'field_3_2': 'value_2'}
        }
      }, merge: true);
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData('value_3', merge: true);
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {'field_3': 'value_3', 'field_3_2': 'value_2'}
        }
      });
      // Merge with existing data nested middle.
      F.instance.destroy();
      F.instance.doc(path).setData({
        'field_1': {
          'field_2': {
            'field_3': {'field_4': 'value_4'},
            'field_3_2': {'field_4_2': 'value_4_2'}
          }
        }
      }, merge: true);
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData({'field_4_3': 'value_4_3'}, merge: true);
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {
            'field_3': {'field_4': 'value_4', 'field_4_3': 'value_4_3'},
            'field_3_2': {'field_4_2': 'value_4_2'}
          }
        }
      });
      // Merge nested different type.
      F.instance.destroy();
      F.instance.doc(path).setData({
        'field_1': {
          'field_2': {
            'field_3': {'field_4': 'value_4'},
            'field_3_2': {'field_4_2': 'value_4_2'}
          }
        }
      }, merge: true);
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData(320, merge: true);
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {
            'field_3': 320,
            'field_3_2': {'field_4_2': 'value_4_2'}
          }
        }
      });
      // Merge complex values.
      F.instance.destroy();
      F.instance.doc(path).setData({
        'field_1': {
          'field_2': {
            'field_3': {'field_4': 'value_4'},
            'field_3_2': {'field_4_2': 'value_4_2'}
          }
        }
      }, merge: true);
      F.instance.doc(path).value('field_1').setData({
        'field_2': {
          'field_3': {'field_4': 'value_1'},
          'field_3_2': {'field_4_1': 'value_4_1', 'field_4_3': 'value_4_3'}
        },
        'field_2_2': {'field_3_2': 'value_3_2'}
      }, merge: true);
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {
            'field_3': {'field_4': 'value_1'},
            'field_3_2': {
              'field_4_1': 'value_4_1',
              'field_4_2': 'value_4_2',
              'field_4_3': 'value_4_3'
            }
          },
          'field_2_2': {'field_3_2': 'value_3_2'}
        }
      });
    });
    test('SetData Stream', () {
      // Stream SetData values..
      List<String> dataList = [
        'value_1',
        'value_2',
        'value_3',
      ];
      F.instance.destroy();
      int counter1 = 0;
      F.instance.doc(path).value('field_1').values().listen((event) {
        expect(event, dataList[counter1]);
        counter1 += 1;
      });
      F.instance.doc(path).value('field_1').setData(dataList[0]);
      F.instance.doc(path).value('field_1').setData(dataList[1]);
      F.instance.doc(path).value('field_1').setData(dataList[2]);
      // Stream UpdateData values.
      F.instance.destroy();
      int counter2 = 0;
      F.instance.doc(path).value('field_1').values().listen((event) {
        expect(event, dataList[counter2]);
        counter2 += 1;
      });
      F.instance.doc(path).value('field_1').setData(dataList[0]);
      F.instance.doc(path).value('field_1').updateData(dataList[1]);
      F.instance.doc(path).value('field_1').updateData(dataList[2]);
      // Stream duplicate values should not update.
      List<String> duplicateList = [
        'value_1',
        'value_1',
        'value_1',
      ];
      F.instance.destroy();
      // Duplicate values only update stream once.
      bool updated1 = false;
      F.instance.doc(path).value('field_1').values().listen((event) {
        expect(updated1, false);
        updated1 = true;
      });
      F.instance.doc(path).value('field_1').setData(duplicateList[0]);
      F.instance.doc(path).value('field_1').setData(duplicateList[1]);
      F.instance.doc(path).value('field_1').setData(duplicateList[2]);
      // New values updates stream after duplicate values.
      List<String> duplicateList2 = [
        'value_1',
        'value_1',
        'value_2',
      ];
      F.instance.destroy();
      // Update stream only when value is new.
      String? oldValue = '';
      F.instance.doc(path).value('field_1').values().listen((event) {
        expect(event != oldValue, true);
        oldValue = event;
      });
      F.instance.doc(path).value('field_1').setData(duplicateList2[0]);
      F.instance.doc(path).value('field_1').setData(duplicateList2[1]);
      F.instance.doc(path).value('field_1').setData(duplicateList2[2]);
      // Streams ignore other key updates.
      F.instance.destroy();
      F.instance.doc(path).value('field_1').values().listen((event) {
        throw Exception('Invalid update: $event');
      });
      F.instance.doc(path).value('field_2').setData('value_1');
      F.instance.doc(path).value('field_3').setData('value_1');
      // Stream nested value updates.
      List<String> dataList1 = [
        'value_1',
        'value_2',
        'value_3',
      ];
      F.instance.destroy();
      int counter3 = 0;
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .values()
          .listen((event) {
        expect(event, dataList[counter3]);
        counter3 += 1;
      });
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData(dataList1[0]);
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData(dataList1[1]);
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData(dataList1[2]);
    });
    test('UpdateData', () {
      // Update field does not exist.
      F.instance.destroy();
      F.instance.doc(path).value('field_1').updateData('value_1');
      expect(F.instance.doc(path).snapshot.data, null);
      // Update overwrite.
      F.instance.destroy();
      F.instance.doc(path).value('field_1').setData('value_1');
      F.instance.doc(path).value('field_1').updateData('value_2');
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_2'});
      // Update append.
      F.instance.destroy();
      F.instance.doc(path).value('field_1').setData('value_1');
      F.instance.doc(path).value('field_2').updateData('value_2');
      expect(F.instance.doc(path).snapshot.data, {'field_1': 'value_1'});
      // Update overlap.
      F.instance.destroy();
      F.instance
          .doc(path)
          .value('field_1')
          .setData({'field_1_1': 'value_1', 'field_1_2': 'value_2'});
      F.instance
          .doc(path)
          .value('field_1')
          .updateData({'field_1_2': 'value_2_1', 'field_1_3': 'value_3'});
      expect(F.instance.doc(path).snapshot.value('field_1'), {
        'field_1_1': 'value_1',
        'field_1_2': 'value_2_1',
        'field_1_3': 'value_3'
      });
      // Update dynamic data.
      F.instance.destroy();
      F.instance.doc(path).value('field_1').setData('value_1');
      F.instance.doc(path).value('field_1').updateData(320);
      expect(F.instance.doc(path).snapshot.value('field_1'), 320);
      // Update nested value does not exist.
      F.instance.destroy();
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .updateData('value_1');
      expect(
          F.instance.doc(path).snapshot.value('field_1/field_2/field_3'), null);
      // Update nested value.
      F.instance.destroy();
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .updateData('value_2');
      expect(F.instance.doc(path).snapshot.value('field_1/field_2/field_3'),
          'value_2');
      // Update nested value merge.
      F.instance.destroy();
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData({'field_1': 'value_1', 'field_2': 'value_2'});
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .updateData({'field_2': 'value_2_2', 'field_3': 'value_3'});
      expect(F.instance.doc(path).snapshot.value('field_1/field_2/field_3'),
          {'field_1': 'value_1', 'field_2': 'value_2_2', 'field_3': 'value_3'});
      // Update nested value overwrite.
      F.instance.destroy();
      F.instance
          .doc(path)
          .value('field_1/field_2/field_3')
          .setData({'field_1': 'value_1'});
      F.instance.doc(path).value('field_1/field_2/field_3').updateData(320);
      expect(
          F.instance.doc(path).snapshot.value('field_1/field_2/field_3'), 320);
      // Update middle value.
      F.instance.destroy();
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      F.instance
          .doc(path)
          .value('field_1')
          .updateData({'field_2_2': 'value_2'});
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {'field_3': 'value_1'},
          'field_2_2': 'value_2'
        }
      });
      // Overwrite middle value.
      F.instance.destroy();
      F.instance.doc(path).value('field_1/field_2/field_3').setData('value_1');
      F.instance.doc(path).value('field_1').updateData({
        'field_2': {'field_3': 'value_1_1'},
        'field_2_2': 'value_2'
      });
      expect(F.instance.doc(path).snapshot.data, {
        'field_1': {
          'field_2': {'field_3': 'value_1_1'},
          'field_2_2': 'value_2'
        }
      });
    });
    test('GetData', () {
      // Get null.
      expect(
          F.instance
              .collection('collection_1')
              .doc('document_1')
              .value('value_1')
              .data,
          null);
    });
    test('Temporary', () {
      // Stream duplicate values should not update.
      List<String> duplicateList = [
        'value_1',
        'value_1',
        'value_1',
      ];
      F.instance.destroy();
      bool updated1 = false;
      F.instance.doc(path).value('field_1').values().listen((event) {
        // print('Updated');
        expect(updated1, false);
        updated1 = true;
      });
      F.instance.doc(path).value('field_1').setData(duplicateList[0]);
      F.instance.doc(path).value('field_1').setData(duplicateList[1]);
      F.instance.doc(path).value('field_1').setData(duplicateList[2]);
    });
  });
}
