#!/user/bin/perl -w

use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;

# Set constants
my $num_dates = 10; ## Number of dates

my $system_id = '712162';
my $api_key = 'f28df63641562571da21a10255e8c6ca';
my $user_id = '4e544d334f544d790a';
my $my_url_info = "key=" . $api_key .
                  "&user_id=" . $user_id;

# Get today's date for the report.
use DateTime qw();
my $curr_date = DateTime->now(time_zone => 'America/Los_Angeles');

my $tmpl_infile = "/home/gene/projects/perl/solar/google_solar_history.tmpl";
my $html_outfile = "/home/gene/projects/perl/solar/solar_history.html";
my $html_chart = "files.asskick.com:8080/solar_data/solar_history.html";
my $outfile = "/home/gene/projects/perl/solar/solar_history.png";

# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for detailed solar data.
my $url_detail = "https://api.enphaseenergy.com/api/v2/systems/712162/energy_lifetime?" . $my_url_info;;

# URL for google-generated chart.
my $url_chart = "http://localhost/solar_data/solar_history.html";

# URL get it.
my $mech = WWW::Mechanize->new( agent => $my_user_agent );
$mech->cookie_jar(HTTP::Cookies->new());
$mech->get($url_detail);

# Get HTML content of report.
my $html_string = $mech->content();
#print $html_string;

# Start by splitting the html
my @tmp_html = split('"production":', $html_string);
#print "   $tmp_html[0] \n";
#print "   $tmp_html[1] \n";

# Split off the first part
@tmp_html = split('\[', $tmp_html[1]);
#print "   $tmp_html[0] \n";
#print "   $tmp_html[1] \n";

# Split off the last part leaving just the comma-separtated list
@tmp_html = split('\]', $tmp_html[1]);
#print "   $tmp_html[0] \n";
#print "   $tmp_html[1] \n";

# Finally, split the comma-separated list
my @data_list = split('\,', $tmp_html[0]);

# Get the length of the @data_list
my $data_len = scalar @data_list;
#print "Length: $data_len\n";

# Build data array and find max_power
my @data;
my $max_power = 0;
my $max_index = 0;
my $total_power = 0; ## For finding the average

for (my $i=0; $i<$num_dates; $i++) {
  # Length of data for the last array index. Then start the num_dates
  # from the end and move one at a time until the last data is reached.
  my $n = ($data_len-$num_dates)+$i;
  $data[$i] = $data_list[$n];
#  print "\[" . $n . "\] " . $data_list[$n] . "\n";

  # Find max_power
  if ($max_power < $data_list[$n]) {
    $max_power = $data_list[$n];
    $max_index = $i;
  }

  # Add to total for average
  $total_power += $data_list[$n];
}

#Set number of dates to retrieve. Don't include today.
my @dates;

# Get dates and build array in reverse order so dates 
# are in forward chronological order.
# Then, subtract 1 from the month for google's Jan is 0 month shit.
for (my $i=0; $i<$num_dates; $i++) {
  my $tmp_date = $curr_date->subtract(days => 1);
  $tmp_date = $tmp_date->strftime('%m/%d');
  my @m_d = split('/', $tmp_date);
  $tmp_date = "\"" . $m_d[0] . "/" . $m_d[1] . "\"";
  
#  print $tmp_date . "\n";

  # A bit awkward. Need to start down the array and work to 0, not 1.
  # Hence the additional '-1'.
  $dates[$num_dates-$i-1] = $tmp_date;
}
#print @dates;

# Create data strings for template file
my $chart_data = "";
my $chart_peak = ""; ## For max_power and average

# Chart data
for (my $i=0; $i<$num_dates; $i++) {
  $chart_data = $chart_data . "\,\n" . "\[$dates[$i]\, $data[$i]\, null\]";
}

# Peak and average
# Strip leading and trailing ""s from date.
$dates[$max_index] = substr($dates[$max_index], 1, -1);

$chart_peak = "Peak " . commify($data[$max_index]) . "Wh on $dates[$max_index]. ";
$chart_peak = $chart_peak . "Average " . commify($total_power/$num_dates) . "Wh";
#print $chart_data . "\n";

# Function comma-ify numbers
sub commify {
  my $input = shift;
  $input = reverse $input;
  $input =~ s<(\d\d\d)(?=\d)(?!\d*\.)><$1,>g;
  return reverse $input;
}

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
system("/usr/bin/xvfb-run /usr/bin/wkhtmltoimage --javascript-delay 6000 --width 800 --height 300 $html_chart $outfile");
#system("/usr/bin/xvfb-run --server-args=\"-screen 0 1366x768x24\" /usr/bin/wkhtmltoimage --javascript-delay 6000 --width 800 --height 300 $html_chart $outfile");

