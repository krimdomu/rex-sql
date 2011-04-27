#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::SQL::mysql::CREATE;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(get_create_sql get_dsn);

my $TYPE_MAP = {
   string   => sub { # 0 => complete, 1 => first part, 2 => part in (...)
                  if($_[2] && $_[2] <= 255) {
                     return "VARCHAR($_[2])";
                  }

                  return "TEXT";
               },
   integer  => sub {
                  if($_[2] && $_[2] == 1) {
                     return "TINYINT";
                  }

                  if($_[2] && $_[2] == 2) {
                     return "SMALLINT";
                  }

                  if($_[2] && $_[2] == 3) {
                     return "MEDIUMINT";
                  }

                  if($_[2] && $_[2] == 4) {
                     return "INT";
                  }

                  if($_[2] && $_[2] == 8) {
                     return "BIGINT";
                  }
               },
   float    => "FLOAT",
   decimal  => "DECIMAL",
   blob     => "BLOB",
   clob     => "TEXT",
   timestamp   => "TIMESTAMP",
   time        => "TIME",
   date        => "DATE",
   enum        => sub {
                  my $values = "'" . join("','", @{$_[0]->{"values"}}) . "'";
                  return "ENUM ($values)";
               },
};

sub get_create_sql {
   my ($table, $columns, $options) = @_;

   my $sql = "CREATE TABLE `%s` (%s) %s";

   my $cols;
   my @primarys = ();
   for my $col (keys %$columns) {
      my $str = "`$col` ";

      my ($type, $dummy, $klammer) = ($columns->{$col}->{"type"} =~ m/^(\w+)(\s*\(([^\)]+)\))?/);

      if(ref($TYPE_MAP->{$type}) eq "CODE") {
         $str .= &{ $TYPE_MAP->{$type} }($columns->{$col}, $type, $klammer);
      }
      else {
         $str .= $TYPE_MAP->{$type};
      }

      if($columns->{$col}->{"primary"} && $columns->{$col}->{"primary"} eq "true") {
         push @primarys, $col;
      }

      if($columns->{$col}->{"autoincrement"} && $columns->{$col}->{"autoincrement"} eq "true") {
         $str .= " auto_increment";
      }

      if($columns->{$col}->{"null"} && $columns->{$col}->{"null"} eq "false") {
         $str .= " NOT NULL"
      }

      if($columns->{$col}->{"default"}) {
         if($columns->{$col}->{"type"} =~ m/^(string|text|clob)/) {
            $str .= " DEFAULT '" . $columns->{$col}->{"default"} . "'";
         }
         else {
            $str .= " DEFAULT " . $columns->{$col}->{"default"};
         }
      }

      if($cols) {
         $cols .= ", " . $str;
      }
      else {
         $cols = $str;
      }
   }

   if(scalar(@primarys)) {
      $cols .= ", PRIMARY KEY(`" . join("`,`", @primarys) . "`)";
   }

   my $opts = "";
   if($options) {

      if($options->{"collate"}) {
         $opts .= " COLLATE " . $options->{"collate"};
      }

      if($options->{"charset"}) {
         $opts .= " CHARACTER SET " . $options->{"charset"};
      }

      if($options->{"type"}) {
         $opts .= " ENGINE " . $options->{"type"};
      }
   }

   return sprintf ($sql, $table, $cols, $opts);
}

sub get_dsn {
   my ($server, $database, $port) = @_;

   return "DBI:mysql:database=$database;host=$server;port=$port";
}

1;
