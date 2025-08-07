import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/isolate/context.dart';
import 'package:libsane/src/isolate/isolate.dart';
import 'package:libsane/src/isolate/logger.dart';
import 'package:libsane/src/structures.dart';

class ControlValueOptionMessage<T>
    implements IsolateMessage<ControlValueOptionResponse<T>> {
  const ControlValueOptionMessage(
    this.handle,
    this.index,
    this.action,
    this.value,
  );

  final SaneHandle handle;
  final int index;
  final SaneControlAction action;
  final T? value;
}

class ControlValueOptionResponse<T> implements IsolateResponse {
  const ControlValueOptionResponse(this.optionResult);
  final SaneOptionResult<T> optionResult;
}

class ControlValueOptionMessageHandler<T>
    implements
        IsolateMessageHandler<ControlValueOptionMessage<T>,
            ControlValueOptionResponse<T>> {
  const ControlValueOptionMessageHandler(this.libSane);
  final LibSane libSane;

  @override
  ControlValueOptionResponse<T> handle(
    ControlValueOptionMessage message,
    SaneIsolateContext context,
  ) {
    if (!context.initialized) throw SaneNotInitializedError();

    final nativeHandle = context.nativeHandles.get(message.handle);
    final optionDescriptor = libSane
        .sane_get_option_descriptor(nativeHandle, message.index)
        .ref
        .toSaneOptionDescriptorWithIndex(message.index);
    final optionType = optionDescriptor.type;
    final optionSize = optionDescriptor.size;

    final infoPointer = ffi.calloc<SANE_Int>();

    final valuePointer = () {
      return switch (optionType) {
        SaneOptionValueType.bool => ffi.calloc<SANE_Bool>(optionSize),
        SaneOptionValueType.int => ffi.calloc<SANE_Int>(optionSize),
        SaneOptionValueType.fixed => ffi.calloc<SANE_Word>(optionSize),
        SaneOptionValueType.string => ffi.calloc<SANE_Char>(optionSize),
        SaneOptionValueType.button => ffi.nullptr,
        SaneOptionValueType.group => throw const SaneInvalidDataException(),
      };
    }();

    if (message.action == SaneControlAction.setValue) {
      final value = message.value;
      switch (optionType) {
        case SaneOptionValueType.bool when value is bool:
          (valuePointer as ffi.Pointer<SANE_Bool>).value = value.toSaneBool();
          break;
        case SaneOptionValueType.int when value is int:
          (valuePointer as ffi.Pointer<SANE_Int>).value = value;
          break;
        case SaneOptionValueType.fixed when value is double:
          (valuePointer as ffi.Pointer<SANE_Word>).value = value.toSaneFixed();
          break;
        case SaneOptionValueType.string when value is String:
          (valuePointer as ffi.Pointer<SANE_Char>)
              .copyStringBytes(value, maxLenght: optionSize);
          break;
        case SaneOptionValueType.button:
          break;
        case SaneOptionValueType.group:
        default:
          throw const SaneInvalidDataException();
      }
    }

    final status = libSane.sane_control_option(
      nativeHandle,
      message.index,
      message.action.toNativeSaneAction(),
      valuePointer.cast<ffi.Void>(),
      infoPointer,
    );
    isolateLogger.finest(
      'sane_control_option(${optionDescriptor.name}(${message.index}), ${message.action}, ${message.value}) -> ${status.name}',
    );

    status.check();

    final infos = infoPointer.value.toSaneOptionInfoList();
    late final dynamic resultValue;
    switch (optionType) {
      case SaneOptionValueType.bool:
        resultValue =
            (valuePointer as ffi.Pointer<SANE_Bool>).value.toDartBool();

      case SaneOptionValueType.int:
        resultValue = (valuePointer as ffi.Pointer<SANE_Int>).value;

      case SaneOptionValueType.fixed:
        resultValue =
            (valuePointer as ffi.Pointer<SANE_Word>).value.toDartDouble();

      case SaneOptionValueType.string:
        resultValue = (valuePointer as ffi.Pointer<SANE_Char>).toDartString();

      case SaneOptionValueType.button:
        resultValue = null;

      default:
        throw const SaneInvalidDataException();
    }
    isolateLogger.finest(
      '  -> $resultValue, $infos',
    );

    ffi.calloc.free(valuePointer);
    ffi.calloc.free(infoPointer);

    return ControlValueOptionResponse(
      SaneOptionResult(
        value: resultValue,
        infos: infos,
      ),
    );
  }
}
