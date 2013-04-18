require 'XcodePages'

desc 'Compiles documentation using Doxygen'
task :doxygen_docset_install do
  ENV['PROJECT_NAME'] ||= File.basename(Dir.pwd)
  XcodePages.doxygen_docset_install
end
