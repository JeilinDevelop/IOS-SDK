Pod::Spec.new do |s|
  s.name             = "JxCameraSDK"
  s.version          = "1.0.0"
  s.summary          = "Jx Camera SDK"
  s.description      = "A powerful camera control SDK for iOS."

  s.homepage         = "https://github.com/JeilinDevelop/IOS-SDK.git"
  s.license          = { :type => "Commercial Free", :file => "release/LICENSE" }
  s.author           = { "jeilintech" => "jeilintechsz@gmail.com" }
  s.source           = { :git => "https://github.com/JeilinDevelop/IOS-SDK.git", :tag => s.version }

  # 发布二进制 xcframework
  s.vendored_frameworks = "release/JxCameraSDK.xcframework"

  s.platform          = :ios, "12.0"
  s.swift_version     = "5.9"

  s.requires_arc = true
end
