# SwiftVLC

> Note: SwiftVLC is still in development, and the API is not guaranteed to be stable. It's subject to change without warning.

## Installation

### Swift Package Manager

SwiftVLC primarily uses [SwiftPM](https://swift.org/package-manager/) as its build tool, so we recommend using that as well. If you want to depend on SwiftVLC in your own project, it's as simple as adding a `dependencies` clause to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sunlubo/SwiftVLC.git", from: "0.0.1")
]
```

## Usage

```swift
// A simple player from 'https://wiki.videolan.org/LibVLC_SampleCode_SDL/'.

import SwiftVLC
import SwiftSDL2

struct Context {
  let renderer: Renderer
  let texture: Texture
  let mutex: Mutex
}

// VLC prepares to render a video frame.
func lock(
  _ opaque: UnsafeMutableRawPointer?,
  _ planes: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
) -> UnsafeMutableRawPointer? {
  let context = opaque!.bindMemory(to: Context.self, capacity: 1).pointee
  var pitch = 0 as Int32
  context.mutex.lock()
  try! context.texture.lock(pixels: planes, pitch: &pitch)
  return nil // Picture identifier, not needed here.
}

// VLC just rendered a video frame.
func unlock(
  _ opaque: UnsafeMutableRawPointer?,
  _ picture: UnsafeMutableRawPointer?,
  _ planes: UnsafePointer<UnsafeMutableRawPointer?>?
) {
  let context = opaque!.bindMemory(to: Context.self, capacity: 1).pointee
  context.texture.unlock()
  context.mutex.unlock()
}

// VLC wants to display a video frame.
func display(_ opaque: UnsafeMutableRawPointer?, _ picture: UnsafeMutableRawPointer?) {
  let context = opaque!.bindMemory(to: Context.self, capacity: 1).pointee
  try! context.renderer.setDrawColor(Color(r: 0, g: 80, b: 0, a: 255))
  try! context.renderer.clear()
  try! context.renderer.copy(texture: context.texture, dstRect: Rect(x: 160, y: 120, w: 320, h: 240))
  context.renderer.present()
}

try SDL.initialize(flags: [.video])
let window = try Window(title: "Simple Player", width: 640, height: 480, flags: .resizable)
let renderer = try Renderer(window: window)
let texture = try Texture(renderer: renderer, format: .bgr565, access: .streaming, width: 320, height: 240)
let mutex = Mutex()
var context = Context(renderer: renderer, texture: texture, mutex: mutex)

try VLC.setupPlugin(path: "/Users/sun/Development/GitHub/Swift/SwiftVLC/libvlc/plugins")
let vlc = VLC(args: ["--no-audio", "--no-xlib"])!
let media = VLCMedia(vlc: vlc, mrl: "file:///Users/sun/AV/kda.flv")!
let mediaPlayer = VLCMediaPlayer(media: media)!
mediaPlayer.setCallbacks(lockCallback: lock, unlockCallback: unlock, displayCallback: display, opaque: &context)
mediaPlayer.setFormat(chroma: "RV16", width: 320, height: 240, pitch: 640)
try mediaPlayer.play()

while let event = Events.wait(), event.type != EventType.quit.rawValue {}

mediaPlayer.stop()

SDL.quit()
```
