require 'test/unit'

$VERBOSE = $CODERAY_DEBUG = true
$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'coderay'

mydir = File.dirname(__FILE__)
suite = Dir[File.join(mydir, '*.rb')]
        .map { |tc| File.basename(tc).sub(/\.rb$/, '') } - %w[suite for_redcloth]

puts "Running basic CodeRay #{CodeRay::VERSION} tests: #{suite.join(', ')}"

suite.each do |test_case|
  load File.join(mydir, test_case + '.rb')
end
