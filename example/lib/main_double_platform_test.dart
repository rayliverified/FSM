import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fsm/fsm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with FListenerStateMixin {
  @override
  void initState() {
    super.initState();
    listenF(F.instance.collection('home').doc('counter'), (data) {
      DocumentSnapshotWrapper snapshotWrapper = data;
      debugPrint('Update Listener: $data, ${snapshotWrapper.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            FStreamBuilder<double>(
              stream: F.instance.collection('home').doc('counter'),
              initialData: 0.0,
              builder: (context, value) {
                print('Value: $value');
                return Text(value.toString());
              },
            ),
            FDocumentStreamBuilder<double>(
              document: 'home/counter',
              initialData: 0.0,
              builder: (context, value) {
                return Text(value.toString());
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => F.instance
            .collection('home')
            .doc('counter')
            .setData(Random().nextDouble()),
        tooltip: 'Random',
        child: const Icon(Icons.add),
      ),
    );
  }
}
