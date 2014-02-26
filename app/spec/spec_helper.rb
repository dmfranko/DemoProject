ENV.delete 'HTTP_PROXY' if ENV['HTTP_PROXY']
require 'erb'
require 'psych'
require 'rspec-rerun'
require 'fuubar'
require 'magicspec'
require 'active_record'
require 'net/http'
require 'watir-browser-factory'
require 'rspec-rest-formatter'
require 'net/ping'
require 'byebug'

Dir["./app/spec/support/**/*.rb"].sort.each {|f|require f}

SAUCE_USERNAME = ""
SAUCE_ACCESS_KEY = ""
class Hash
  def find_all_values_for(key)
    result = []
    result << self[key]
    self.values.each do |hash_value|
      values = [hash_value] unless hash_value.is_a? Array
      if values
        values.each do |value|
          result += value.find_all_values_for(key) if value.is_a? Hash
        end
      end
    end
    result.compact
  end
end

Magicspec::Initializer.new(File.expand_path(File.join('.')), 'DemoProject')
$:.unshift(File.expand_path File.join('.'))

# Make sure all of our supporting files are loaded
Dir["./app/spec/support/**/*.rb"].sort.each {|f|require f}

# Determine if we're local or not and setup accordingly.
# In this case we're getting our request from something external
if ENV['RUNTIME']
  $params = eval(ENV['RUNTIME'])
  $caps = {
    :browserName => $params[:platform]["browser"],
    :browser_version => $params[:platform]["version"],
    :os => $params[:platform]["os"],
    :local => false
  }
  $metadata = {
    :notes => $params[:notes],
    :description => $config[:description]
  }
  $tags = $params[:tags]
  $filter = $params[:filter]
# Here we're running locally
else
  $caps = {
    :browserName => $config["browser"],
    :browser_version => "Unknow",
    :os => RbConfig::CONFIG["host_os"],
    :local => true
  }
  $metadata = {
    :notes => $config[:notes],
    :description => $config[:description]
  }
  $tags = Hash[*$config.tags.split(',').map {|k| [k.to_sym, true]}.flatten]
end

RSpec.configure do |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.run_all_when_everything_filtered = true
  c.alias_example_to :test_case
  c.alias_it_should_behave_like_to :include_shared

  c.color_enabled = true

  # Force expect syntax
  c.expect_with :rspec do |e|
    e.syntax = :expect
  end

  if ENV['REFRESH']
    # Set everyting to run
    c.filter_run

    # User the dry run formatter
    c.add_formatter("DryRunFormatter")
    #c.add_formatter("documentation")
    # Make everything fail

    c.before(:all) do
      raise 'Fail each test immediately'
    end

    # We'll collect our keys into an array
    $KEYS = []
    c.before(:each) do |x|
      keys = x.example.metadata.each_key.to_a
      keys.each do |k|
        $KEYS.push k
      end
    end

    c.after(:suite) {
    # Strip out any rspec keys/tags to get just the ones we've added
      d = [:description_args,:caller,:execution_result,:example_group,:example_group_block]
      d.each {|k| $KEYS.delete(k)
      }
    }
  else
  # Add formatters
    c.add_formatter("Fuubar")
    # Check to make sure we can reach our service
    HOST = "http://localhost:3000"
    begin 
      if JSON.parse(RestClient.get("#{HOST}/about/summary.json"))["status"] == "up"
        c.add_formatter("RestFormatter")
      else
        c.add_formatter("Lazyman::LazymanFormatter")
      end
    rescue
      c.add_formatter("Lazyman::LazymanFormatter")
    end

    # If we've got a filter use that
    if $filter && ! $filter.empty?
      c.inclusion_filter = {:full_description => Regexp.union(*Array($filter).map {|d| Regexp.new(d) })}
    end

    # If we have tags and no filter, use that
    if $tags && c.inclusion_filter.empty?
      unless($tags.empty?)
      c.filter_run $tags
      end
    end
  end

  def test_data file
    content = ''
    file_path = File.expand_path(File.join('.', 'app', 'test_data', "#{file}.yml"))
    raise "Can not find #{file}.yml" unless File.exists?(file_path)
    File.open(file_path, 'r') do |handle|
      content = handle.read
    end
    Psych.load ERB.new(content).result(binding)
  end
end
