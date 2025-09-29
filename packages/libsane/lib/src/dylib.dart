import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';

LibSANE? _dylib;
LibSANE get dylib {
  return _dylib ??= LibSANE(ffi.DynamicLibrary.open('libsane.so'));
}
