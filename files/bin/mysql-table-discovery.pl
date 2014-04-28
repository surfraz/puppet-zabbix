#!/usr/bin/perl

$first = 1;

print "{\n";
print "\t\"data\":[\n\n";

for (`echo "SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ( 'information_schema', 'performance_schema', 'mysql' )" | mysql -N`) {
  ($db,$table) = m/^(\S+)\s+(\S+).*$/;

  print "\t,\n" if not $first;
  $first = 0;

  print "\t{\n";
  print "\t\t\"{#DB}\":\"$db\",\n";
  print "\t\t\"{#TABLE}\":\"$table\"\n";
  print "\t}\n";
  }


print "\n\t]\n";
print "}\n";

