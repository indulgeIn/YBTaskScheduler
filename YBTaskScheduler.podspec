

Pod::Spec.new do |s|


  s.name         = "YBTaskScheduler"
  s.version      = "1.0"
  s.summary      = "iOS 任务调度器，为 CPU 和内存减负"
  s.description  = <<-DESC
  					iOS 任务调度器，为 CPU 和内存减负
                   DESC

  s.homepage     = "https://github.com/indulgeIn"

  s.license      = "MIT"

  s.author       = { "杨波" => "1106355439@qq.com" }
 
  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/indulgeIn/YBTaskScheduler", :tag => "#{s.version}" }

  s.source_files = "YBTaskScheduler/**/*.{h,m}"

  s.requires_arc = true

end
