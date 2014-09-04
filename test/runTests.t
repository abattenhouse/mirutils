#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use Test::Class;

use Cwd 'abs_path'; use File::Basename 'dirname'; use lib abs_path(dirname(__FILE__)) . "/lib"; 
use TestMirObjects;

$|=1; # autoflush STDOUT

my @ALL_TEST_CLASSES = qw( MirObjects );

# Runs all Test::Class subclasses in use list
#Test::Class->runtests;

if ( @ARGV == 0) { 
   print STDERR "runTests.t [options] classToTest+\n\n";
   print STDERR "[options]:\n";
   print STDERR "  -skip Skip all tests with \$SKIP_ME 1 (all tests by default)\n\n";
   print STDERR "classToTest+ is one or more of:\n";
   print STDERR "  MirObjects\n";
   exit(1);  
}

my $skip  = 0;
while (@ARGV) {
   my $thing = shift(@ARGV);
   if ( $thing eq '-skip' ) { 
      $skip = 1;
   } else {
      unshift(@ARGV, $thing);
      last;
   }
}
$ENV{TEST_VERBOSE} = 1;

my %classHash = ();
my @testsToRun = ();
foreach (@ARGV) {
   if ( $_ eq 'All' ) {
      @testsToRun = @ALL_TEST_CLASSES;
      last;
   } else {
      push( @testsToRun, $_ ) if !$classHash{$_};
      $classHash{$_} = 1;
   }
}
#Test::Harness->runtests(@testsToRun); exit 0;

my $numSoFar = 0;
foreach my $tst (@testsToRun) {
   my $testClass = "Test$tst";
   print "--------------------------------------------\n";
   print "$testClass\n";
   print "--------------------------------------------\n";
   $testClass->setSkip($skip);
   $testClass->runtests();
   $numSoFar += $testClass->expected_tests();
   print "--------------------------------------------\n";
   print "$testClass complete\n";
}
print "--------------------------------------------\n";

exit(0);

####################################################################

0;


