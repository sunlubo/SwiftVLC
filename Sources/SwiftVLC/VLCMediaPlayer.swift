//
//  VLCMediaPlayer.swift
//  SwiftVLC
//
//  Created by sunlubo on 2019/1/31.
//

import CVLC

/// Callback prototype to allocate and lock a picture buffer.
///
/// Whenever a new video frame needs to be decoded, the lock callback is
/// invoked. Depending on the video chroma, one or three pixel planes of
/// adequate dimensions must be returned via the second parameter. Those
/// planes must be aligned on 32-bytes boundaries.
///
/// - Parameters:
///   - opaque: private pointer as passed to `libvlc_video_set_callbacks()` [IN]
///   - planes: start address of the pixel planes (LibVLC allocates the array
///     of void pointers, this callback must initialize the array) [OUT]
/// - Returns: A private pointer for the display and unlock callbacks to identify the picture buffers
public typealias VLCLockCallback = (
  UnsafeMutableRawPointer?,
  UnsafeMutablePointer<UnsafeMutableRawPointer?>?
) -> UnsafeMutableRawPointer?

/// Callback prototype to unlock a picture buffer.
///
/// When the video frame decoding is complete, the unlock callback is invoked.
/// This callback might not be needed at all. It is only an indication that the
/// application can now read the pixel values if it needs to.
///
/// - Note: A picture buffer is unlocked after the picture is decoded,
///   but before the picture is displayed.
///
/// - Parameters:
///   - opaque: private pointer as passed to libvlc_video_set_callbacks() [IN]
///   - picture: private pointer returned from the @ref libvlc_video_lock_cb callback [IN]
///   - planes: pixel planes as defined by the @ref libvlc_video_lock_cb callback
///     (this parameter is only for convenience) [IN]
public typealias VLCUnlockCallback = (
  UnsafeMutableRawPointer?,
  UnsafeMutableRawPointer?,
  UnsafePointer<UnsafeMutableRawPointer?>?
) -> Void

/// Callback prototype to display a picture.
///
/// When the video frame needs to be shown, as determined by the media playback
/// clock, the display callback is invoked.
///
/// - Parameters:
///   - opaque: private pointer as passed to libvlc_video_set_callbacks() [IN]
///   - picture: private pointer returned from the @ref libvlc_video_lock_cb callback [IN]
public typealias VLCDisplayCallback = (
  UnsafeMutableRawPointer?,
  UnsafeMutableRawPointer?
) -> Void

typealias MediaPlayerBoxValue = (
  opaque: UnsafeMutableRawPointer?,
  lock: VLCLockCallback?,
  unlock: VLCUnlockCallback?,
  display: VLCDisplayCallback?
)
typealias MediaPlayerBox = Box<MediaPlayerBoxValue>

/// A LibVLC media player plays one media (usually in a custom drawable).
public final class VLCMediaPlayer {
  let instance: OpaquePointer

  private var opaque: MediaPlayerBox?

  /// Create an empty Media Player object.
  ///
  /// - Parameter vlc: the libvlc instance in which the Media Player should be created.
  public init?(vlc: VLC) {
    guard let instance = libvlc_media_player_new(vlc.instance) else {
      return nil
    }
    self.instance = instance
  }

  /// Create a Media Player object from a Media.
  ///
  /// - Parameter media: the media. Afterwards the p_md can be safely destroyed.
  public init?(media: VLCMedia) {
    guard let instance = libvlc_media_player_new_from_media(media.instance) else {
      return nil
    }
    self.instance = instance
  }

  deinit {
    libvlc_media_player_release(instance)
  }

  /// 1 if the media player is playing, 0 otherwise
  public var isPlaying: Bool {
    return libvlc_media_player_is_playing(instance) == 1
  }

  /// Set callbacks and private data to render decoded video to a custom area
  /// in memory.
  /// Use `libvlc_video_set_format()` or `libvlc_video_set_format_callbacks()`
  /// to configure the decoded format.
  ///
  /// - Warning: Rendering video into custom memory buffers is considerably less
  ///   efficient than rendering in a custom window as normal.
  ///
  /// For optimal perfomances, VLC media player renders into a custom window, and
  /// does not use this function and associated callbacks. It is __highly recommended__
  /// that other LibVLC-based application do likewise.
  /// To embed video in a window, use `libvlc_media_player_set_xid()` or equivalent
  /// depending on the operating system.
  ///
  /// If window embedding does not fit the application use case, then a custom
  /// LibVLC video output display plugin is required to maintain optimal video
  /// rendering performances.
  ///
  /// The following limitations affect performance:
  /// - Hardware video decoding acceleration will either be disabled completely,
  ///   or require (relatively slow) copy from video/DSP memory to main memory.
  /// - Sub-pictures (subtitles, on-screen display, etc.) must be blent into the
  ///   main picture by the CPU instead of the GPU.
  /// - Depending on the video format, pixel format conversion, picture scaling,
  ///   cropping and/or picture re-orientation, must be performed by the CPU
  ///   instead of the GPU.
  /// - Memory copying is required between LibVLC reference picture buffers and
  ///   application buffers (between lock and unlock callbacks).
  ///
  /// - Parameters:
  ///   - lock: callback to lock video memory (must not be NULL)
  ///   - unlock: callback to unlock video memory (or NULL if not needed)
  ///   - display: callback to display video (or NULL if not needed)
  ///   - opaque: private pointer for the three callbacks (as first parameter)
  public func setCallbacks(
    lockCallback: VLCLockCallback?,
    unlockCallback: VLCUnlockCallback?,
    displayCallback: VLCDisplayCallback?,
    opaque: UnsafeMutableRawPointer?
  ) {
    // Store everything we want to pass into the c function in a `Box` so we can hand-over the reference.
    let box = MediaPlayerBox((
      opaque: opaque,
      lock: lockCallback,
      unlock: unlockCallback,
      display: displayCallback
    ))
    var lock: libvlc_video_lock_cb?
    if lockCallback != nil {
      lock = { (opaque, planes) -> UnsafeMutableRawPointer? in
        let value = Unmanaged<MediaPlayerBox>.fromOpaque(opaque!).takeUnretainedValue().value
        return value.lock?(value.opaque, planes)
      }
    }
    var unlock: libvlc_video_unlock_cb?
    if unlockCallback != nil {
      unlock = { opaque, picture, planes in
        let value = Unmanaged<MediaPlayerBox>.fromOpaque(opaque!).takeUnretainedValue().value
        value.unlock?(value.opaque, picture, planes)
      }
    }
    var display: libvlc_video_display_cb?
    if displayCallback != nil {
      display = { opaque, picture in
        let value = Unmanaged<MediaPlayerBox>.fromOpaque(opaque!).takeUnretainedValue().value
        value.display?(value.opaque, picture)
      }
    }
    libvlc_video_set_callbacks(instance, lock, unlock, display, Unmanaged.passUnretained(box).toOpaque())
    self.opaque = box
  }

  /// Set decoded video chroma and dimensions.
  /// This only works in combination with `libvlc_video_set_callbacks()`,
  /// and is mutually exclusive with `libvlc_video_set_format_callbacks()`.
  ///
  /// - Bug: All pixel planes are expected to have the same pitch.
  ///   To use the YCbCr color space with chrominance subsampling,
  ///   consider using libvlc_video_set_format_callbacks() instead.
  ///
  /// - Parameters:
  ///   - chroma: a four-characters string identifying the chroma (e.g. "RV32" or "YUYV")
  ///   - width: pixel width
  ///   - height: pixel height
  ///   - pitch: line pitch (in bytes)
  public func setFormat(chroma: String, width: Int, height: Int, pitch: Int) {
    libvlc_video_set_format(instance, chroma, UInt32(width), UInt32(height), UInt32(pitch))
  }

  /// Play.
  public func play() throws {
    try throwIfFail(libvlc_media_player_play(instance))
  }

  /// Toggle pause (no effect if there is no media).
  public func pause() {
    libvlc_media_player_pause(instance)
  }

  /// Stop (no effect if there is no media).
  public func stop() {
    libvlc_media_player_stop(instance)
  }
}
