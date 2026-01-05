Pod::Spec.new do |s|
  s.name             = 'QuranRenderer'
  s.version          = '1.0.0'
  s.summary          = 'quran-renderer native library (vendored XCFramework)'
  s.description      = 'Vendored QuranRenderer.xcframework for use by Flutter FFI.'
  s.homepage         = 'https://example.invalid/quran-renderer'
  s.license          = { :type => 'Proprietary', :text => 'See project repository for licensing details.' }
  s.author           = { 'quran-renderer' => 'n/a' }

  s.platform         = :ios, '13.0'
  s.static_framework = true

  s.source           = { :git => 'https://example.invalid/quran-renderer.git', :tag => s.version.to_s }
  s.vendored_frameworks = 'Frameworks/QuranRenderer.xcframework'
  
  # Force load all symbols from the static library so they're available via DynamicLibrary.process()
  # Use -all_load to load all symbols from all static libraries
  s.xcconfig = {
    'OTHER_LDFLAGS' => '-ObjC -all_load'
  }
end
