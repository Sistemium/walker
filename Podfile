#Execute line bellow before pod install!!!
#brew install autoconf automake libtool

platform :ios, '12.1'
use_frameworks!

target 'walker' do
  pod "GEOSwift"
  pod 'Squeal'
  pod 'Firebase/Core'
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'PromisesSwift'
  pod 'Just'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'Squeal'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
    end
end
