## XLYAnimatedImage ##

play animated images using player. Easy to associated with any thing which can draw UIImage.

support **speed**, **skipFrames**, **displayLinkFrameInterval** config. Auto preload and clear cache if needed.

### swift 2 ###

swift 2 is required. And better use framework.

### Quick look ###

In most scene, developer will async load image data rather than other ways.

```swift

import XLYAnimatedImage

// get data
let data = ... // load from some where, network or ...

// scale has a default value equals to screen scale, or you can specify it.
let animatedImage = AnimatedDataImage(data: data, scale: default)

// setup player and keep a reference.
let player = AnimatedImagePlayer {
image, index in
someImageView.image = image
}

// setup image
player.image = animatedImage

// set replay to true will replay animatedImage even if it's same object.
player.setImage(image, replay: true)

// config player
player.onTimeElapse = {
[unowned self] time in
self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
}

player.speed = 2
player.skipFrames = true
player.displayLinkFrameInterval = 2


```

or use a helper extension method on UIImageView.

```swift

imageView.xly_setAnimatedImage(animatedImage, replay: true)

```

see more in demo.

