require 'erb'
require 'rspec/core/formatters/html_formatter'
#require './override.rb'

module Lazyman
  class LazymanFormatter < ::RSpec::Core::Formatters::HtmlFormatter
    def initialize(output)
      output = File.new(File.expand_path(File.join('.', 'app', 'reports', "#{Time.now.strftime("%Y%m%d_%H%M%S")}.html")), 'w')
      super(output)
      @printer.class.send(:define_method, 'puts') do |what|
        @output.puts what
      end #define_method
    end

    def example_failed(example)
      super(example)
      if $navi
        failed_url = $navi.url rescue $navi.current_url
        @printer.puts "<a target=\"_blank\" href=\"#{failed_url}\">failed url is [#{failed_url}]</a>"
        @printer.puts '<br />'
        @printer.puts '<p>Extra problem text</p>'
        @printer.flush
      end #if
    end

    def example_passed(example)
      super(example)
      @printer.flush
    end

    def extra_failure_content(failure)
      browser = example_group.before_all_ivars[:@browser] || @browser
      # If we'ere dealing with a browser get a screenshot on failure
      if browser
        browser.screenshot.save File.expand_path(File.join('.', 'app', 'reports','screenshots', "#{Time.now.strftime("%Y%m%d_%H%M%S")}.png"))      
        
        # Need to figure out how to remotely upload
        content = []
        content << "<span>"
        content << "<a target='_blank' href='http://127.0.0.1:8020/o365/app/reports/screenshots/20131031_103612.png'>screenshot</a>"
        content << "</span>"
        super + content.join($/)
      end
    end
  end #LazymanFormatter
end #Lazyman