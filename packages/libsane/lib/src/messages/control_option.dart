import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus/message_bus.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';

class ControlValueOptionMessage<T>
    implements Message<ControlValueOptionResponse<T>> {
  const ControlValueOptionMessage(
    this.handle,
    this.index,
    this.action,
    this.value,
  );

  final SANEHandle handle;
  final int index;
  final SANEControlAction action;
  final T? value;
}

class ControlValueOptionResponse<T> implements Response {
  const ControlValueOptionResponse(this.optionResult);
  final SANEOptionResult<T> optionResult;
}

class ControlValueOptionMessageHandler<T> extends MessageHandler<
    ControlValueOptionMessage<T>,
    ControlValueOptionResponse<T>,
    SANEBusContext> {
  const ControlValueOptionMessageHandler(this.libsane);
  final LibSANE libsane;

  @override
  ControlValueOptionResponse<T> handle(
    ControlValueOptionMessage message,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final nativeHandle = context.nativeHandles.get(message.handle);
    final optionDescriptor = libsane
        .sane_get_option_descriptor(nativeHandle, message.index)
        .ref
        .toSANEOptionDescriptorWithIndex(message.index);
    final optionType = optionDescriptor.type;
    final optionSize = optionDescriptor.size;

    final infoPointer = ffi.calloc<SANE_Int>();

    final valuePointer = () {
      return switch (optionType) {
        SANEOptionValueType.bool => ffi.calloc<SANE_Bool>(optionSize),
        SANEOptionValueType.int => ffi.calloc<SANE_Int>(optionSize),
        SANEOptionValueType.fixed => ffi.calloc<SANE_Word>(optionSize),
        SANEOptionValueType.string => ffi.calloc<SANE_Char>(optionSize),
        SANEOptionValueType.button => ffi.nullptr,
        SANEOptionValueType.group => throw const SANEInvalidDataException(),
      };
    }();

    if (message.action == SANEControlAction.setValue) {
      final value = message.value;
      switch (optionType) {
        case SANEOptionValueType.bool when value is bool:
          (valuePointer as ffi.Pointer<SANE_Bool>).value = value.toSANEBool();
          break;
        case SANEOptionValueType.int when value is int:
          (valuePointer as ffi.Pointer<SANE_Int>).value = value;
          break;
        case SANEOptionValueType.fixed when value is double:
          (valuePointer as ffi.Pointer<SANE_Word>).value = value.toSANEFixed();
          break;
        case SANEOptionValueType.string when value is String:
          (valuePointer as ffi.Pointer<SANE_Char>)
              .copyStringBytes(value, maxLenght: optionSize);
          break;
        case SANEOptionValueType.button:
          break;
        case SANEOptionValueType.group:
        default:
          throw const SANEInvalidDataException();
      }
    }

    final status = libsane.sane_control_option(
      nativeHandle,
      message.index,
      message.action.toNativeSANEAction(),
      valuePointer.cast<ffi.Void>(),
      infoPointer,
    );
    logger.finest(
      'sane_control_option(${optionDescriptor.name}(${message.index}), ${message.action}, ${message.value}) -> ${status.name}',
    );

    status.check();

    final infos = infoPointer.value.toSANEOptionInfoList();
    late final dynamic resultValue;
    switch (optionType) {
      case SANEOptionValueType.bool:
        resultValue =
            (valuePointer as ffi.Pointer<SANE_Bool>).value.toDartBool();

      case SANEOptionValueType.int:
        resultValue = (valuePointer as ffi.Pointer<SANE_Int>).value;

      case SANEOptionValueType.fixed:
        resultValue =
            (valuePointer as ffi.Pointer<SANE_Word>).value.toDartDouble();

      case SANEOptionValueType.string:
        resultValue = (valuePointer as ffi.Pointer<SANE_Char>).toDartString();

      case SANEOptionValueType.button:
        resultValue = null;

      default:
        throw const SANEInvalidDataException();
    }
    logger.finest(
      '  -> $resultValue, $infos',
    );

    ffi.calloc.free(valuePointer);
    ffi.calloc.free(infoPointer);

    return ControlValueOptionResponse(
      SANEOptionResult(
        value: resultValue,
        infos: infos,
      ),
    );
  }
}
