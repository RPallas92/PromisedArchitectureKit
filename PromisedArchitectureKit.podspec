#
# Be sure to run `pod lib lint PromisedArchitectureKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PromisedArchitectureKit'
  s.version          = '2.2.0'
  s.summary          = 'Simplest architecture for PromiseKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Simplest architecture for PromiseKit.
This architectural approach, fits on the View layer of Clean Architecture. It is an alternative to Model-View-Presenter or Model-View-ViewModel, and it is strongly inspired by Redux.

The idea is to constrain the changes to view state in order to enforce correctness. Changes to state are explicity documented by Events and by a pure reducer function. This approach also allows testing presentation logic with ease (it also includes a mechanism to inject dependencies, such views, API Clients, etc.)
                       DESC

  s.homepage         = 'https://github.com/rpallas92/PromisedArchitectureKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'rpallas92' => 'ricardo.pallas@adidas-group.com' }
  s.source           = { :git => 'https://github.com/rpallas92/PromisedArchitectureKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Classes/**/*'
  
  # s.resource_bundles = {
  #   'PromisedArchitectureKit' => ['PromisedArchitectureKit/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'PromiseKit', '~> 6.0'
  s.swift_version = '4.2'
end
