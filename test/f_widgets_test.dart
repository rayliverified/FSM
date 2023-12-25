import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsm/fsm.dart';

void main() {
  group('MultiStreamBuilder', () {
    test('ReferenceType', () {
      F.instance.destroy();
      expect(F.instance.collection('collection_1').runtimeType,
          CollectionReferenceWrapper);
      expect(F.instance.doc('collection_1/document').runtimeType,
          DocumentReferenceWrapper);
      expect(
          F.instance.doc('collection_1/document').value('value_1').runtimeType,
          ValueReferenceWrapper);
    });
    testWidgets('DocumentUpdates', (WidgetTester tester) async {
      F.instance.destroy();
      int counter = 0;
      Widget widget = MaterialApp(
        home: Scaffold(
          body: FMultiStreamBuilder(
            references: [
              F.instance.doc('collection_1/document_1'),
              F.instance.doc('collection_1/document_1').value('field_1'),
            ],
            builder: (BuildContext context, Map<String, dynamic> snapshot) {
              dynamic value = F.instance
                      .doc('collection_1/document_1')
                      .value('field_1')
                      .data ??
                  'default';
              switch (counter) {
                case 0:
                  // Initial data null.
                  expect(value, 'default');
                case 1:
                  // Value setData.
                  expect(value, 'value_1');
                case 2:
                  // Document setData override.
                  expect(value, 'value_2');
              }
              counter += 1;
              return Container();
            },
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      F.instance
          .doc('collection_1/document_1')
          .value('field_1')
          .setData('value_1');
      await tester.pump();
      await tester.pump();
      F.instance.doc('collection_1/document_1').setData({'field_1': 'value_2'});
      await tester.pump();
      await tester.pump();
    });
    testWidgets('MultiDocumentUpdate', (WidgetTester tester) async {
      F.instance.destroy();
      Widget widget = MaterialApp(
        home: Scaffold(
          body: FMultiStreamBuilder(
            references: [
              F.instance.doc('collection_1/text'),
              F.instance.doc('collection_1/container'),
            ],
            builder: (BuildContext context, Map<String, dynamic> snapshot) {
              return Stack(
                children: [
                  Container(),
                  Text(F.instance.doc('collection_1/text').snapshot.data ??
                      'default'),
                  Positioned.fromRect(
                      rect: Rect.fromLTWH(
                          F.instance
                                  .doc('collection_1/container')
                                  .value('l')
                                  .data
                                  ?.toDouble() ??
                              0,
                          F.instance
                                  .doc('collection_1/container')
                                  .value('t')
                                  .data
                                  ?.toDouble() ??
                              0,
                          F.instance
                                  .doc('collection_1/container')
                                  .value('w')
                                  .data
                                  ?.toDouble() ??
                              200,
                          F.instance
                                  .doc('collection_1/container')
                                  .value('h')
                                  .data
                                  ?.toDouble() ??
                              200),
                      child: Container()),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pump();
      // Update widget values.
      F.instance
          .doc('collection_1/container')
          .setData({'l': 400, 't': 400, 'w': 400, 'h': 400});
      F.instance.doc('collection_1/text').setData('Text 1');
      await tester.pump();
      await tester.pump();
      Text textWidget = tester.firstWidget(find.byType(Text));
      Positioned positionedWidget = tester.firstWidget(find.byType(Positioned));
      expect(textWidget.data, 'Text 1');
      expect(positionedWidget.left, 400);
      expect(positionedWidget.top, 400);
      expect(positionedWidget.width, 400);
      expect(positionedWidget.height, 400);
      // Update widget values #2.
      F.instance.doc('collection_1/text').setData('Text 2');
      F.instance.doc('collection_1/container').value('l').setData(800);
      F.instance.doc('collection_1/container').value('t').setData(800);
      await tester.pump();
      await tester.pump();
      textWidget = tester.firstWidget(find.byType(Text));
      positionedWidget = tester.firstWidget(find.byType(Positioned));
      expect(textWidget.data, 'Text 2');
      expect(positionedWidget.left, 800);
      expect(positionedWidget.top, 800);
    });
  });
}
