#!/usr/bin/env perl -n

BEGIN {
  print "# Summary\n\n"
}

# Trim whitespace
s/^\s+|\s+$//g;

# Print headlines
if (/^# (.*)/) {
  print "* [$1]($ARGV)\n"
}

# Print subheadlines
if (/^## (.*)/) {
  my $subheadline = $1;
  print "  * [$subheadline]($ARGV#$subheadline)\n"
}
