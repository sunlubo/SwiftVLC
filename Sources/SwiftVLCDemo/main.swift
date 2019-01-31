import SwiftVLC
import Darwin

try VLC.setupPlugin(path: "/Users/sun/Development/GitHub/Swift/SwiftVLC/libvlc/plugins")

print(VLC.version)
print(VLC.compiler)
print(VLC.changeset)

let vlc = VLC.make(args: ["--play-and-pause",
                          "--no-color",
                          "--no-video-title-show",
                          "--verbose=4",
                          "--no-sout-keep",
                          "--vout=macosx",
                          "--text-renderer=freetype",
                          "--extraintf=macosx_dialog_provider",
                          "--audio-resampler=soxr"])!
print(vlc)
print("audio")
for f in vlc.availableAudioFilters {
  print(f)
}
print("video")
for f in vlc.availableVideoFilters {
  print(f)
}
