Pod::Spec.new do |s|
  s.name         = "IndefiniteObservable"
  s.summary      = "IndefiniteObservable is a minimal implementation of Observable with no concept of completion or failure."
  s.version      = "2.0.0"
  s.authors      = "The Material Motion Authors"
  s.license      = "Apache 2.0"
  s.homepage     = "https://github.com/material-motion/indefinite-observable-swift"
  s.source       = { :git => "https://github.com/material-motion/indefinite-observable-swift.git", :tag => "v" + s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.requires_arc = true
  s.default_subspec = "lib"

  s.subspec "lib" do |ss|
    ss.source_files = "src/*.{swift}", "src/private/*.{swift}"
  end

  s.subspec "examples" do |ss|
    ss.ios.source_files = "examples/*.{swift}", "examples/supplemental/*.{swift}"
    ss.ios.exclude_files = "examples/TableOfContents.swift"
    #ss.resources = "examples/supplemental/*.{xcassets}"
    ss.dependency "IndefiniteObservable/lib"
  end

  #s.subspec "tests" do |ss|
  #  ss.source_files = "tests/src/*.{swift}", "tests/src/private/*.{swift}"
  #  ss.dependency "IndefiniteObservable/lib"
  #end
end
