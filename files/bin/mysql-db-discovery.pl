#!/usr/bin/perl

$first = 1;

print "{\n";
print "\t\"data\":[\n\n";

for (`echo "show databases" | mysql -N`) {
  ($db) = m/^(\S+).*$/;

  print "\t,\n" if not $first;
  $first = 0;

  print "\t{\n";
  print "\t\t\"{#DB}\":\"$db\"\n";
  print "\t}\n";
  }


print "\n\t]\n";
print "}\n";

