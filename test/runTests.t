#!/usr/bin/perl -w

my $ID_INFO = '$Id: runTests.t,v 1.37 2014/08/25 18:57:46 abattenhouse Exp $';

use strict;

use Getopt::Long;
use Test::Class;

use Cwd 'abs_path'; use File::Basename 'dirname'; use lib abs_path(dirname(__FILE__)) . "/lib"; 
use TestAssert;
use TestUtil;
use TestHistogram;
use TestSeqUtil;
use TestAnalysisUtil;
use TestAlignUtil;
use TestDBUtil;
use TestDBConn;
use TestBuildUtil;
use TestSample;
use TestSampleGroup;
use TestReadUtil;
use TestMirUtil;

use Cwd 'abs_path'; use File::Basename 'dirname'; use lib abs_path(dirname(__FILE__)) . "/lib"; 
use TestMirObjects;

$|=1; # autoflush STDOUT

my @ALL_TEST_CLASSES = qw( Assert Util SeqUtil 
                           Histogram AnalysisUtil AlignUtil ReadUtil
                           MirObjects MirUtil DBUtil DBConn BuildUtil 
                           Sample SampleGroup );

# Runs all Test::Class subclasses in use list
#Test::Class->runtests;

if ( @ARGV == 0) { 
   print STDERR "$ID_INFO\n";
   print STDERR "runTests.t [options] classToTest+\n";
   print STDERR "[options]:\n";
   print STDERR "  -skip Skip all tests with \$SKIP_ME 1 (all tests by default)\n";
   print STDERR "  -nodb Skip all DB tests (those with \$NO_DB 1)\n";
   print STDERR "classToTest+ is one or more of:\n";
   print STDERR "  All Assert Util SeqUtil Histogram AnalysisUtil AlignUtil ReadUtil\n";
   print STDERR "  MirUtil MirObjects DBUtil DBConn BuildUtil Sample SampleGroup\n";
   exit(1);  
}

my $quiet = 0;
my $skip  = 0;
my $nodb  = 0;
while (@ARGV) {
   my $thing = shift(@ARGV);
   if ( $thing eq '-q' ) { 
      $quiet = 1; 
   } elsif ( $thing eq '-skip' ) { 
      $skip = 1;
   } elsif ( $thing eq '-nodb' ) { 
      $nodb = 1;
   } else {
      unshift(@ARGV, $thing);
      last;
   }
}
$ENV{TEST_VERBOSE} = !$quiet;

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
   $testClass->setNodb($nodb);
   $testClass->runtests();
   $numSoFar += $testClass->expected_tests();
   print "--------------------------------------------\n";
   print "$testClass complete\n";
}
print "--------------------------------------------\n";

exit(0);

####################################################################

0;


