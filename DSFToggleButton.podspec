Pod::Spec.new do |s|
  s.name			= "DSFToggleButton"
  s.version			= "3.0"
  s.summary			= "A layer-based NSButton that mimics the toggle button style of iOS"
  s.homepage		= "https://github.com/dagronf/DSFToggleButton"
  s.license			= { :type => "MIT", :file => "LICENSE" }
  s.author			= { "Darren Ford" => "dford_au-reg@yahoo.com" }
  s.screenshot		= "https://github.com/dagronf/dagronf.github.io/raw/master/art/projects/DSFToggleButton/primary.png"
  s.social_media_url = "https://twitter.com/dagronf"
  s.platform		= :osx, '10.9'
  
  s.source			= { 
    :git => "https://github.com/dagronf/DSFToggleButton.git", 
    :tag => s.version.to_s 
  }
  
  s.subspec "Core" do |ss|
    ss.source_files = "Sources/DSFToggleButton/**/*.swift"
  end

  s.osx.framework	= "AppKit"
  s.osx.deployment_target = "10.9"
  
  s.swift_version 	= "5.0"
end
