#
# Be sure to run `pod lib lint Shakuro.iOS_Toolbox.PlaceholderTextView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

# TODO: add email validator
Pod::Spec.new do |s|
    s.name             = 'Shakuro.iOS_Toolbox'
    s.version          = '0.5.4'
    s.summary          = 'A bunch of components for iOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!
    s.description      = <<-DESC
TODO: Add long description of the pod here.
                        DESC

    s.homepage         = 'https://github.com/shakurocom/iOS_Toolbox'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.authors          = {'Sanakabarabaka' => 'slaschuk@shakuro.com',
                            'wwwpix' => 'spopov@shakuro.com'}
    s.source           = { :git => 'https://github.com/shakurocom/iOS_Toolbox.git', :tag => s.version }
    s.ios.deployment_target = '10.0'

# s.resource_bundles = {
#   'Shakuro.iOS_Toolbox.PlaceholderTextView' => ['Shakuro.iOS_Toolbox.PlaceholderTextView/Assets/*.png']
# }

# s.public_header_files = 'Pod/Classes/**/*.h'
# s.dependency 'AFNetworking', '~> 2.3'

    s.subspec 'PlaceholderTextView' do |sp|

        sp.source_files = 'PlaceholderTextView/Source/Classes/**/*'

    end

    s.subspec 'Extensions' do |sp|

        sp.source_files = 'Extensions/Source/Classes/**/*'
        sp.frameworks = 'UIKit'

    end

    s.subspec 'VideoCamera' do |sp|

        sp.dependency  'Shakuro.iOS_Toolbox/ImageProcessing'
        sp.dependency  'Shakuro.iOS_Toolbox/Device'
        sp.source_files = 'VideoCamera/Source/**/*'
        sp.frameworks = 'Accelerate', 'AVFoundation', 'UIKit'

    end

    s.subspec 'Device' do |sp|

        sp.source_files = 'Device/Source/**/*'
        sp.frameworks = 'UIKit', 'CoreMotion'

    end

    s.subspec 'ImageProcessing' do |sp|

        sp.source_files = 'ImageProcessing/Source/**/*'
        sp.frameworks = 'CoreGraphics', 'Accelerate', 'AVFoundation', 'UIKit'

    end

    s.subspec 'Keyboard' do |sp|

        sp.source_files = 'Keyboard/Source/**/*'
        sp.frameworks = 'UIKit'

    end

    s.subspec 'Keychain' do |sp|

        sp.source_files = 'Keychain/Source/**/*'
        sp.frameworks = 'Foundation'

    end

end
