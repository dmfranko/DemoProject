require 'rspec'
require 'rspec/core/formatters/base_text_formatter'
require 'rspec/core/formatters/html_printer'
require 'gmail'
require 'sys/uname'
include Sys

#https://github.com/GICodeWarrior/threaded-rspec

module RSpec
  module Core
    module Formatters
      class HtmlPrinter
        def print_html_start
          @output.puts YALE_HTML_HEADER
          @output.puts YALE_REPORT_HEADER
        end

        def print_summary( was_dry_run, duration, example_count, failure_count, pending_count )
          # TODO - kill dry_run?
          if was_dry_run
            totals = "This was a dry-run"
          else
            totals =  "#{example_count} example#{'s' unless example_count == 1}, "
            totals << "#{failure_count} failure#{'s' unless failure_count == 1}"
            totals << ", #{pending_count} pending" if pending_count > 0
          end

          formatted_duration = sprintf("%.5f", duration)

          @output.puts "<script type=\"text/javascript\">document.getElementById('duration').innerHTML = \"Finished in <strong>#{formatted_duration} seconds</strong>\";</script>"
          @output.puts "<script type=\"text/javascript\">document.getElementById('totals').innerHTML = \"#{totals}\";</script>"
          @output.puts "<script type=\"text/javascript\">document.getElementById('browser').innerHTML = \"#{Uname.sysname}\";</script>"
          @output.puts "<script type=\"text/javascript\">localStorage.g=JSON.stringify([['Pass',#{example_count}],['Fail',#{failure_count}],['Pending',#{pending_count}]])</script>"
          @output.puts "</div>"
          @output.puts "</div>"
          @output.puts "</body>"
          @output.puts "</html>"

          gmail = Gmail.new("yaleqa@gmail.com","")
          gmail.deliver do
            to "dan.franko@yale.edu"
            subject "Test is complete!"
            html_part do
              content_type 'text/html; charset=UTF-8'
              body "<p>Done!</p>"
            end
            #add_file "/path/to/some_image.jpg"
          end
        end

        YALE_REPORT_HEADER = <<-EOF
<div class="rspec-report container">
<div id="rspec-header">
  <div id="label">
    <h1>Yale Automation Report</h1>
  </div>

  <div id="display-filters">
    <input id="passed_checkbox"  name="passed_checkbox"  type="checkbox" checked="checked" onchange="apply_filters()" value="1" /> <label for="passed_checkbox">Passed</label>
    <input id="failed_checkbox"  name="failed_checkbox"  type="checkbox" checked="checked" onchange="apply_filters()" value="2" /> <label for="failed_checkbox">Failed</label>
    <input id="pending_checkbox" name="pending_checkbox" type="checkbox" checked="checked" onchange="apply_filters()" value="3" /> <label for="pending_checkbox">Pending</label>
  </div>

  <div id="summary">
    <p id="totals">&#160;</p>
    <p id="duration">&#160;</p>
  </div>
  <div id="chart">
    <div id="container" style="min-width: 200px; height: 200px; margin: 0 auto"></div>
    <script>
    $(function () {
    var chart;
    
    $(document).ready(function () {
      
      // Build the chart
        $('#container').highcharts({
            chart: {
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false
            },
            title: {
                text: 'Test Results'
            },
            tooltip: {
              pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: false
                    },
                    showInLegend: true
                }
            },
            series: [{
                type: 'pie',
                name: 'Browser share',
                data: JSON.parse(localStorage.g)
            }]
        });
    });
    
});
</script>
  </div>
  <div id="deets">
  <table class="table table-bordered table-condensed table-responsive">
    <tr>
      <td>Browser</td>
      <td id="browser"></td>
    </tr>
    <tr>
      <td>OS</td>
      <td id="OS">Mac</td>
    </tr>
    <tr>
      <td>Date</td>
      <td id="Date">#{Time.now.to_s}</td>
    </tr>
    <tr>
      <td>Time</td>
      <td id="Time">12 PM</td>
    </tr>
    </table>
  </div>
</div>
<div class="results">
EOF


        YALE_GLOBAL_STYLES = <<-EOF
#rspec-header {
  background: #65C400; color: #fff; height: 250px;
  margin: 10px 10px 10px 10px;
  position: relative;
}

.rspec-report h1 {
  margin: 0px 10px 0px 10px;
  padding: 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  font-size: 1.8em;
  position: absolute;
}

#deets {
  float:left;
  margin: 60px 10px 0px 20px;
  position: absolute;
}

#chart {
  float:right;
  margin: 10px 10px 0px 60px;
}

#label {
  float:left;
}

#display-filters {
    font-family: "Lucida Grande",Helvetica,sans-serif;
    position: absolute;
    bottom: 0;
    left: 20px;
}

#summary {
  float:right;
  padding: 5px 10px;
  font-family: "Lucida Grande", Helvetica, sans-serif;
  text-align: right;
}

#summary p {
  margin: 0 0 0 2px;
}

#summary #totals {
  font-size: 1.2em;
}

.example_group {
  margin: 0 10px 5px;
  background: #fff;
}

dl {
  margin: 0; padding: 0 0 5px;
  font: normal 11px "Lucida Grande", Helvetica, sans-serif;
}

dt {
  padding: 3px;
  background: #65C400;
  color: #fff;
  font-weight: bold;
}

dd {
  margin: 5px 0 5px 5px;
  padding: 3px 3px 3px 18px;
}

dd .duration {
  padding-left: 5px;
  text-align: right;
  right: 0px;
  float:right;
}

dd.example.passed {
  border-left: 5px solid #65C400;
  border-bottom: 1px solid #65C400;
  background: #DBFFB4; color: #3D7700;
}

dd.example.not_implemented {
  border-left: 5px solid #FAF834;
  border-bottom: 1px solid #FAF834;
  background: #FCFB98; color: #131313;
}

dd.example.pending_fixed {
  border-left: 5px solid #0000C2;
  border-bottom: 1px solid #0000C2;
  color: #0000C2; background: #D3FBFF;
}

dd.example.failed {
  border-left: 5px solid #C20000;
  border-bottom: 1px solid #C20000;
  color: #C20000; background: #FFFBD3;
}


dt.not_implemented {
  color: #000000; background: #FAF834;
}

dt.pending_fixed {
  color: #FFFFFF; background: #C40D0D;
}

dt.failed {
  color: #FFFFFF; background: #C40D0D;
}


#rspec-header.not_implemented {
  color: #000000; background: #FAF834;
}

#rspec-header.pending_fixed {
  color: #FFFFFF; background: #C40D0D;
}

#rspec-header.failed {
  color: #FFFFFF; background: #C40D0D;
}


.backtrace {
  color: #000;
  font-size: 12px;
}

a {
  color: #BE5C00;
}

/* Ruby code, style similar to vibrant ink */
.ruby {
  font-size: 12px;
  font-family: monospace;
  color: white;
  background-color: black;
  padding: 0.1em 0 0.2em 0;
}

.ruby .keyword { color: #FF6600; }
.ruby .constant { color: #339999; }
.ruby .attribute { color: white; }
.ruby .global { color: white; }
.ruby .module { color: white; }
.ruby .class { color: white; }
.ruby .string { color: #66FF00; }
.ruby .ident { color: white; }
.ruby .method { color: #FFCC00; }
.ruby .number { color: white; }
.ruby .char { color: white; }
.ruby .comment { color: #9933CC; }
.ruby .symbol { color: white; }
.ruby .regex { color: #44B4CC; }
.ruby .punct { color: white; }
.ruby .escape { color: white; }
.ruby .interp { color: white; }
.ruby .expr { color: white; }

.ruby .offending { background-color: gray; }
.ruby .linenum {
  width: 75px;
  padding: 0.1em 1em 0.2em 0;
  color: #000000;
  background-color: #FFFBD3;
}
EOF


        YALE_HTML_HEADER = <<-EOF
<!DOCTYPE html>
<html lang='en'>
<head>
  <title>RSpec results</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Expires" content="-1" />
  <meta http-equiv="Pragma" content="no-cache" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src='http://code.jquery.com/jquery-1.10.1.min.js'></script>"
  <script src="//netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap.min.js"></script>
  <link href="//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css" rel="stylesheet">
  <script src='http://code.highcharts.com/highcharts.js'></script>
  <style type="text/css">
  body {
    margin: 0;
    padding: 0;
    background: #fff;
    font-size: 80%;
  }
  </style>
  <script type="text/javascript">
    // <![CDATA[
#{GLOBAL_SCRIPTS}
    // ]]>
  </script>
  <style type="text/css">
#{YALE_GLOBAL_STYLES}
  </style>
</head>
<body>
EOF

      end
    end
  end
end
