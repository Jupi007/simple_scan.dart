import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as ffi;
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class ControlValueOptionQuery<T>
    implements Query<ControlValueOptionResponse<T>> {
  const ControlValueOptionQuery(
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

class ControlValueOptionQueryHandler<T> extends QueryHandler<
    ControlValueOptionQuery<T>, ControlValueOptionResponse<T>, SANEBusContext> {
  const ControlValueOptionQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  ControlValueOptionResponse<T> handle(
    ControlValueOptionQuery query,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final nativeHandle = context.nativeHandles.get(query.handle);
    final optionDescriptor = libsane
        .sane_get_option_descriptor(nativeHandle, query.index)
        .ref
        .toSANEOptionDescriptorWithIndex(query.index);
    final optionType = optionDescriptor.type;
    final optionSize = optionDescriptor.size;

    final infoPointer = ffi.calloc<SANE_Int>();

    final valuePointer = () {
      return switch (optionType) {
        SANEOptionValueType.bool => ffi.calloc<SANE_Bool>(),
        SANEOptionValueType.int => ffi.calloc<SANE_Int>(),
        SANEOptionValueType.fixed => ffi.calloc<SANE_Word>(),
        SANEOptionValueType.string => ffi.calloc<SANE_Char>(optionSize),
        SANEOptionValueType.button => ffi.nullptr,
        SANEOptionValueType.group => throw const SANEInvalidDataException(),
      };
    }();

    if (query.action == SANEControlAction.setValue) {
      final value = query.value;
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

    late final dynamic resultValue;
    late final List<SANEOptionInfo> infos;

    try {
      logger.finest(
        'sane_control_option(${optionDescriptor.name}(${query.index}), ${query.action}, ${query.value})',
      );
      final status = libsane.sane_control_option(
        nativeHandle,
        query.index,
        query.action.toNativeSANEAction(),
        valuePointer.cast<ffi.Void>(),
        infoPointer,
      );
      logger.finest(
        '  -> ${status.name}',
      );

      status.check();

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
      infos = infoPointer.value.toSANEOptionInfoList();
      logger.finest(
        '  -> $resultValue, $infos',
      );
    } finally {
      ffi.calloc.free(valuePointer);
      ffi.calloc.free(infoPointer);
    }

    return ControlValueOptionResponse(
      SANEOptionResult(
        value: resultValue,
        infos: infos,
      ),
    );
  }
}
