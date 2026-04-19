import 'package:ffi/ffi.dart';
import 'package:libsane/src/bindings.g.dart';
import 'package:libsane/src/dylib.dart';

/// Base class for all possible errors that can occur in the SANE library.
///
/// See also:
///
/// - [SANEEOFException]
/// - [SANEJammedException]
/// - [SANEDeviceBusyException]
/// - [SANEInvalidDataException]
/// - [SANEIoException]
/// - [SANENoDocumentsException]
/// - [SANECoverOpenException]
/// - [SANEUnsupportedException]
/// - [SANECancelledException]
/// - [SANENoMemoryException]
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
sealed class SANEException implements Exception {
  factory SANEException(SANE_Status status) {
    final exception = switch (status) {
      SANE_Status.STATUS_GOOD => throw ArgumentError(
          'Cannot create SANEException with status STATUS_GOOD',
          'status',
        ),
      SANE_Status.STATUS_UNSUPPORTED => const SANEUnsupportedException(),
      SANE_Status.STATUS_CANCELLED => const SANECancelledException(),
      SANE_Status.STATUS_DEVICE_BUSY => const SANEDeviceBusyException(),
      SANE_Status.STATUS_INVAL => const SANEInvalidDataException(),
      SANE_Status.STATUS_EOF => const SANEEOFException(),
      SANE_Status.STATUS_JAMMED => const SANEJammedException(),
      SANE_Status.STATUS_NO_DOCS => const SANENoDocumentsException(),
      SANE_Status.STATUS_COVER_OPEN => const SANECoverOpenException(),
      SANE_Status.STATUS_IO_ERROR => const SANEIoException(),
      SANE_Status.STATUS_NO_MEM => const SANENoMemoryException(),
      SANE_Status.STATUS_ACCESS_DENIED => const SANEAccessDeniedException(),
    };

    assert(exception._status == status);

    return exception;
  }

  const SANEException._();
  SANE_Status get _status;

  String get query {
    return dylib.sane_strstatus(_status).cast<Utf8>().toDartString();
  }

  @override
  String toString() {
    return '$runtimeType: $query';
  }
}

/// No more data available.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANEEOFException extends SANEException {
  const SANEEOFException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_EOF;
}

/// The document feeder is jammed.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANEJammedException extends SANEException {
  const SANEJammedException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_JAMMED;
}

/// The document feeder is out of documents.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANENoDocumentsException extends SANEException {
  const SANENoDocumentsException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_NO_DOCS;
}

/// The scanner cover is open.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANECoverOpenException extends SANEException {
  const SANECoverOpenException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_COVER_OPEN;
}

/// The device is busy.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANEDeviceBusyException extends SANEException {
  const SANEDeviceBusyException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_DEVICE_BUSY;
}

/// Data is invalid.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANEInvalidDataException extends SANEException {
  const SANEInvalidDataException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_INVAL;
}

/// Error during device I/O.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANEIoException extends SANEException {
  const SANEIoException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_IO_ERROR;
}

/// Out of memory.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANENoMemoryException extends SANEException {
  const SANENoMemoryException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_NO_MEM;
}

/// Access to resource has been denied.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANEAccessDeniedException extends SANEException {
  const SANEAccessDeniedException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_ACCESS_DENIED;
}

/// Operation was cancelled.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANECancelledException extends SANEException {
  const SANECancelledException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_CANCELLED;
}

/// Operation is not supported.
///
/// See also:
///
/// - <https://sane-project.gitlab.io/standard/api.html#tab-status>
final class SANEUnsupportedException extends SANEException {
  const SANEUnsupportedException() : super._();

  @override
  SANE_Status get _status => SANE_Status.STATUS_UNSUPPORTED;
}

abstract interface class SANEError extends Error {}

/// SANE has been exited
final class SANENotInitializedError extends StateError implements SANEError {
  SANENotInitializedError()
      : super('SANE isn\'t initialized, please call init().');
}

/// SANE is already initialized
final class SANEAlreadyInitializedError extends StateError
    implements SANEError {
  SANEAlreadyInitializedError() : super('SANE is already initialized.');
}

/// SANE is already initialized
final class SANEHandleClosedError extends StateError implements SANEError {
  SANEHandleClosedError(this.deviceName)
      : super(
          'This handle is closed, you should recall open() with "$deviceName".',
        );
  final String deviceName;
}
