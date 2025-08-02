import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockLibSane extends Mock implements LibSane {}

void setUpMockLibSane() {
  registerFallbackValue(ffi.Pointer<ffi.Int>.fromAddress(0));
  registerFallbackValue(SANE_Auth_Callback.fromAddress(0));
  registerFallbackValue(SANE_Action.fromValue(0));
}
