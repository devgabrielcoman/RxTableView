Pod::Spec.new do |s|
  s.name             = 'RxTableView'
  s.version          = '1.0.9'
  s.summary          = 'Reactive UITableView'
  s.description      = <<-DESC
A reactive implementation of UITableView using RxSwift
			DESC

  s.homepage         = 'https://github.com/devgabrielcoman/RxTableView'
  s.license          = { :type => 'GNU GENERAL PUBLIC LICENSE Version 2', :file => 'LICENSE' }
  s.author           = { 'devgabrielcoman' => 'dev.gabriel.coman@gmail.com' }
  s.source           = { :git => 'https://github.com/devgabrielcoman/RxTableView.git', :tag => "1.0.9" }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'RxSwift', '3.4.1'
  s.dependency 'RxCocoa', '3.4.1'
end
