
Pod::Spec.new do |s|
  s.name         = "XLYAnimatedImage"
  s.version      = "3.0.1"
  s.summary      = "extendable animated image player."
  s.homepage     = "https://github.com/kaizeiyimi/XLYAnimatedImage"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "kaizei" => "kaizeiyimi@126.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/kaizeiyimi/XLYAnimatedImage.git", :tag => "3.0.1" }
  s.source_files  = "XLYAnimatedImage/codes/**/*.swift"
  s.requires_arc = true
end
