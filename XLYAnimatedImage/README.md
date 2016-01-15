## XLYAnimatedImage ##

play animated images using player. Easy to associated with any thing which can draw UIImage.

### swift 2 ###

swift 2 is required. And better use framework.

### Quick look ###

In most scene, developer will async load image data rather than other ways.

```swift

import XLYAnimatedImage

// get data
let data = ... // load from some where, network or ...

// scale has a default value equals to screen scale, or you can specify it.
let animatedImage = AnimatedGIFImage(data: data, scale: default)

// setup player and keep a reference.
let player = AnimatedImagePlayer(image: animatedImage) {
    image, index in
    someImageView.image = image
}

// config time elapse call back
player.onTimeElapse = {
    [unowned self] time in
    self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
}

```

or use a helper extension method on UIImageView.

```swift

// set replay to true will replay animatedImage even if it's same object.
let player = xly_setAnimatedImage(animatedImage, replay: true).onTimeElapse = {
    [unowned self] time in
    self.timeSlider.value = Float(time / self.imageView.xly_animatedImagePlayer!.totalTime)
}

player.speed = xxx

```

see more in demo.

