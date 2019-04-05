platform :ios, '12.1'
use_frameworks!

target 'walker' do
  pod 'GEOSwift', '~> 3.1'
  pod 'Squeal', '~> 1.2'
  pod 'Firebase/Core'
  pod 'Fabric', '~> 1.9.0'
  pod 'Crashlytics', '~> 3.12.0'
  pod 'PromisesSwift', '~> 1.2.7'
  pod 'Just', '~> 0.7.1'
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
