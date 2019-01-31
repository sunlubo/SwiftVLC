//
//  VLCMedia.swift
//  SwiftVLC
//
//  Created by sunlubo on 2019/1/31.
//

import CVLC

/// libvlc_media_t is an abstract representation of a playable media.
/// It consists of a media location and various optional meta data.
public final class VLCMedia {
  let instance: OpaquePointer

  /// Create a media with a certain given media resource location, for instance a valid URL.
  ///
  /// - Note: To refer to a local file with this function, the `file://...` URI syntax
  ///   __must__ be used (see IETF RFC3986).
  ///   We recommend using libvlc_media_new_path() instead when dealing with
  ///   local files.
  ///
  /// - Parameters:
  ///   - vlc: the instance
  ///   - path: the media location
  public init?(vlc: VLC, mrl: String) {
    guard let instance = libvlc_media_new_location(vlc.instance, mrl) else {
      return nil
    }
    self.instance = instance
  }

  deinit {
    libvlc_media_release(instance)
  }

  /// Get the media resource locator (mrl) from a media descriptor object.
  public var mrl: String? {
    let cstr = libvlc_media_get_mrl(instance)
    defer { libvlc_free(cstr) }
    return String(cString: cstr)
  }

  /// Get current state of media descriptor object.
  ///
  /// Possible media states are:
  /// - libvlc_NothingSpecial=0
  /// - libvlc_Opening
  /// - libvlc_Playing
  /// - libvlc_Paused
  /// - libvlc_Stopped
  /// - libvlc_Ended
  /// - libvlc_Error
  public var state: State {
    return State(rawValue: Int32(libvlc_media_get_state(instance).rawValue))!
  }

  /// Get event manager from media descriptor object.
  ///
  /// - Note: This function doesn't increment reference counting.
  public var eventManager: VLCEventManager {
    return VLCEventManager(instance: libvlc_media_event_manager(instance))
  }

  /// Get duration (in ms) of media descriptor object item.
  public var duration: Int64 {
    return libvlc_media_get_duration(instance)
  }

  /// Get the media type of the media descriptor object.
  public var mediaType: MediaType {
    return MediaType(rawValue: libvlc_media_get_type(instance).rawValue)!
  }
}

extension VLCMedia {

  /// Meta data types.
  public enum MetaType: Int32 {
    case libvlc_meta_Title
    case libvlc_meta_Artist
    case libvlc_meta_Genre
    case libvlc_meta_Copyright
    case libvlc_meta_Album
    case libvlc_meta_TrackNumber
    case libvlc_meta_Description
    case libvlc_meta_Rating
    case libvlc_meta_Date
    case libvlc_meta_Setting
    case libvlc_meta_URL
    case libvlc_meta_Language
    case libvlc_meta_NowPlaying
    case libvlc_meta_Publisher
    case libvlc_meta_EncodedBy
    case libvlc_meta_ArtworkURL
    case libvlc_meta_TrackID
    case libvlc_meta_TrackTotal
    case libvlc_meta_Director
    case libvlc_meta_Season
    case libvlc_meta_Episode
    case libvlc_meta_ShowName
    case libvlc_meta_Actors
    case libvlc_meta_AlbumArtist
    case libvlc_meta_DiscNumber
    case libvlc_meta_DiscTotal
  }
}

extension VLCMedia {

  public enum State: Int32 {
    case libvlc_NothingSpecial = 0
    case libvlc_Opening
    case libvlc_Buffering /* XXX: Deprecated value. Check the
     * libvlc_MediaPlayerBuffering event to know the
     * buffering state of a libvlc_media_player */
    case libvlc_Playing
    case libvlc_Paused
    case libvlc_Stopped
    case libvlc_Ended
    case libvlc_Error
  }
}

extension VLCMedia {

  public enum TrackType: Int32 {
    case libvlc_track_unknown = -1
    case libvlc_track_audio = 0
    case libvlc_track_video = 1
    case libvlc_track_text = 2
  }
}

extension VLCMedia {

  public enum MediaType: UInt32 {
    case libvlc_media_type_unknown
    case libvlc_media_type_file
    case libvlc_media_type_directory
    case libvlc_media_type_disc
    case libvlc_media_type_stream
    case libvlc_media_type_playlist
  }
}
