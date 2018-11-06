Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '11.0'
s.name = "UIDraggableController"
s.summary = "RWPickFlavor lets a user select an ice cream flavor."
s.requires_arc = true

# 2
s.version = "1.0"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Rolando Rodriguez" => "cxavier71@gmail.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/rorodriguez117/UIDraggableController"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/rorodriguez117/UIDraggableController.git",
:tag => "#{s.version}" }

# 7
s.framework = "UIKit"

# 8
s.source_files = "UIDraggableController/**/*.{swift}"

# 9
s.resources = "UIDraggableController/**/*.{png,jpeg,jpg,storyboard,xib,xcassets}"

# 10
s.swift_version = "4.2"

end

