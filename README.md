# TYCImagePreviewController

<p align="center">
<img src="https://img.shields.io/badge/platform-iOS%2010%2B-blue.svg" alt="Platform: iOS 10+"/>
<img src="https://img.shields.io/badge/language-Swift%204-green.svg" alt="Language: Swift 4" /></a>
</p>
Simple drop-n-go solution for previewing image or video.

<img src="https://raw.githubusercontent.com/yunnnyunnn/TYCImagePreviewController/master/demo.gif" alt=“demo” width=“249” height=“444” />

## Requirements
* iOS 10.0+
* Swift 4.0+

## Demo

Build and run the `TYCImagePreviewControllerDemo` project in Xcode.

## Installation

Drag `TYCImagePreviewController.swift` into your project. That's it.

## Example Usage

Preview image:

```swift
let samplePhoto = UIImage(named: "sample-photo")!
let previewController = TYCImagePreviewController(image: samplePhoto)
self.present(previewController, animated: true, completion: nil)
```

Preview video:

```swift
let sampleVideo = Bundle.main.url(forResource: "sample-video", withExtension: "mp4")!
let previewController = TYCImagePreviewController(videoURL: sampleVideo)
self.present(previewController, animated: true, completion: nil)
```

## Discussion

Open an issue or submit a pull request.


## Contact

Tim Chen

- https://www.linkedin.com/in/timychen12
- https://facebook.com/yunnnyunnn
- timychen12@gmail.com

## License

TYCImagePreviewController is available under the MIT license. See the LICENSE file for more info.
