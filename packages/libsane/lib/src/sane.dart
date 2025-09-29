import 'dart:async';
import 'dart:typed_data';

import 'package:libsane/src/isolated_sane.dart';
import 'package:libsane/src/structures.dart';
import 'package:libsane/src/sync_sane.dart';

typedef AuthCallback = SANECredentials Function(String resourceName);

abstract interface class SANE {
  /// Returns a singleton instance of [SANE] that runs in the same isolate
  /// as the caller.
  ///
  /// Note: [SANE.sync] and [SANE.isolated] both return the same singleton.
  /// The first one you call decides the mode for the entire application.
  factory SANE.sync() => _instance ??= SyncSANE();

  /// Returns a singleton instance of [SANE] that runs in a separate isolate
  /// for background processing.
  ///
  /// Note: [SANE.sync] and [SANE.isolated] both return the same singleton.
  /// The first one you call decides the mode for the entire application.
  factory SANE.isolated() => _instance ??= IsolatedSANE();

  static SANE? _instance;

  /// Initializes the SANE library.
  ///
  /// This function must be called before any other SANE function can be called.
  ///
  /// The authorization function may be called by a backend in response to any
  /// of the following calls: [open], [controlOption], [start].
  ///
  /// See also:
  ///
  /// - [`sane_open`](https://sane-project.gitlab.io/standard/api.html#sane-open)
  FutureOr<SANEVersion> init({AuthCallback? authCallback});

  /// Disposes the SANE instance.
  ///
  /// Closes all device handles and all future calls are invalid.
  ///
  /// See also:
  ///
  /// - [`sane_exit`](https://sane-project.gitlab.io/standard/api.html#sane-exit)
  FutureOr<void> exit();

  /// Queries the list of devices that are available.
  ///
  /// This method can be called repeatedly to detect when new devices become
  /// available. If argument [localOnly] is true, only local devices are
  /// returned (devices directly attached to the machine that SANE is running
  /// on). If it is `false`, the device list includes all remote devices that
  /// are accessible to the SANE library.
  ///
  /// See also:
  ///
  /// - [`sane_get_devices`](https://sane-project.gitlab.io/standard/api.html#sane-get-devices)
  FutureOr<List<SANEDevice>> getDevices({bool localOnly = true});

  /// Establish a connection to a particular device.
  ///
  /// If the call completes successfully, a handle for the device is returned.
  ///
  /// Exceptions:
  ///
  /// - Throws [SANEDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SANEInvalidDataException] if the device nameis not valid.
  /// - Throws [SANEIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SANENoMemoryException] if no memory is available.
  /// - Throws [SANEAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_open`](https://sane-project.gitlab.io/standard/api.html#sane-open)
  FutureOr<SANEHandle> open(String name);

  /// Shortcut for [open] with a [SANEDevice]
  FutureOr<SANEHandle> openDevice(SANEDevice device) {
    return open(device.name);
  }

  /// Disposes the SANE device. Infers [cancel].
  ///
  /// See also:
  ///
  /// - [`sane_close`](https://sane-project.gitlab.io/standard/api.html#sane-close)
  FutureOr<void> close(SANEHandle handle);

  FutureOr<SANEOptionDescriptor?> getOptionDescriptor(
    SANEHandle handle,
    int index,
  );

  FutureOr<List<SANEOptionDescriptor>> getAllOptionDescriptors(
    SANEHandle handle,
  );

  FutureOr<SANEOptionResult<bool>> controlBoolOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    bool? value,
  });

  FutureOr<SANEOptionResult<int>> controlIntOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    int? value,
  });

  FutureOr<SANEOptionResult<double>> controlFixedOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    double? value,
  });

  FutureOr<SANEOptionResult<String>> controlStringOption({
    required SANEHandle handle,
    required int index,
    required SANEControlAction action,
    String? value,
  });

  FutureOr<SANEOptionResult<Null>> controlButtonOption({
    required SANEHandle handle,
    required int index,
  });

  /// Obtain the current scan parameters.
  ///
  /// The returned parameters are guaranteed to be accurate between the time
  /// a scan has been started.
  ///
  /// See also:
  ///
  /// - [`sane_get_parameters`](https://sane-project.gitlab.io/standard/api.html#sane-get-parameters)
  FutureOr<SANEParameters> getParameters(SANEHandle handle);

  /// Initiates acquisition of an image from the device.
  ///
  /// Exceptions:
  ///
  /// - Throws [SANECancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SANEDeviceBusyException] if the device is busy. The operation
  ///   should be later again.
  /// - Throws [SANEJammedException] if the document feeder is jammed.
  /// - Throws [SANENoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SANECoverOpenException] if the scanner cover is open.
  /// - Throws [SANEIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SANENoMemoryException] if no memory is available.
  /// - Throws [SANEInvalidDataException] if the sane cannot be started with the
  ///   current set of options. The frontend should reload the option
  ///   descriptors.
  ///
  /// See also:
  ///
  /// - [`sane_start`](https://sane-project.gitlab.io/standard/api.html#sane-start)
  FutureOr<void> start(SANEHandle handle);

  /// Reads image data from the device.
  ///
  /// The returned [Uint8List] is [bufferSize] bytes long or less. If it is
  /// zero, the end of the frame has been reached.
  ///
  /// Exceptions:
  ///
  /// - Throws [SANECancelledException] if the operation was cancelled through
  ///   a call to [cancel].
  /// - Throws [SANEJammedException] if the document feeder is jammed.
  /// - Throws [SANENoDocumentsException] if the document feeder is out of
  ///   documents.
  /// - Throws [SANECoverOpenException] if the scanner cover is open.
  /// - Throws [SANEIoException] if an error occurred while communicating with
  ///   the device.
  /// - Throws [SANENoMemoryException] if no memory is available.
  /// - Throws [SANEAccessDeniedException] if access to the device has been
  ///   denied due to insufficient or invalid authentication.
  ///
  /// See also:
  ///
  /// - [`sane_read`](https://sane-project.gitlab.io/standard/api.html#sane-read)
  FutureOr<Uint8List> read(SANEHandle handle, int bufferSize);

  /// Tries to cancel the currently pending operation of the device immediately
  /// or as quickly as possible.
  ///
  /// See also:
  ///
  /// - [`sane_cancel`](https://sane-project.gitlab.io/standard/api.html#sane-cancel)
  FutureOr<void> cancel(SANEHandle handle);
}
