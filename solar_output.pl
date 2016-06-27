#!/user/bin/perl -w

use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;

# Set constants
my $system_id = '712162';
my $api_key = 'f28df63641562571da21a10255e8c6ca';
my $user_id = '4e544d334f544d790a';
my $my_url_info = "key=" . $api_key .
                  "&user_id=" . $user_id;

# Get today's date for the report.
use DateTime qw();
my $report_date = DateTime->now(time_zone => 'America/Los_Angeles');
$report_date = $report_date->strftime('%Y-%m-%d');

my $tmpl_infile = "/home/gene/projects/perl/solar/google_solar_chart.tmpl";
my $html_outfile = "/home/gene/projects/perl/solar/solar_output.html";
my $html_chart = "cms.asskick.com/solar_data/solar_output.html";
my $outfile = "/home/gene/projects/perl/solar/solar_output.png";

# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for detailed solar data.
my $url_detail = "https://api.enphaseenergy.com/api/v2/systems/712162/stats?" . $my_url_info;;

# URL for google-generated chart.
my $url_chart = "http://localhost/solar_data/solar_output.html";

# URL get it.
my $mech = WWW::Mechanize->new( agent => $my_user_agent );
$mech->cookie_jar(HTTP::Cookies->new());
$mech->get($url_detail);

#$mech->get($url2);
#$mech->get($url3);

# Get HTML content of report.
my $html_string = $mech->content();
#print $html_string;

# For converting epoch time to something google can use for 'timeofday' data.
use POSIX 'strftime';

my @y_plot; 
my @x_plot;
my @tmp_data;

# First pass will get the timestamps
my $i = 0;
foreach my $val ($html_string =~ m/"end_at":\d+/g) {
#  print "$val\n";
  @tmp_data = split(':', $val);
  $x_plot[$i] = strftime('[%-H,%M,%S]',localtime($tmp_data[1]));
  $i++;
}

# Second pass will get the power values
# Reset $i.
$i=0;
# 2 vars for max value and index position
my $max_power = 0;
my $max_index = 0;
foreach my $val ($html_string =~ m/"powr":\d+/g) {
  @tmp_data = split(':', $val);
  $y_plot[$i] = $tmp_data[1];
  if ($max_power < $tmp_data[1]) {
     $max_power = $tmp_data[1];
     $max_index = $i;
  }
  $i++;
}

# Assemble string of chart data. Specially format the peak point.
my $p = 50; # next position.
my $l = @x_plot;
my $chart_data = "";

# Again, this was for plotting timestamp every so man plots. 
# Unused now. Timestamps always.
for ($i=0; $i<$l; $i++) {
  if ($i == $max_index) {
    $chart_data = $chart_data . ",\n" . '[' . $x_plot[$i] . ', ' . $y_plot[$i] . ', \'point { size: 12; shape-type: star; shape-rotation: 180; fill-color: #FF0000; visible: on }\'' . ']';
  }
  else {
    $chart_data = $chart_data . ",\n" . '[' . $x_plot[$i] . ', ' . $y_plot[$i] . ', null' . ']';
  }

}

# Function comma-ify numbers
sub commify {
  my $input = shift;
  $input = reverse $input;
  $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
  return reverse $input;
}

# Strip leading and trailing []'s.
$x_plot[$max_index] = substr($x_plot[$max_index], 1, -1);

@tmp_data = split(',', $x_plot[$max_index]);
#my $chart_peak_time = "$tmp_data[0]:$tmp_data[1]";

use Time::Local;
use POSIX 'strftime';
my $time = timelocal(0, $tmp_data[1], $tmp_data[0], 1, 0, 0);
my $chart_peak_time = sprintf strftime('%-I:%M%p',localtime($time));
my $chart_peak = "Peak " . commify($y_plot[$max_index]) . "W \@ $chart_peak_time";

# Open input template file.
open(FILE, "$tmpl_infile");

# Open html output file.
open(OUTFILE, ">$html_outfile");
#binmode(OUTFILE, ":utf8");

select((select(OUTFILE), $|=1)[0]);

# Open graph image output file.
#open(IMG, ">$outfile");
#binmode IMG;


while(<FILE>) {
  $_ =~ s/<CHART_DATA>/$chart_data/; 
  $_ =~ s/<CHART_PEAK>/$chart_peak/; 
  print OUTFILE $_;
}

# Close input and html output file handles;
close(FILE);
close(OUTFILE);

# Run WKHTMLTOIMAGE command to dump to PNG.
system(" /home/gene/wkhtmltox/bin/wkhtmltoimage --javascript-delay 6000 --width 800 --height 300 $html_chart $outfile");

