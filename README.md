## XLYAnimatedImage

play animated images using player. Easy to associated with any thing which can draw UIImage.

support **speed**, **skipFramesEnabled**, **displayLinkFrameInterval** config. Auto preload and clear cache if needed.

### updates
updated to swift 3 and refined some code.

### swift 3

2.x will base on swift3.0.

### swift 2

swift 2.2 or 2.2 please use 1.x.

### Quick look

In most scene, developer will async load image data rather than other ways.

```swift

import XLYAnimatedImage

// get data
let data = ... // load from some where, network or ...

// scale has a default value equals to screen scale, or you can specify it.
let animatedImage = AnimatedDataImage(data: data, scale: default)

// setup player and keep a reference.
let player = AnimatedImagePlayer(display: {[weak self] image, index in
        self?.image = image
    },
    stop: {[weak self] in
        self?.image = nil
    })

// setup image
player.image = animatedImage

// set replay to true will replay animatedImage even if it's same object.
player.setImage(image, replay: true)

// config player
player.onTimeElapse = { [unowned self] time in
    self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
}

player.speed = 2
player.skipFramesEnabled = true
player.displayLinkFrameInterval = 2


```

or use a helper extension method on UIImageView.

```swift

// set image
imageView.xly_setAnimatedImage(animatedImage, replay: true)

// get player and then config as you wish
let player = imageView.xly_animatedImagePlayer

```

see more in demo.

### feature

 * uses protocol so that anyone can make impl of `AnimatedImage` and can be playered with player.
 * player supports `paused`, `speed`, `skipFramesEnabled`, `displayLinkFrameInterval` config.
 * player provides `frameIndex` for current image frame index, `time` for current playing time.
 * player can move to any index by calling `move(ToFrame:)`, can move to any time by calling `move(ToTime:)`.
 * player uses `display` callback for you to display a frame, `stop` callback for you to stop playing an image, and `onTimeElapse` to nofify time changing.
 * also at any time, you can change callbacks and image, and can also refresh an image's playing by set param 'replay' to `true`.

 ### more

 no apng support now cause I'm waiting for apple to support in iOS device. if you need it, you can write your own impl, it's not difficult.


