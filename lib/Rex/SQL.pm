#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::SQL;

use strict;
use warnings;

our $VERSION = '0.3.99.4';

use YAML;
use DBI;
use Data::Dumper;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT $user $password $database $type $port);

@EXPORT = qw(sql sql_user sql_password sql_type sql_database sql_port);

$port = 3306;
$user = $ENV{"USER"};

sub sql_user {
   $user = shift;
}

sub sql_password {
   $password = shift;
}

sub sql_database {
   $database = shift;
}

sub sql_port {
   $port = shift;
}

sub sql_type {
   $type = shift;
   my $mod = "Rex::SQL::$type" . "::CREATE";
   eval "use $mod;";

   if($@) { Rex::Logger::info("Error, no SQL Module for $type found."); exit 2; }
}

sub sql {
   my ($type, $file) = @_; 

   Rex::Logger::debug("SQL: Type: $type");
   Rex::Logger::debug("SQL: file: $file");
   
   if($type eq "yaml") {
      unless(-f $file) {
         Rex::Logger::info("File: $file not found");
         exit 2;
      }

      my $content = Load(eval { local(@ARGV, $/) = ($file); <>;});

      my $server = Rex::get_current_connection();
      my $server_name = $server->{"server"};
      if($server_name eq "<local>") {
         $server_name = "localhost";
      }

      my $dsn = get_dsn($server_name, $database, $port);
      Rex::Logger::debug("Got dsn: $dsn");

      my $dbh = DBI->connect($dsn, $user, $password);

      unless($dbh) {
         Rex::Logger::info("No connection to database on " . $server_name);
         exit 2;
      }

      for my $table (keys %$content) {
      
         my $sql = get_create_sql($table, $content->{$table}->{"columns"}, $content->{$table}->{"options"});
         Rex::Logger::debug("Got SQL: $sql");

         eval { $dbh->do($sql); };

         if($@) {
            Rex::Logger::info("Error in SQL: $sql");
            exit 2;
         }
         
         $dbh->commit unless($dbh->{"AutoCommit"});

      }
   }
   else {
      Rex::Logger::info("Error, $type not supported.");
      exit 2;
   }
}

1;
