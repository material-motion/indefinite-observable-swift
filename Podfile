workspace 'IndefiniteObservable.xcworkspace'
use_frameworks!

target "Catalog" do
  pod 'CatalogByConvention'
  pod 'IndefiniteObservable/examples', :path => './'
  project 'examples/apps/Catalog/Catalog.xcodeproj'
end

abstract_target 'Tests' do
  project 'examples/apps/Catalog/Catalog.xcodeproj'
  pod 'IndefiniteObservable/tests', :path => './'

  target "UnitTests"
  target "OSXTests"
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['SWIFT_VERSION'] = "3.0"
      if target.name.start_with?("Material")
        configuration.build_settings['WARNING_CFLAGS'] ="$(inherited) -Wall -Wcast-align -Wconversion -Werror -Wextra -Wimplicit-atomic-properties -Wmissing-prototypes -Wno-sign-conversion -Wno-unused-parameter -Woverlength-strings -Wshadow -Wstrict-selector-match -Wundeclared-selector -Wunreachable-code"
      end
    end
  end
end
