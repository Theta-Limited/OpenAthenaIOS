# NSExceptionSwift

A tiny library that lets you catch Objective-C NSExceptions right in your Swift code.

## Integration

#### CocoaPods

You can use [CocoaPods](http://cocoapods.org/) to install `NSExceptionSwift` by adding it to your `Podfile`:

```ruby
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
    pod 'NSExceptionSwift', '~> 1.0.0'
end
```

#### Swift Package Manager

You can use [The Swift Package Manager](https://swift.org/package-manager) to install `NSExceptionSwift` by adding the proper description to your `Package.swift` file:

```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/ky1vstar/NSExceptionSwift.git", from: "1.0.0"),
    ]
)
```
