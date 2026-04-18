import 'dart:ffi' as ffi;

import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/bus_context.dart';
import 'package:libsane/src/exceptions.dart';
import 'package:libsane/src/extensions.dart';
import 'package:libsane/src/logger.dart';
import 'package:libsane/src/structures.dart';
import 'package:simple_scan_query_bus/simple_scan_query_bus.dart';

class GetAllOptionDescriptorsQuery
    implements Query<GetAllOptionDescriptorsResponse> {
  const GetAllOptionDescriptorsQuery(this.handle);
  final SANEHandle handle;
}

class GetAllOptionDescriptorsResponse implements Response {
  const GetAllOptionDescriptorsResponse(this.optionDescriptors);
  final List<SANEOptionDescriptor> optionDescriptors;
}

class GetAllOptionDescriptorsQueryHandler extends QueryHandler<
    GetAllOptionDescriptorsQuery,
    GetAllOptionDescriptorsResponse,
    SANEBusContext> {
  const GetAllOptionDescriptorsQueryHandler(this.libsane);
  final LibSANE libsane;

  @override
  GetAllOptionDescriptorsResponse handle(
    GetAllOptionDescriptorsQuery query,
    SANEBusContext context,
  ) {
    if (!context.initialized) throw SANENotInitializedError();

    final optionDescriptors = <SANEOptionDescriptor>[];

    for (var i = 0;; i++) {
      logger.finest('sane_get_option_descriptor($i)');
      final optionDescriptorPointer = libsane.sane_get_option_descriptor(
        context.nativeHandles.get(query.handle),
        i,
      );

      if (optionDescriptorPointer == ffi.nullptr) break;
      final optionDescriptor =
          optionDescriptorPointer.ref.toSANEOptionDescriptorWithIndex(i);
      optionDescriptors.add(optionDescriptor);
      logger.finest('  -> $optionDescriptor');
    }

    return GetAllOptionDescriptorsResponse(optionDescriptors);
  }
}
