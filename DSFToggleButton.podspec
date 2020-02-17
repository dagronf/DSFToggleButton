Pod::Spec.new do |s|
  s.name         = "DSFToggleButton"
  s.version      = "1.0"
  s.summary      = "A macOS toggle button that mimics the toggle button of iOS"
  s.description  = <<-DESC
    A macOS toggle button that mimics the toggle button of iOS
  DESC
  s.homepage     = "https://github.com/dagronf"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Darren Ford" => "dford_au-reg@yahoo.com" }
  s.social_media_url   = ""
  s.osx.deployment_target = "10.11"
  s.source       = { :git => ".git", :tag => s.version.to_s }
  s.subspec "Core" do |ss|
    ss.source_files  = "Sources/DSFToggleButton/**/*.swift"
  end

  s.osx.framework  = 'AppKit'

  s.swift_version = "5.0"
end
