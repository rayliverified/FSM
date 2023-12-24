//import 'package:flutter/material.dart';
//
//part 'f_prototype.g.dart';
//
//class FSMPrototype extends FSMObserver {
//  @FReference('elements/{widget.id}/properties', 'x', 'widget.id')
//  double positionX;
//  @FReference('elements/{widget.id}/properties', 'x', 'widget.id')
//  double positionY;
//  @FReference('elements/{widget.id}/properties', 'w', 'widget.id')
//  double width;
//  @FReference('elements/{widget.id}/properties', 'h', 'widget.id')
//  double height;
//
//  @override
//  Widget build(BuildContext context) {
//    return Stack(
//      children: [
//        Positioned(
//          left: positionX,
//          right: positionY,
//          child: Container(
//            width: width,
//            height: height,
//          ),
//        ),
//      ],
//    );
//  }
//}

// 1. Run build runner for generated files.
// 2. Create FSM generated file that connects annotated variables to ValueNotifiers.
// 3. Observe variable value changes and update database.
//https://medium.com/flutter-community/part-2-code-generation-in-dart-annotations-source-gen-and-build-runner-bbceee28697b
//https://developpaper.com/flutter-series-4-annotation-based-code-generation-applications/
