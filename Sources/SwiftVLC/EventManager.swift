//
//  EventManager.swift
//  SwiftVLC
//
//  Created by sunlubo on 2019/1/31.
//

import CVLC

/// Event types.
public enum VLCEventType: Int32 {
  case mediaMetaChanged = 0
  case mediaSubItemAdded
  case mediaDurationChanged
  case mediaParsedChanged
  case mediaFreed
  case mediaStateChanged
  case mediaSubItemTreeAdded
  
  case mediaPlayerMediaChanged = 0x100
  case mediaPlayerNothingSpecial
  case mediaPlayerOpening
  case mediaPlayerBuffering
  case mediaPlayerPlaying
  case mediaPlayerPaused
  case mediaPlayerStopped
  case mediaPlayerForward
  case mediaPlayerBackward
  case mediaPlayerEndReached
  case mediaPlayerEncounteredError
  case mediaPlayerTimeChanged
  case mediaPlayerPositionChanged
  case mediaPlayerSeekableChanged
  case mediaPlayerPausableChanged
  case mediaPlayerTitleChanged
  case mediaPlayerSnapshotTaken
  case mediaPlayerLengthChanged
  case mediaPlayerVout
  case mediaPlayerScrambledChanged
  case mediaPlayerESAdded
  case mediaPlayerESDeleted
  case mediaPlayerESSelected
  case mediaPlayerCorked
  case mediaPlayerUncorked
  case mediaPlayerMuted
  case mediaPlayerUnmuted
  case mediaPlayerAudioVolume
  case mediaPlayerAudioDevice
  case mediaPlayerChapterChanged
  
  case mediaListItemAdded = 0x200
  case mediaListWillAddItem
  case mediaListItemDeleted
  case mediaListWillDeleteItem
  case mediaListEndReached
  
  case mediaListViewItemAdded = 0x300
  case mediaListViewWillAddItem
  case mediaListViewItemDeleted
  case mediaListViewWillDeleteItem
  
  case mediaListPlayerPlayed = 0x400
  case mediaListPlayerNextItemSet
  case mediaListPlayerStopped
  
  /// Useless event, it will be triggered only when calling `libvlc_media_discoverer_start()`.
  @available(*, deprecated)
  case mediaDiscovererStarted = 0x500
  /// Useless event, it will be triggered only when calling `libvlc_media_discoverer_stop()`.
  @available(*, deprecated)
  case mediaDiscovererEnded
  
  case rendererDiscovererItemAdded
  case rendererDiscovererItemDeleted
  
  case vlmMediaAdded = 0x600
  case vlmMediaRemoved
  case vlmMediaChanged
  case vlmMediaInstanceStarted
  case vlmMediaInstanceStopped
  case vlmMediaInstanceStatusInit
  case vlmMediaInstanceStatusOpening
  case vlmMediaInstanceStatusPlaying
  case vlmMediaInstanceStatusPause
  case vlmMediaInstanceStatusEnd
  case vlmMediaInstanceStatusError
}

typealias CVLCEvent = CVLC.libvlc_event_t

/// A LibVLC event.
public struct VLCEvent {
  /// Event type.
  public let type: VLCEventType
  /// Object emitting the event.
  public let obj: UnsafeMutableRawPointer
  
  init(cEvent: libvlc_event_t) {
    self.type = VLCEventType(rawValue: cEvent.type)!
    self.obj = cEvent.p_obj
  }
}

/// Event manager that belongs to a libvlc object, and from whom events can be received.
public final class VLCEventManager {
  let instance: OpaquePointer
  
  init(instance: OpaquePointer) {
    self.instance = instance
  }
}
