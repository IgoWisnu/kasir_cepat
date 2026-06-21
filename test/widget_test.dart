import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cepat/core/utils/impact_animation.dart';

void main() {
  testWidgets('ScaleImpactAnimation triggers callback on tap', (WidgetTester tester) async {
    bool tapped = false;

    // Build the ScaleImpactAnimation with a text child
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ScaleImpactAnimation(
              onTap: () {
                tapped = true;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      ),
    );

    // Verify widget renders the child correctly
    expect(find.text('Tap Me'), findsOneWidget);

    // Tap on the widget
    await tester.tap(find.text('Tap Me'));
    await tester.pump();

    // Verify that the tap callback was executed
    expect(tapped, isTrue);
  });
}
