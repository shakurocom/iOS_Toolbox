#
#
#

Pod::Spec.new do |s|
    s.name             = 'Shakuro.iOS_Toolbox'
    s.version          = '0.17.1'
    s.summary          = 'A bunch of components for iOS'
    s.homepage         = 'https://github.com/shakurocom/iOS_Toolbox'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.authors          = {'Sanakabarabaka' => 'slaschuk@shakuro.com',
                            'wwwpix' => 'spopov@shakuro.com'}
    s.source           = { :git => 'https://github.com/shakurocom/iOS_Toolbox.git', :tag => s.version }
    s.swift_version    = '5.0'

    s.ios.deployment_target = '10.0'

    # --- subspecs ---

    s.subspec 'CommonTypes' do |sp|

        sp.source_files = 'CommonTypes/Source/**/*'
        sp.frameworks = 'Foundation'

    end

    s.subspec 'Device' do |sp|

        sp.source_files = 'Device/Source/**/*'
        sp.frameworks = 'UIKit', 'CoreMotion'

    end

    s.subspec 'DraggableDetailsOverlay' do |sp|

        sp.dependency 'Shakuro.iOS_Toolbox/Extensions'
        sp.source_files = 'DraggableDetailsOverlay/Source/**/*'
        sp.frameworks = 'UIKit'

    end

    s.subspec 'EMail' do |sp|

        sp.source_files = 'EMail/Source/**/*'
        sp.frameworks = 'Foundation'

    end

    s.subspec 'EventHandler' do |sp|

        sp.dependency 'Shakuro.iOS_Toolbox/Extensions'
        sp.source_files = 'EventHandler/Source/**/*'
        sp.frameworks = 'Foundation'

    end

    s.subspec 'Exceptions' do |sp|

        sp.source_files = 'Exceptions/Source/**/*'
        sp.frameworks = 'Foundation'

    end

    s.subspec 'Extensions' do |sp|

        sp.source_files = 'Extensions/Source/**/*'
        sp.frameworks = 'UIKit'
        sp.dependency 'CommonCryptoModule', '1.0.2'

    end

    s.subspec 'HTTPClient' do |sp|

        sp.dependency 'Shakuro.iOS_Toolbox/CommonTypes'
        sp.source_files = 'HTTPClient/Source/**/*'
        sp.frameworks = 'Foundation'
        sp.dependency 'Alamofire', '4.7.3'

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

    s.subspec 'Labels' do |sp|

        sp.source_files = 'Labels/Source/**/*'
        sp.frameworks = 'UIKit'

    end

    s.subspec 'PlaceholderTextView' do |sp|

        sp.source_files = 'PlaceholderTextView/Source/**/*'
        sp.frameworks = 'UIKit'

    end

    s.subspec 'PullToRefresh' do |sp|

        sp.source_files = 'PullToRefresh/Source/**/*'
        sp.frameworks = 'UIKit'

    end

    s.subspec 'Settings' do |sp|

        sp.source_files = 'Settings/Source/**/*'
        sp.frameworks = 'Foundation'

    end

    s.subspec 'TaskManager' do |sp|

        sp.dependency 'Shakuro.iOS_Toolbox/CommonTypes'
        sp.dependency 'Shakuro.iOS_Toolbox/Extensions'
        sp.source_files = 'TaskManager/Source/**/*'
        sp.frameworks = 'Foundation'

    end

    s.subspec 'VideoCamera' do |sp|

        sp.dependency 'Shakuro.iOS_Toolbox/ImageProcessing'
        sp.dependency 'Shakuro.iOS_Toolbox/Device'
        sp.source_files = 'VideoCamera/Source/**/*'
        sp.frameworks = 'Accelerate', 'AVFoundation', 'UIKit'

    end

end
