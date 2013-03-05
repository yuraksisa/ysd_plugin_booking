Gem::Specification.new do |s|
  s.name    = "ysd_plugin_booking"
  s.version = "0.1.2"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2013-02-28"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb','views/**/*.erb','i18n/**/*.yml','static/**/*.*'] 
  s.description = "Booking plugin"
  s.summary = "Booking plugin"
  
  s.add_runtime_dependency "json"

  s.add_runtime_dependency "ysd_md_booking"    
  s.add_runtime_dependency "ysd_md_configuration"
end
