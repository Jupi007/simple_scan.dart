import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/sane_bus_context.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class GetOptionDescriptorQuery implements Query<GetOptionDescriptorResponse> {
  const GetOptionDescriptorQuery(this.handle, this.index);
  final SANEHandle handle;
  final int index;
}

class GetOptionDescriptorResponse implements Response {
  const GetOptionDescriptorResponse(this.optionDescriptor);
  final SANEOptionDescriptor? optionDescriptor;
}

class GetOptionDescriptorQueryHandler extends QueryHandler<
    GetOptionDescriptorQuery, GetOptionDescriptorResponse, SANEBusContext> {
  const GetOptionDescriptorQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  GetOptionDescriptorResponse handle(
    GetOptionDescriptorQuery query,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final optionDescriptorPointer = libsane.sane_get_option_descriptor(
      context.nativeHandles.get(query.handle),
      query.index,
    );
    logger.finest('sane_get_option_descriptor(${query.index})');

    if (optionDescriptorPointer == ffi.nullptr) {
      return const GetOptionDescriptorResponse(null);
    }

    final optionDescriptor = optionDescriptorPointer.ref
        .toSANEOptionDescriptorWithIndex(query.index);
    logger.finest('  -> $optionDescriptor');

    return GetOptionDescriptorResponse(optionDescriptor);
  }
}
