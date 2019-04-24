require 'test/unit'
require 'rubygems'

$VERBOSE = $CODERAY_DEBUG = true
$:.unshift 'lib'

mydir = File.dirname(__FILE__)
suite = Dir[File.join(mydir, '*.rb')]
        .map { |tc| File.basename(tc).sub(/\.rb$/, '') } - %w'suite vhdl'

puts "Running CodeRay unit tests: #{suite.join(', ')}"

helpers = %w(file_type word_list tokens)
helpers + (suite - helpers).each do |test_case|
  load File.join(mydir, test_case + '.rb')
end
