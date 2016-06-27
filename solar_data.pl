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
my $outfile = "/home/gene/projects/perl/solar/solar_data.html";

# Set user agent to avoid the dreaded lack-of-Flash bullshit. 
my $my_user_agent = 'Mozilla/5.0 (Linux; U; Android 2.2; de-de; HTC Desire HD 1.18.161.2 Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1';

# URL for summary data.
my $url_summary = "https://api.enphaseenergy.com/api/v2/systems/712162/summary?" . $my_url_info;

# URL get it.
my $mech = WWW::Mechanize->new( agent => $my_user_agent );
$mech->cookie_jar(HTTP::Cookies->new());
$mech->get($url_summary);

#$mech->get($url2);
#$mech->get($url3);

# Get HTML content of report.
my $html_string = $mech->content();
#print $html_string;

# Parse this shit. Need current power, total energy for today, and last report time.
my @html_elements = split(',', $html_string);
#print "   " . $html_elements[3] . "\n";
#print "   " . $html_elements[4] . "\n";
#print "   " . $html_elements[10] . "\n";

my @curr_power = split(':', $html_elements[3]);
my @total_power = split(':', $html_elements[4]);
my @report_time = split(':', $html_elements[10]);
my @grid_status = split(':', $html_elements[8]);

# Remove quotes from grid_status.
$grid_status[1] =~ s/^"(.*)"$/$1/;

#print "   " . $curr_power[1] . "\n";
#print "   " . $total_power[1] . "\n";
#print "   " . $report_time[1] . "\n";

# Convert time to something readable.
use POSIX 'strftime';
my $time_stamp = strftime("%-I:%M:%S%p", localtime($report_time[1]));
#print "   " . $time_stamp . "\n";

#foreach my $val (@html_elements) {
#  print "$val\n";
#}

# Open output file.
open(OUTFILE, ">$outfile");
#binmode(OUTFILE, ":utf8");

# Print outfile HTML
# If number are >999, follow with kW. Otherwise, it's W.
if ($curr_power[1] > 999) {
  print OUTFILE sprintf("%.2f", $curr_power[1]/1000) . "kW,";
}
else {
  print OUTFILE $curr_power[1] . "W,";
}

if ($total_power[1] > 999) {
  print OUTFILE sprintf("%.2f",$total_power[1]/1000) . "kWh,";
}
else {
  print OUTFILE $total_power[1] . "Wh,";
}

print OUTFILE $time_stamp . "," . $grid_status[1];

#print OUTFILE "$html_string";
close(OUTFILE);
