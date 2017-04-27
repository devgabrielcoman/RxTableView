Pod::Spec.new do |s|
  s.name             = 'RxTableView'
  s.version          = '1.0.7'
  s.summary          = 'Reactive UITableView'
  s.description      = <<-DESC
A reactive implementation of UITableView using RxSwift
			DESC

  s.homepage         = 'https://github.com/devgabrielcoman/RxTableView'
  s.license          = { :type => 'GNU GENERAL PUBLIC LICENSE Version 2', :file => 'LICENSE' }
  s.author           = { 'devgabrielcoman' => 'dev.gabriel.coman@gmail.com' }
  s.source           = { :git => 'https://github.com/devgabrielcoman/RxTableView.git', :tag => "1.0.7" }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Pod/Classes/**/*'
  s.dependency 'RxSwift', '3.1.0'
  s.dependency 'RxCocoa', '3.1.0'
end
