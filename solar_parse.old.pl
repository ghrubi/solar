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

# my $outfile = "/home/gene/projects/perl/wtm_out.html";
#my $outfile = "/home/gene/projects/perl/solar_output.html";
my $outfile = "/home/gene/projects/perl/solar_output.png";

# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for detailed data.
#my $url_summary = "https://api.enphaseenergy.com/api/v2/systems/712162/summary?" . $my_url_info;
my $url_detail = "https://api.enphaseenergy.com/api/v2/systems/712162/stats?" . $my_url_info;;

# URL get it.
my $mech = WWW::Mechanize->new( agent => $my_user_agent );
$mech->cookie_jar(HTTP::Cookies->new());
$mech->get($url_detail);

#$mech->get($url2);
#$mech->get($url3);

# Get HTML content of report.
my $html_string = $mech->content();
#print $html_string;

# Parse this shit. Need all power data points.
#my @html_elements = split(',', $html_string);
#print "   " . $html_elements[3] . "\n";
#print "   " . $html_elements[4] . "\n";
#print "   " . $html_elements[10] . "\n";

#my @curr_power = split(':', $html_elements[3]);
#my @total_power = split(':', $html_elements[4]);
#my @report_time = split(':', $html_elements[10]);
#my @grid_status = split(':', $html_elements[8]);

#my @data_points =~ /"powr":(.*),$/$1/;

#print "   " . $curr_power[1] . "\n";
#print "   " . $total_power[1] . "\n";
#print "   " . $report_time[1] . "\n";

# Convert time to something readable.
use POSIX 'strftime';
#my $time_stamp = strftime("%-I:%M:%S%p", localtime($report_time[1]));
##print "   " . $time_stamp . "\n";

#my $url_data = "0";
my @y_plot;
my @x_plot;
my @tmp_data;

# First pass will get the timestamps
my $i = 0;
foreach my $val ($html_string =~ m/"end_at":\d+/g) {
#  print "$val\n";
  @tmp_data = split(':', $val);
#  $url_data = $url_data . ',' . $tmp_data[1];
#  $x_plot[$i] = $tmp_data[1];
  $x_plot[$i] = strftime('[%-H,%M,%S]',localtime($tmp_data[1]));
  $i++;
}

# Reset $i.
$i=0;

# Second pass will get the power values
foreach my $val ($html_string =~ m/"powr":\d+/g) {
#  print "$val\n";
  @tmp_data = split(':', $val);
#  $url_data = $url_data . ',' . $tmp_data[1];
  $y_plot[$i] = $tmp_data[1];
  $i++;
}

my $n = 0; # number index of the position.
my $p = 1; # next position.
my $s = 4; # total position spots.
my $l = @x_plot;
my $m = int($l/$s); # distance between positions.
print "\$m is $m\n";

print "[\'Time\', \'Watts\']";
for ($i=0; $i<$l; $i++) {
  if (($i+1) == $p) {
#    print "[$i]:Print all\n";
    print ",\n" . '[' . $x_plot[$i] . ', ' . $y_plot[$i] . ']';
    $n++;
    if ($n < $s) {
      $p = $n * $m;
    }
    else {
      $p = $l;
    }
  }     
  else {
#    print "[$i]:No datetime\n";
#    print ",\n" . '[\'\', ' . $y_plot[$i] . ']';
    print ",\n" . '[' . $x_plot[$i] . ', ' . $y_plot[$i] . ']';
  }

}
print "\n]);\n";

exit;

# Open output file.
#open(OUTFILE, ">$outfile");
#binmode(OUTFILE, ":utf8");
open(IMG, ">$outfile");
binmode IMG;


# Print outfile HTML
# If number are >999, follow with kW. Otherwise, it's W.
#if ($curr_power[1] > 999) {
#  print OUTFILE sprintf("%.2f", $curr_power[1]/1000) . "kW,";
#}
#else {
#  print OUTFILE $curr_power[1] . "W,";
#}

#if ($total_power[1] > 999) {
#  print OUTFILE sprintf("%.2f",$total_power[1]/1000) . "kWh,";
#}
#else {
#  print OUTFILE $total_power[1] . "Wh,";
#}

#print OUTFILE $time_stamp . "," . $grid_status[1];

#print OUTFILE "$html_string";

#print OUTFILE "http://chart.apis.google.com/chart?chd=t:" . $url_data . "&chs=200x100&cht=lc&chds=0,6000&chxt=y&chxl=0:|0|2000|4000|6000&chtt=Solar+Production\n";

#my $url_chart = "http://chart.apis.google.com/chart?chd=t:" . $url_data . "&chs=300x100&cht=lc&chds=0,6000&chxt=y,y&chxl=0:|0|2000|4000|6000|1:|Power%20(W)&chxp=1,50&chtt=Solar+Production";

#$mech->get($url_chart);

# Get HTML content of report.
#$html_string = $mech->content();
#print IMG $html_string;
#print OUTFILE "
#<html> \n
#<body> \n
#<img src=$url_chart></img> \n
#</body> \n
#</html> \n";

#close(IMG);
#close(OUTFILE);
