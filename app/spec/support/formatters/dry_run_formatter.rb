require 'rspec/core/formatters/documentation_formatter'

class DryRunFormatter < RSpec::Core::Formatters::DocumentationFormatter
  def initialize(output)
    output = File.new(File.expand_path(File.join('.', 'app', 'reports', "#{Time.now.strftime("%Y%m%d_%H%M%S")}-dry.txt")), 'w')
    super(output)
    @group_level = 0
  end

  def example_failed(example)
    example_passed(example)
  end
end