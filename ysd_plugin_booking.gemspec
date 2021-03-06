Gem::Specification.new do |s|
  s.name    = "ysd_plugin_booking"
  s.version = "0.4.193"
  s.authors = ["Yurak Sisa Dream"]
  s.date    = "2013-02-28"
  s.email   = ["yurak.sisa.dream@gmail.com"]
  s.files   = Dir['lib/**/*.rb','views/**/*.erb','i18n/**/*.yml','static/**/*.*','fonts/**/*.*'] 
  s.description = "Booking plugin"
  s.summary = "Booking plugin"
  
  s.add_runtime_dependency "json"
  
  s.add_runtime_dependency "ysd_core_plugins"
  s.add_runtime_dependency "ysd_core_themes"
  s.add_runtime_dependency "ysd_yito_core"

  s.add_runtime_dependency "ysd_md_booking"
  s.add_runtime_dependency "ysd_md_cms"    
  s.add_runtime_dependency "ysd_md_configuration"
  s.add_runtime_dependency "ysd_md_calendar"
  s.add_runtime_dependency "ysd_md_comparison"
  
  s.add_runtime_dependency "ysd_plugin_payment"
  s.add_runtime_dependency "ysd_plugin_rates"
  s.add_runtime_dependency "ysd_plugin_calendar"
  s.add_runtime_dependency "ysd_plugin_auth"

  s.add_runtime_dependency "prawn"
  s.add_runtime_dependency "prawn-table"
  s.add_runtime_dependency "uglifier"

  s.add_development_dependency "dm-sqlite-adapter" # Model testing using sqlite
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rack"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "sinatra"
  s.add_development_dependency "sinatra-r18n"

end
