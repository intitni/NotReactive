Pod::Spec.new do |s|
  s.name             = 'NotReactive'
  s.version          = '0.2.6'
  s.summary          = 'A simple way to subscribe to value change or event emission.'
  s.description      = 'A siiiimple way to subscribe to value change or event emission.'

  s.homepage         = 'https://github.com/intitni/NotReactive'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'intitni' => 'int123c@gmail.com' }
  s.source           = { :git => 'https://github.com/intitni/NotReactive.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/intitni'
  s.ios.deployment_target = '9.0'
  s.swift_versions = ['5']
  s.source_files = 'NotReactive/Classes/**/*'
end
