import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:mocktail/mocktail.dart';

class MockLibSANE extends Mock implements LibSANE {}

void setUpMockLibSANE() {
  registerFallbackValue(ffi.Pointer<ffi.Int>.fromAddress(0));
  registerFallbackValue(SANE_Auth_Callback.fromAddress(0));
  registerFallbackValue(SANE_Action.fromValue(0));
}
