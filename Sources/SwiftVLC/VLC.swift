//
//  VLC.swift
//  SwiftVLC
//
//  Created by sunlubo on 2019/1/30.
//

import CVLC
import Darwin

public final class VLC {
  let instance: OpaquePointer
  var logLevel: LogLevel = .debug

  /// Create and initialize a libvlc instance.
  ///
  /// This functions accept a list of "command line" arguments similar to the
  /// `main()`. These arguments affect the LibVLC instance default configuration.
  ///
  /// - Note: LibVLC may create threads. Therefore, any thread-unsafe process
  ///   initialization must be performed before calling `libvlc_new()`.
  ///   In particular and where applicable:
  ///   - `setlocale()` and `textdomain()`,
  ///   - `setenv()`, `unsetenv()` and `putenv()`,
  ///   - with the X11 display system, `XInitThreads()` (see also `libvlc_media_player_set_xwindow()`) and
  ///   - on Microsoft Windows, `SetErrorMode()`.
  ///   - `sigprocmask()` shall never be invoked; `pthread_sigmask()` can be used.
  ///
  /// On POSIX systems, the SIGCHLD signal __must not__ be ignored, i.e. the
  /// signal handler must set to SIG_DFL or a function pointer, not SIG_IGN.
  /// Also while LibVLC is active, the `wait()` function shall not be called, and
  /// any call to `waitpid()` shall use a strictly positive value for the first
  /// parameter (i.e. the PID). Failure to follow those rules may lead to a
  /// deadlock or a busy loop.
  /// Also on POSIX systems, it is recommended that the SIGPIPE signal be blocked,
  /// even if it is not, in principles, necessary, e.g.:
  ///
  ///     sigset_t set;
  ///
  ///     signal(SIGCHLD, SIG_DFL);
  ///     sigemptyset(&set);
  ///     sigaddset(&set, SIGPIPE);
  ///     pthread_sigmask(SIG_BLOCK, &set, NULL);
  ///
  /// On Microsoft Windows Vista/2008, the process error mode
  /// SEM_FAILCRITICALERRORS flag __must__ be set before using LibVLC.
  /// On later versions, that is optional and unnecessary.
  /// Also on Microsoft Windows (Vista and any later version), setting the default
  /// DLL directories to SYSTEM32 exclusively is strongly recommended for
  /// security reasons:
  ///
  ///     SetErrorMode(SEM_FAILCRITICALERRORS);
  ///     SetDefaultDllDirectories(LOAD_LIBRARY_SEARCH_SYSTEM32);
  ///
  /// - Version: Arguments are meant to be passed from the command line to LibVLC, just like
  ///   VLC media player does. The list of valid arguments depends on the LibVLC
  ///   version, the operating system and platform, and set of available LibVLC
  ///   plugins. Invalid or unsupported arguments will cause the function to fail
  ///   (i.e. return NULL). Also, some arguments may alter the behaviour or
  ///   otherwise interfere with other LibVLC functions.
  ///
  /// - Warning: There is absolutely no warranty or promise of forward, backward and
  ///   cross-platform compatibility with regards to `libvlc_new()` arguments.
  ///   We recommend that you do not use them, other than when debugging.
  ///
  /// - Parameter args: list of arguments
  public init?(args: [String] = []) {
    let argv: [UnsafePointer<Int8>?] = args.map({ $0.withCString({ $0 }) })
    guard let instance = libvlc_new(Int32(args.count), argv) else {
      return nil
    }
    self.instance = instance
  }

  deinit {
    libvlc_release(instance)
  }

  /// Returns a list of audio filters that are available.
  public var availableAudioFilters: [VLCModuleDescription] {
    var list = [VLCModuleDescription]()
    var next = libvlc_audio_filter_list_get(instance)
    defer { libvlc_module_description_list_release(next) }
    while let md = next?.pointee {
      list.append(VLCModuleDescription(cDescription: md))
      next = next?.pointee.p_next
    }
    return list
  }

  /// Returns a list of video filters that are available.
  public var availableVideoFilters: [VLCModuleDescription] {
    var list = [VLCModuleDescription]()
    var next = libvlc_video_filter_list_get(instance)
    defer { libvlc_module_description_list_release(next) }
    while let md = next?.pointee {
      list.append(VLCModuleDescription(cDescription: md))
      next = next?.pointee.p_next
    }
    return list
  }

  /// Sets the application name.
  /// LibVLC passes this as the user agent string when a protocol requires it.
  ///
  /// - Parameters:
  ///   - name: human-readable application name, e.g. "FooBar player 1.2.3"
  ///   - http: HTTP User Agent, e.g. "FooBar/1.2.3 Python/2.6.0"
  public func setHumanReadableName(_ name: String, httpUserAgent: String) {
    libvlc_set_user_agent(instance, name, httpUserAgent)
  }

  /// Sets some meta-information about the application.
  ///
  /// - Parameters:
  ///   - id: Java-style application identifier, e.g. "com.acme.foobar"
  ///   - version: application version numbers, e.g. "1.2.3"
  ///   - iconName: application icon name, e.g. "foobar"
  public func setApplicationIdentifier(_ id: String, version: String, iconName: String) {
    libvlc_set_app_id(instance, id, version, iconName)
  }
}

extension VLC {

  /// Retrieve libvlc version.
  ///
  /// Example: "1.1.0-git The Luggage"
  public static var version: String {
    return String(cString: libvlc_get_version())
  }

  /// Retrieve libvlc compiler version.
  ///
  /// Example: "gcc version 4.2.3 (Ubuntu 4.2.3-2ubuntu6)"
  public static var compiler: String {
    return String(cString: libvlc_get_compiler())
  }

  /// Retrieve libvlc changeset.
  ///
  /// Example: "aa9bce0bc4"
  public static var changeset: String {
    return String(cString: libvlc_get_changeset())
  }

  /// If you don't have this variable set you must have plugins directory
  /// with the executable or libvlc_new() will not work!
  ///
  /// - Parameter path: the plugin path
  /// - Throws: VLCError
  public static func setupPlugin(path: String) throws {
    if setenv("VLC_PLUGIN_PATH", path, 1) != 0 {
      throw VLCError(code: errno)
    }
  }
}

// MARK: - Log

/// Logging messages level.
public enum LogLevel: Int32 {
  /// Debug message
  case debug = 0
  /// Important informational message
  case notice = 2
  /// Warning (potential error) message
  case warning = 3
  /// Error message
  case error = 4
}

extension VLC {

  public func enableLogging(_ enable: Bool, level: LogLevel = .debug) {
    if enable {
      logLevel = level
      libvlc_log_set(instance, { data, level, ctx, fmt, args in
        let ll = Unmanaged<VLC>.fromOpaque(data!).takeUnretainedValue().logLevel.rawValue
        guard level >= ll else {
          return
        }

        var cstr: UnsafeMutablePointer<Int8>?
        defer { free(cstr) }
        if vasprintf(&cstr, fmt, args) != -1, let str = String(cString: cstr) {
          print(str)
        }
      }, Unmanaged.passUnretained(self).toOpaque())
    } else {
      libvlc_log_unset(instance)
    }
  }
}

// MARK: - Time

// These functions provide access to the LibVLC time/clock.
extension VLC {

  /// Return the current time as defined by LibVLC. The unit is the microsecond.
  ///
  /// Time increases monotonically (regardless of time zone changes and RTC adjustements).
  /// The origin is arbitrary but consistent across the whole system
  /// (e.g. the system uptim, the time since the system was booted).
  ///
  /// - Note: On systems that support it, the POSIX monotonic clock is used.
  public static var clock: Int64 {
    return libvlc_clock()
  }

  /// Return the delay (in microseconds) until a certain timestamp.
  ///
  /// - Parameter pts: timestamp
  /// - Returns: negative if timestamp is in the past, positive if it is in the future
  public static func delay(_ pts: Int64) -> Int64 {
    return libvlc_delay(pts)
  }
}
