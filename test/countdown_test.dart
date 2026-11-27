import 'package:flutter_test/flutter_test.dart';
import 'package:studygram/features/countdown/countdown_logic.dart';
void main(){
 test('expired deadline clamps to zero',()=>expect(remainingUntil(DateTime(2024),DateTime(2025)),Duration.zero));
 test('countdown formats under one day with seconds',()=>expect(countdownLabel(const Duration(hours:2,minutes:4,seconds:9)),'02h : 04m : 09s'));
 test('countdown formats days',()=>expect(countdownLabel(const Duration(days:3,hours:5,minutes:2)),'3d : 05h : 02m'));
}
