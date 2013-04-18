require 'XcodePages'

desc 'Compiles HTML documentation using Doxygen'
task :doxygen do
  ENV['PROJECT_NAME'] ||= File.basename(Dir.pwd)
  XcodePages.doxygen
end

desc 'Compiles DocSet documentation using AppleDoc'
task :appledoc do
  %x(appledoc .)
end
