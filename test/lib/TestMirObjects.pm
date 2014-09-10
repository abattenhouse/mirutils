package TestMirObjects;

use strict;

use base qw(Test::Class);
use Test::More;
use Test::Exception;

use Cwd 'abs_path'; use File::Basename 'dirname'; use lib abs_path(dirname(__FILE__) . "/../..") . "/lib"; 
use MirInfo;
use MirStats;

#=====================================================================================

my $SKIP_ME = 0;
my $KEEP_FILES = 0;
my $SKIP_ME_MSG = "quick test";
sub setSkip {
   my ($class, $val) = @_;
   $SKIP_ME = defined($val) ? $val : 0;
   $KEEP_FILES = 1 if $SKIP_ME;
}
sub setKeepFiles {
   my ($class, $val) = @_;
   $KEEP_FILES = defined($val) ? $val : 0;
}

#-------------------------------------------------------------------

sub __testDataDir {
   my $dir = dirname(__FILE__); 
   return abs_path("$dir/../data");
}
sub __readTestFile {
   my ($file) = @_;
   my @lines = ();
   open (FILE, "< $file") || die "Can't open $file for input: $!";
   while (<FILE>) {
      push(@lines, $_);
   }
   close FILE;
   return @lines;
}

#=====================================================================================
# MirInfo general helper tests
#=====================================================================================

sub a01_openInputOutput: Test(22) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my @dirs  = ( '.', __testDataDir, __testDataDir . "/spaces dir" );
   my $fname = "ioTest.txt";
   my $data  = "some data\n";
   foreach (@dirs) {
      my $path = "$_/$fname"; 
      unlink($path);
      ok( ! -e $path,       "No file '$path'" );
      
      my $fh   = undef;
      lives_ok { $fh = MirInfo::openOutputSafely( $path ); } "  openOutputSafely lives";
      next unless $fh;

      print $fh $data; close($fh);
      ok( -e $path,         "  file now exists" );
      my @lines = __readTestFile($path);
      is( @lines, 1,        "  has 1 line" );

      $fh = undef; @lines = ();
      lives_ok { $fh = MirInfo::openInputSafely( $path ); } "  openInputSafely lives";
      next unless $fh;
      
      while (<$fh>) { push(@lines, $_);} close($fh);
      is( @lines, 1,        "  read 1 line" );
      is( $lines[0], $data, "  correct data" );

      unlink($path);
   }
   my $path = __testDataDir . "/spaces dir/spaces file";
   my $fh;
   lives_ok { $fh = MirInfo::openInputSafely( $path ); } "openInputSafely '$path' lives";
   close($fh) if $fh;
}
sub a10_chromCmp: Test(14) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   is( MirInfo::chromCmp( 'chr2',   'chr3' ),   -1,   "chr2  <  chr3" );
   is( MirInfo::chromCmp( 'chr9',   'chr8' ),    1,   "chr9  >  chr8" );
   is( MirInfo::chromCmp( 'chr5',   'chr5' ),    0,   "chr5  == chr5" );

   is( MirInfo::chromCmp( 'chr21',  'chr22' ),  -1,   "chr21 <  chr22" );
   is( MirInfo::chromCmp( 'chr94',  'chr93' ),   1,   "chr94 >  chr93" );
   is( MirInfo::chromCmp( 'chr57',  'chr57' ),   0,   "chr57 == chr57" );

   is( MirInfo::chromCmp( 'chr19',  'chr20' ),  -1,   "chr19 <  chr20" );
   is( MirInfo::chromCmp( 'chr2',   'chr20' ),  -1,   "chr2  <  chr20" );
   is( MirInfo::chromCmp( 'chr90',  'chr89' ),   1,   "chr90 >  chr89" );
   is( MirInfo::chromCmp( 'chr94',  'chr9' ),    1,   "chr94 >  chr9" );

   is( MirInfo::chromCmp( 'chrX',   'chrY' ),   -1,   "chrX  <  chrY" );
   is( MirInfo::chromCmp( 'chrP',   'chrM' ),    1,   "chrP  >  chrM" );
   is( MirInfo::chromCmp( 'chrAb',  'chrAb' ),   0,   "chrAb == chrAb" );

   is( MirInfo::chromCmp( 'chr11',  'chrM' ),   -1,   "chr11 <  chrM" );
}

#=====================================================================================
# MirInfo environment helper tests
#=====================================================================================

sub a50_MirInfo_globals : Test(3) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   is( $MirInfo::MIRBASE_VERSION,     'v21',      "MIRBASE_VERSION    v21" );
   is( $MirInfo::DEFAULT_ORGANISM,    'hsa',      "DEFAULT_ORGANISM   hsa" );
   is( $MirInfo::CLUSTER_DISTANCE,    10000,      "CLUSTER_DISTANCE 10000" );
}
sub a51_getMirbaseDir_noEnv : Test(8) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   $ENV{MIRBASE_ROOTDIR} = "";

   # default is v21
   diag( MirInfo::getMirbaseDir() );
   like( MirInfo::getMirbaseDir(),       qr/v21$/,    "getMirbaseDir() ~ v21" );
   like( MirInfo::getMirbaseDir('v19'),  qr/v19$/,    "getMirbaseDir(v19) ~ v19" );
   like( MirInfo::getMirbaseDir('v20'),  qr/v20$/,    "getMirbaseDir(v20) ~ v20" );
   like( MirInfo::getMirbaseDir('v21'),  qr/v21$/,    "getMirbaseDir(v21) ~ v21" );

   ok( -e MirInfo::getMirbaseDir(),      "getMirbaseDir() "    . MirInfo::getMirbaseDir()      . " exists" );
   ok( -e MirInfo::getMirbaseDir('v19'), "getMirbaseDir(v19) " . MirInfo::getMirbaseDir('v19') . " exists" );
   ok( -e MirInfo::getMirbaseDir('v20'), "getMirbaseDir(v20) " . MirInfo::getMirbaseDir('v20') . " exists" );
   ok( -e MirInfo::getMirbaseDir('v21'), "getMirbaseDir(v21) " . MirInfo::getMirbaseDir('v21') . " exists" );
}
sub a52_getMirbaseDir_withEnv : Test(4) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   $ENV{MIRBASE_ROOTDIR} = "../mirbase";

   # default is v21
   diag( MirInfo::getMirbaseDir() );
   ok( -e MirInfo::getMirbaseDir(),      "getMirbaseDir() "    . MirInfo::getMirbaseDir()      . " exists" );
   ok( -e MirInfo::getMirbaseDir('v19'), "getMirbaseDir(v19) " . MirInfo::getMirbaseDir('v19') . " exists" );
   ok( -e MirInfo::getMirbaseDir('v20'), "getMirbaseDir(v20) " . MirInfo::getMirbaseDir('v20') . " exists" );
   ok( -e MirInfo::getMirbaseDir('v21'), "getMirbaseDir(v21) " . MirInfo::getMirbaseDir('v21') . " exists" );
}
sub a53_getMirbaseGff : Test(21) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   $ENV{MIRBASE_ROOTDIR} = "";

   ok(-e MirInfo::getMirbaseGff('v19', 'hsa'),                    "getMirbaseGff(v19 hsa) exists" );
   like( MirInfo::getMirbaseGff('v19', 'hsa'),   qr/\/v19\//,     "getMirbaseGff(v19 hsa) ~ /v19/" );
   like( MirInfo::getMirbaseGff('v19', 'hsa'),   qr/hsa[.]gff3$/, "getMirbaseGff(v19 hsa) ~ hsa.gff3" );

   ok(-e MirInfo::getMirbaseGff('v20', 'hsa'),                    "getMirbaseGff(v20 hsa) exists" );
   like( MirInfo::getMirbaseGff('v20', 'hsa'),   qr/\/v20\//,     "getMirbaseGff(v20 hsa) ~ /v20/" );
   like( MirInfo::getMirbaseGff('v20', 'hsa'),   qr/hsa[.]gff3$/, "getMirbaseGff(v20 hsa) ~ hsa.gff3" );

   ok(-e MirInfo::getMirbaseGff('v21', 'hsa'),                    "getMirbaseGff(v21 hsa) exists" );
   like( MirInfo::getMirbaseGff('v21', 'hsa'),   qr/\/v21\//,     "getMirbaseGff(v21 hsa) ~ /v21/" );
   like( MirInfo::getMirbaseGff('v21', 'hsa'),   qr/hsa[.]gff3$/, "getMirbaseGff(v21 hsa) ~ hsa.gff3" );

   ok(-e MirInfo::getMirbaseGff('v19', 'mmu'),                    "getMirbaseGff(v19 mmu) exists" );
   like( MirInfo::getMirbaseGff('v19', 'mmu'),   qr/\/v19\//,     "getMirbaseGff(v19 mmu) ~ /v19/" );
   like( MirInfo::getMirbaseGff('v19', 'mmu'),   qr/mmu[.]gff3$/, "getMirbaseGff(v19 mmu) ~ mmu.gff3" );

   ok(-e MirInfo::getMirbaseGff('v20', 'mmu'),                    "getMirbaseGff(v20 mmu) exists" );
   like( MirInfo::getMirbaseGff('v20', 'mmu'),   qr/\/v20\//,     "getMirbaseGff(v20 mmu) ~ /v20/" );
   like( MirInfo::getMirbaseGff('v20', 'mmu'),   qr/mmu[.]gff3$/, "getMirbaseGff(v20 mmu) ~ mmu.gff3" );

   ok(-e MirInfo::getMirbaseGff('v21', 'mmu'),                    "getMirbaseGff(v21 mmu) exists" );
   like( MirInfo::getMirbaseGff('v21', 'mmu'),   qr/\/v21\//,     "getMirbaseGff(v21 mmu) ~ /v21/" );
   like( MirInfo::getMirbaseGff('v21', 'mmu'),   qr/mmu[.]gff3$/, "getMirbaseGff(v21 mmu) ~ mmu.gff3" );
   
   # default is v21, hsa
   ok(-e MirInfo::getMirbaseGff(),                                "getMirbaseGff() exists" );
   like( MirInfo::getMirbaseGff(),               qr/\/v21\//,     "getMirbaseGff() ~ /v21/" );
   like( MirInfo::getMirbaseGff(),               qr/hsa[.]gff3$/, "getMirbaseGff() ~ hsa.gff3" );
}
sub a54_getFamilyFile : Test(12) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   $ENV{MIRBASE_ROOTDIR} = "";

   ok( -e MirInfo::getFamilyFile('v19'), "getFamilyFile(v19) exists" );
   like( MirInfo::getFamilyFile('v19'),  qr/miFam[.]dat$/,  "getFamilyFile(v19) ~ mirFam.dat" );
   like( MirInfo::getFamilyFile('v19'),  qr/\/v19\//,       "getFamilyFile(v19) ~ /v19/" );

   ok( -e MirInfo::getFamilyFile('v20'), "getFamilyFile(v21) exists" );
   like( MirInfo::getFamilyFile('v20'),  qr/miFam[.]dat$/,  "getFamilyFile(v20) ~ mirFam.dat" );
   like( MirInfo::getFamilyFile('v20'),  qr/\/v20\//,       "getFamilyFile(v20) ~ /v20/" );

   ok( -e MirInfo::getFamilyFile('v21'), "getFamilyFile(v21) exists" );
   like( MirInfo::getFamilyFile('v21'),  qr/miFam[.]dat$/,  "getFamilyFile(v21) ~ mirFam.dat" );
   like( MirInfo::getFamilyFile('v21'),  qr/\/v21\//,       "getFamilyFile(v21) ~ /v21/" );

   # default is v21
   ok( -e MirInfo::getFamilyFile(),      "getFamilyFile() exists" );
   like( MirInfo::getFamilyFile(),       qr/miFam[.]dat$/,  "getFamilyFile() ~ mirFam.dat" );
   like( MirInfo::getFamilyFile(),       qr/\/v21\//,       "getFamilyFile() ~ /v21/" );
}
sub a55_getHairpinFa : Test(12) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   $ENV{MIRBASE_ROOTDIR} = "";

   ok(-e MirInfo::getHairpinFa('v19'),                      "getHairpinFa(v19) exists" );
   like( MirInfo::getHairpinFa('v19'),  qr/hairpin[.]fa$/,  "getHairpinFa(v19) ~ hairpin.fa" );
   like( MirInfo::getHairpinFa('v19'),  qr/\/v19\//,        "getHairpinFa(v19) ~ /v19/" );

   ok(-e MirInfo::getHairpinFa('v20'),                      "getHairpinFa(v21) exists" );
   like( MirInfo::getHairpinFa('v20'),  qr/hairpin[.]fa$/,  "getHairpinFa(v20) ~ hairpin.fa" );
   like( MirInfo::getHairpinFa('v20'),  qr/\/v20\//,        "getHairpinFa(v20) ~ /v20/" );

   ok(-e MirInfo::getHairpinFa('v21'),                      "getHairpinFa(v21) exists" );
   like( MirInfo::getHairpinFa('v21'),  qr/hairpin[.]fa$/,  "getHairpinFa(v21) ~ hairpin.fa" );
   like( MirInfo::getHairpinFa('v21'),  qr/\/v21\//,        "getHairpinFa(v21) ~ /v21/" );

   # default is v21
   ok(-e MirInfo::getHairpinFa(),                           "getHairpinFa() exists" );
   like( MirInfo::getHairpinFa(),       qr/hairpin[.]fa$/,  "getHairpinFa() ~ hairpin.fa" );
   like( MirInfo::getHairpinFa(),       qr/\/v21\//,        "getHairpinFa() ~ /v21/" );
}

#=====================================================================================
# MirInfo object tests
#=====================================================================================

# Use a gff of known composition (hsa v20)
my $MIR_INFO_V20;
sub getGffInfo {
   if (!$MIR_INFO_V20 || $SKIP_ME) {
      $MIR_INFO_V20 = MirInfo->newFromGff(version => 'v20', organism => 'hsa');
   }
   return $MIR_INFO_V20;
}
my $FULL_MIR_INFO_V20;
sub getGffInfoFull {
   if (!$FULL_MIR_INFO_V20) {
      $FULL_MIR_INFO_V20 = MirInfo->newFromGffFull(version => 'v20', organism => 'hsa');
   }
   return $FULL_MIR_INFO_V20;
}

sub b01_MirInfo_new : Test(23) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $gff   = MirInfo::getMirbaseGff();
   my $miFam = MirInfo::getFamilyFile();
   my $hpFa  = MirInfo::getHairpinFa();
   my $res   = MirInfo->new();
   ok( $res,                                 "MirInfo->new() ok" );
   isa_ok( $res, 'MirInfo',                  "  isa MirInfo" );
   is( $res->{version}, 'v21',               "  version v21" );
   is( $res->{organism}, 'hsa',              "  organism hsa" );
   is( $res->{clusterDist}, 10000,           "  clusterDist 10000" );
   is( $res->{gff}, $gff,                    "  gff   '$gff'" );
   is( $res->{miFam}, $miFam,                "  miFam '$miFam'" );
   is( $res->{hpFa}, $hpFa,                  "  hpFa  '$hpFa'" );
   is( $res->getObjects('hpid'), undef,      "  no hpid objects" );
   is( $res->getObjects('hairpin'), undef,   "  no hairpin objects" );
   is( $res->getObjects('mature'), undef,    "  no mature objects" );
   is( $res->getObjects('matseq'), undef,    "  no matseq objects" );
   is( $res->getObjects('group'), undef,     "  no group objects" );
   is( $res->getObjects('family'), undef,    "  no family objects" );
   is( $res->getObjects('byChrom'), undef,   "  no byChrom objects" );
   is( $res->getObjects('cluster'), undef,   "  no cluster objects" );
   is( $res->getObjects('cluster+'), undef,  "  no cluster+ objects" );
   is( $res->getObjects('cluster-'), undef,  "  no cluster- objects" );

   # checkFiles info
   is( $res->{mirbase}, 'v21',                        "  mirbase v21 " );
   is( $res->{date},    '2014-6-22',                  "  date    2014-6-22" );
   is( $res->{build},   'GRCh38',                     "  build   GRCh38" );
   is( $res->{species}, 'Homo sapiens',               "  species Homo sapiens" );
   is( $res->{acc}, 'NCBI_Assembly:GCA_000001405.15', "  acc     NCBI_Assembly:GCA_000001405.15" );
}
sub b02_MirInfo_new_params : Test(13) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $gff   = MirInfo::getMirbaseGff('v20', 'mmu');
   my $miFam = MirInfo::getFamilyFile('v20');
   my $hpFa  = MirInfo::getHairpinFa('v20');
   my $res   = MirInfo->new(version => 'v20', organism => 'mmu', clusterDist => 50000);
   ok( $res,                                "MirInfo->new(version => 'v20', organism => 'mmu', clusterDist => 50000) ok" );
   isa_ok( $res, 'MirInfo',                 "  isa MirInfo" );
   is( $res->{version}, 'v20',              "  version v20" );
   is( $res->{organism}, 'mmu',             "  organism mmu" );
   is( $res->{clusterDist}, 50000,          "  clusterDist 50000" );
   is( $res->{gff}, $gff,                   "  gff   '$gff'" );
   is( $res->{miFam}, $miFam,               "  miFam '$miFam'" );
   is( $res->{hpFa}, $hpFa,                 "  hpFa  '$hpFa'" );

   # checkFiles info
   is( $res->{mirbase}, 'v20',                        "  mirbase v20 " );
   is( $res->{date},    '2013-10-1',                  "  date    date 2013-10-1" );
   is( $res->{build},   'GRCm38',                     "  build   GRCm38" );
   is( $res->{species}, 'Mus musculus',               "  species Mus musculus" );
   is( $res->{acc}, 'NCBI_Assembly:GCA_000001635.2',  "  acc     NCBI_Assembly:GCA_000001635.2" );
}

sub b10_MirInfo_newFromGff : Test(21) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfo(); 
   ok( $res,                                  "getGffInfo ok" );
   diag($res->toString());
   isa_ok( $res, 'MirInfo',                   "  isa MirInfo" );
   
   my ($nLine, $nEntry, $nHpId, $nHpin, $nMat, $nMatseq, $nUqHp, $nDupHp, $nGrp, $nMGrp, $nFam);
   $nLine   = $res->{stats}->{nLine};
   $nEntry  = $res->{stats}->{nEntry};
   $nMat    = $res->{stats}->{nMature};
   $nMatseq = $res->{stats}->{nMatseq};
   $nHpId   = $res->{stats}->{nHpId};
   $nHpin   = $res->{stats}->{nHairpin};
   $nDupHp  = $res->{stats}->{nDupHpin};
   $nGrp    = $res->{stats}->{nGroup};
   $nMGrp   = $res->{stats}->{nMultiGrp};
   $nFam    = $res->{stats}->{nFamily};
   is( $nLine,   4678,                        "  has 4678 lines" );
   is( $nHpId,   1871,                        "  has 1871 hpid miRNAs" );
   is( $nMat,    2794,                        "  has 2794 mature miRNA loci" );
   is( $nMatseq, 2576,                        "  has 2576 mature miRNA sequences" );
   is( $nEntry,  4665,                        "  has 4665 entries" );
   is( $nDupHp,     1,                        "  has    1 duplicate hairpin name" );
   is( $nHpin,   1870,                        "  has 1870 hairpin names" );
   is( $nGrp,    1702,                        "  has 1702 miRNA groups" );
   is( $nFam,       0,                        "  has    0 miRNA families" );
   is( $res->getObjects('hpid'),    $nHpId,   "  has $nHpId hpid objects" );
   is( $res->getObjects('hairpin'), $nHpin,   "  has $nHpin hairpin objects" );
   is( $res->getObjects('mature'),  $nMat,    "  has $nMat mature objects" );
   is( $res->getObjects('matseq'),  $nMatseq, "  has $nMatseq mature sequence objects" );
   is( $res->getObjects('group'),   $nGrp,    "  has $nGrp group objects" );
   is( $res->getObjects('byChrom'), 24,       "  has 24 byChrom objects" );
   is( $res->getObjects('family'),   undef,   "  no family objects" );
   is( $res->getObjects('cluster'),  undef,   "  no cluster objects" );
   is( $res->getObjects('cluster+'), undef,   "  no cluster+ objects" );
   is( $res->getObjects('cluster-'), undef,   "  no cluster- objects" );
}

sub b21_MirInfo_base_obj : Test(42) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfo();
   ok( $res,                                 "getGffInfo() ok" );

   # chr9  hairpin  96938239  96938318 + ID=MI0000060;Alias=MI0000060;Name=hsa-let-7a-1
   # chr9  mature   96938244  96938265 + ID=MIMAT0000062_2;Alias=MIMAT0000062;Name=hsa-let-7a-5p;Derives_from=MI0000060
   # chr9  mature   96938295  96938315 + ID=MIMAT0004481_1;Alias=MIMAT0004481;Name=hsa-let-7a-3p;Derives_from=MI0000060
   my $hp = $res->{hairpin}->{'hsa-let-7a-1'};
   ok( $hp,                                  "hsa-let-7a-1 hairpin" );
   isa_ok( $res, 'MirInfo',                  "  isa MirInfo" );
   is( $hp->{name},     'hsa-let-7a-1',      "  name   hsa-let-7a-1" );
   is( $hp->{alias},    'MI0000060',         "  alias  MI0000060" );
   is( $hp->{type},     'hairpin',           "  type   hairpin" );
   is( $hp->{chr},      'chr9',              "  chr    chr9" );
   is( $hp->{start},    96938239,            "  start  96938239" );
   is( $hp->{end},      96938318,            "  end    96938318" );
   is( $hp->{strand},   '+',                 "  strand +" );
   is( $hp->{parent},   undef,               "  parent undef" );
   is( $hp->{nextCopy}, undef,               "  nextCopy undef" );

   my $refCh = $hp->{children};
   my $id    = $hp->{id};
   my $hpId  = $res->{hpid}->{$id};
   is( $id, 'MI0000060',                     "  id MI0000060" );
   is( $hpId, $hp,                           "  byId obj eq byName obj" );
   is( ref($refCh), 'ARRAY',                 "  children ARRAY ref" );
   is( @$refCh, 2,                           "  has 2 children" );

   my $ch = @$refCh[0];
   is( ref($ch),        'HASH',              "  child 1 HASH ref" );
   is( $ch->{name},     'hsa-let-7a-5p',     "    name     hsa-let-7a-5p" );
   is( $ch->{id},       'MIMAT0000062_2',    "    id       MIMAT0000062_2" );
   is( $ch->{alias},    'MIMAT0000062',      "    alias    MIMAT0000062" );
   is( $ch->{type},     'mature',            "    type     mature" );
   is( $ch->{chr},      'chr9',              "    chr      chr9" );
   is( $ch->{start},    96938244,            "    start    96938244" );
   is( $ch->{end},      96938265,            "    end      96938265" );
   is( $ch->{strand},   '+',                 "    strand   +" );
   is( $ch->{parent},   'MI0000060',         "    parent   MI0000060" );
   is( $ch->{pobj},     $hp,                 "    parent   obj is hairpin" );
   is( $ch->{startPos}, 96938244-96938239+1, "    startPos " . (96938244-96938239+1) );
   is( $ch->{endPos},   96938265-96938239+1, "    endPos   " . (96938265-96938239+1) );

   $ch = @$refCh[1];
   is( ref($ch),        'HASH',              "  child 2 HASH ref" );
   is( $ch->{name},     'hsa-let-7a-3p',     "    name     hsa-let-7a-3p" );
   is( $ch->{id},       'MIMAT0004481_1',    "    id       MIMAT0004481_1" );
   is( $ch->{alias},    'MIMAT0004481',      "    alias    MIMAT0004481" );
   is( $ch->{type},     'mature',            "    type     mature" );
   is( $ch->{chr},      'chr9',              "    chr      chr9" );
   is( $ch->{start},    96938295,            "    start    96938295" );
   is( $ch->{end},      96938315,            "    end      96938315" );
   is( $ch->{strand},   '+',                 "    strand   +" );
   is( $ch->{parent},   'MI0000060',         "    parent   MI0000060" );
   is( $ch->{pobj},     $hp,                 "    parent   obj is hairpin" );
   is( $ch->{startPos}, 96938295-96938239+1, "    startPos " . (96938295-96938239+1) );
   is( $ch->{endPos},   96938315-96938239+1, "    endPos   " . (96938315-96938239+1) );
}

sub b22_MirInfo_mature_5or3 : Test(101) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfo();
   ok( $res,                                   "getGffInfo() ok" );
   return "error" if !$res;

   # hsa-let-7a has both 5p and 3p mature miRs
   #   chr9  hairpin  96938239  96938318 + ID=MI0000060;Alias=MI0000060;Name=hsa-let-7a-1
   #   chr9  mature   96938244  96938265 + ID=MIMAT0000062_2;Alias=MIMAT0000062;Name=hsa-let-7a-5p;Derives_from=MI0000060
   #   chr9  mature   96938295  96938315 + ID=MIMAT0004481_1;Alias=MIMAT0004481;Name=hsa-let-7a-3p;Derives_from=MI0000060
   my $p5 = $res->{mature}->{'MIMAT0000062_2'};
   ok( $p5,                                    "MIMAT0000062_2 mature" );
   is( $p5->{name},     'hsa-let-7a-5p',       "  name     hsa-let-7a-5p" );
   is( $p5->{chr},      'chr9',                "  chr      chr9" );
   is( $p5->{start},    96938244,              "  start    96938244" );
   is( $p5->{end},      96938265,              "  end      96938265" );
   is( $p5->{strand},   '+',                   "  strand   +" );
   is( $p5->{p5or3},    '5p',                  "  p5or3    5p" );
   is( $p5->{startPos},  96938244-96938239+1,  "  startPos " . (96938244-96938239+1) );
   is( $p5->{endPos},    96938265-96938239+1,  "  endPos   " . (96938265-96938239+1) );
   is( $p5->{dname},    'hsa-let-7a-1(hsa-let-7a-5p)',     "  dname    hsa-let-7a-1(hsa-let-7a-5p)" );
   my $p3 = $res->{mature}->{'MIMAT0004481_1'};
   ok( $p3,                                    "MIMAT0004481_1 mature" );
   is( $p3->{name},     'hsa-let-7a-3p',       "  name     hsa-let-7a-3p" );
   is( $p3->{chr},      'chr9',                "  chr      chr9" );
   is( $p3->{start},    96938295,              "  start    96938295" );
   is( $p3->{end},      96938315,              "  end      96938315" );
   is( $p3->{strand},   '+',                   "  strand   +" );
   is( $p3->{p5or3},    '3p',                  "  p5or3    3p" );
   is( $p3->{startPos},  96938295-96938239+1,  "  startPos " . (96938295-96938239+1) );
   is( $p3->{endPos},    96938315-96938239+1,  "  endPos   " . (96938315-96938239+1) );
   is( $p3->{dname},    'hsa-let-7a-1(hsa-let-7a-3p)',     "  dname    hsa-let-7a-1(hsa-let-7a-3p)" ); 
   
   my $hp = $res->{hairpin}->{'hsa-let-7a-1'};
   ok( $hp,                                    "hsa-let-7a-1 hairpin" );
   is( $hp->{name},     'hsa-let-7a-1',        "  name    hsa-let-7a-1" );
   is( $hp->{chr},      'chr9',                "  chr     chr9" );
   is( $hp->{start},    96938239,              "  start   96938239" );
   is( $hp->{end},      96938318,              "  end     96938318" );
   is( $hp->{strand},   '+',                   "  strand  +" );
   is( $hp->{'5p'},     $p5,                   "  correct 5p mature miR" );
   is( $hp->{'3p'},     $p3,                   "  correct 3p mature miR" );   

   # hsa-mir-3658 has only 5p mature miR  (+ strand)
   # chr1 hairpin 165877158 165877213 + ID=MI0016058;Alias=MI0016058;Name=hsa-mir-3658
   # chr1 mature  165877160 165877181 + ID=MIMAT0018078;Alias=MIMAT0018078;Name=hsa-miR-3658;Derives_from=MI0016058
   $p5 = $res->{mature}->{'MIMAT0018078'};
   $p3 = undef;
   ok( $p5,                                    "MIMAT0018078 mature" );
   is( $p5->{name},     'hsa-miR-3658',        "  name     hsa-miR-3658" );
   is( $p5->{chr},      'chr1',                "  chr      chr1" );
   is( $p5->{start},    165877160,             "  start    165877160" );
   is( $p5->{end},      165877181,             "  end      165877181" );
   is( $p5->{strand},   '+',                   "  strand   +" );
   is( $p5->{p5or3},    '5p',                  "  p5or3    5p" );
   is( $p5->{startPos}, 165877160-165877158+1, "  startPos " . (165877160-165877158+1) );
   is( $p5->{endPos},   165877181-165877158+1, "  endPos   " . (165877181-165877158+1) );
   is( $p5->{dname},    'hsa-mir-3658(hsa-miR-3658(5p))',  "  dname    hsa-mir-3658(hsa-miR-3658(5p))" );
  
   $hp = $res->{hairpin}->{'hsa-mir-3658'};
   ok( $hp,                                    "hsa-mir-3658 hairpin" );
   is( $hp->{name},     'hsa-mir-3658',        "  name    hsa-mir-3658" );
   is( $hp->{chr},      'chr1',                "  chr     chr1" );
   is( $hp->{start},    165877158,             "  start   165877158" );
   is( $hp->{end},      165877213,             "  end     165877213" );
   is( $hp->{strand},   '+',                   "  strand  +" );
   is( $hp->{'5p'},     $p5,                   "  correct 5p mature miR" );
   ok(!$hp->{'3p'},                            "  no      3p mature miR" ); 

   # hsa-mir-521-1 has only 3p mature miR  (+ strand)
   #   chr19 hairpin 54251890 54251976 + ID=MI0003176;Alias=MI0003176;Name=hsa-mir-521-1
   #   chr19 mature  54251943 54251964 + ID=MIMAT0002854_1;Alias=MIMAT0002854;Name=hsa-miR-521;Derives_from=MI0003176
   $p3 = $res->{mature}->{'MIMAT0002854_1'};
   $p5 = undef;
   ok( $p3,                                    "MIMAT0002854_1 mature" );
   is( $p3->{name},     'hsa-miR-521',         "  name     hsa-miR-521" );
   is( $p3->{chr},      'chr19',               "  chr      chr19" );
   is( $p3->{start},    54251943,              "  start    54251943" );
   is( $p3->{end},      54251964,              "  end      54251964" );
   is( $p3->{strand},   '+',                   "  strand   +" );
   is( $p3->{p5or3},    '3p',                  "  p5or3    3p" );
   is( $p3->{startPos},  54251943-54251890+1,  "  startPos " . (54251943-54251890+1) );
   is( $p3->{endPos},    54251964-54251890+1,  "  endPos   " . (54251964-54251890+1) );
   is( $p3->{dname},    'hsa-mir-521-1(hsa-miR-521(3p))',  "  dname    hsa-mir-521-1(hsa-miR-521(3p))" ); 
  
   $hp = $res->{hairpin}->{'hsa-mir-521-1'};
   ok( $hp,                                    "hsa-mir-521-1 hairpin" );
   is( $hp->{name},     'hsa-mir-521-1',       "  name    hsa-mir-521-1" );
   is( $hp->{chr},      'chr19',               "  chr     chr19" );
   is( $hp->{start},    54251890,              "  start   54251890" );
   is( $hp->{end},      54251976,              "  end     54251976" );
   is( $hp->{strand},   '+',                   "  strand  +" );
   ok(!$hp->{'5p'},                            "  no      5p mature miR" );
   is( $hp->{'3p'},     $p3,                   "  correct 3p mature miR" );

   # hsa-mir-217 has only 5p mature miR  (- strand)
   #   chr2 hairpin 56210102 56210211 - ID=MI0000293;Alias=MI0000293;Name=hsa-mir-217
   #   chr2 mature  56210155 56210177 - ID=MIMAT0000274;Alias=MIMAT0000274;Name=hsa-miR-217;Derives_from=MI0000293
   $p5 = $res->{mature}->{'MIMAT0000274'};
   $p3 = undef;
   ok( $p5,                                    "MIMAT0000274 mature" );
   is( $p5->{name},     'hsa-miR-217',         "  name     hsa-miR-217" );
   is( $p5->{chr},      'chr2',                "  chr      chr2" );
   is( $p5->{start},    56210155,              "  start    56210155" );
   is( $p5->{end},      56210177,              "  end      56210177" );
   is( $p5->{strand},   '-',                   "  strand   -" );
   is( $p5->{p5or3},    '5p',                  "  p5or3    5p" );
   is( $p5->{startPos},  56210211-56210177+1,  "  startPos " . (56210211-56210177+1) );
   is( $p5->{endPos},    56210211-56210155+1,  "  endPos   " . (56210211-56210155+1) );
   is( $p5->{dname},    'hsa-mir-217(hsa-miR-217(5p))',    "  dname    hsa-mir-217(hsa-miR-217(5p))" );  
  
   $hp = $res->{hairpin}->{'hsa-mir-217'};
   ok( $hp,                                    "hsa-mir-217 hairpin" );
   is( $hp->{name},     'hsa-mir-217',         "  name    hsa-mir-217" );
   is( $hp->{chr},      'chr2',                "  chr     chr2" );
   is( $hp->{start},    56210102,              "  start   56210102" );
   is( $hp->{end},      56210211,              "  end     56210211" );
   is( $hp->{strand},   '-',                   "  strand  -" );
   is( $hp->{'5p'},     $p5,                   "  correct 5p mature miR" );
   ok(!$hp->{'3p'},                            "  no      3p mature miR" );

   # hsa-mir-1-2 has only 3p mature miR  (- strand)
   #   chr18 hairpin  19408965 19409049 - ID=MI0000437;Alias=MI0000437;Name=hsa-mir-1-2
   #   chr18 mature   19408976 19408997 - ID=MIMAT0000416;Alias=MIMAT0000416;Name=hsa-miR-1;Derives_from=MI0000437
   $p3 = $res->{mature}->{'MIMAT0000416'};
   $p5 = undef;
   ok( $p3,                                    "MIMAT0000416 mature" );
   is( $p3->{name},     'hsa-miR-1',           "  name     hsa-miR-1" );
   is( $p3->{chr},      'chr18',               "  chr      chr18" );
   is( $p3->{start},    19408976,              "  start    19408976" );
   is( $p3->{end},      19408997,              "  end      19408997" );
   is( $p3->{strand},   '-',                   "  strand   -" );
   is( $p3->{p5or3},    '3p',                  "  p5or3    3p" );
   is( $p3->{startPos},  19409049-19408997+1,  "  startPos " . (19409049-19408997+1) );
   is( $p3->{endPos},    19409049-19408976+1,  "  endPos   " . (19409049-19408976+1) );
   is( $p3->{dname},    'hsa-mir-1-2(hsa-miR-1(3p))',      "  dname    hsa-mir-1-2(hsa-miR-1(3p))" );
  
   $hp = $res->{hairpin}->{'hsa-mir-1-2'};
   ok( $hp,                                    "hsa-mir-1-1 hairpin" );
   is( $hp->{name},     'hsa-mir-1-2',         "  name    hsa-mir-1-2" );
   is( $hp->{chr},      'chr18',               "  chr     chr18" );
   is( $hp->{start},    19408965,              "  start   61151513" );
   is( $hp->{end},      19409049,              "  end     61151583" );
   is( $hp->{strand},   '-',                   "  strand  -" );
   ok(!$hp->{'5p'},                            "  no      5p mature miR" );
   is( $hp->{'3p'},     $p3,                   "  correct 3p mature miR" );
}
sub b23_MirInfo_mirs: Test(24) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfo();
   ok( $res,                                "getGffInfo() ok" );

   ok( $res->{hairpin}->{'hsa-let-7a-1'},   "  hsa-let-7a-1   hairpin found" );
   ok( $res->{hairpin}->{'hsa-let-7a-2'},   "  hsa-let-7a-2   hairpin found" );
   ok( $res->{hairpin}->{'hsa-let-7a-3'},   "  hsa-let-7a-3   hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-1-1'},    "  hsa-mir-1-1    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-105-1'},  "  hsa-mir-105-1  hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-105-2'},  "  hsa-mir-105-2  hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-1254-2'}, "  hsa-mir-1254-2 hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-149'},    "  hsa-mir-149    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-192'},    "  hsa-mir-192    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-196a-1'}, "  hsa-mir-196a-1 hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-21'},     "  hsa-mir-21     hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-22'},     "  hsa-mir-22     hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-27b'},    "  hsa-mir-27b    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-3198-1'}, "  hsa-mir-3198-1 hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-504'},    "  hsa-mir-504    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-511'},    "  hsa-mir-511    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-598'},    "  hsa-mir-598    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-5683'},   "  hsa-mir-5683   hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-636'},    "  hsa-mir-636    hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-6083'},   "  hsa-mir-6083   hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-6807'},   "  hsa-mir-6807   hairpin found" );
   ok( $res->{hairpin}->{'hsa-mir-7-1'},    "  hsa-mir-7-1    hairpin found" );

   ok( !$res->{hairpin}->{'hsa-mir-1273e'}, "  hsa-mir-1273e  hairpin NOT found" );
}

# hsa-mir-511 is the one example of a duplicate hairpin name in mirbase v20 (but not in v21):
#   chr10 hairpin 17887107 17887193 + ID=MI0003127;Alias=MI0003127;Name=hsa-mir-511
#   chr10 mature  17887122 17887142 + ID=MIMAT0002808;Alias=MIMAT0002808;Name=hsa-miR-511-5p;Derives_from=MI0003127
#   chr10 mature  17887160 17887179 + ID=MIMAT0026606;Alias=MIMAT0026606;Name=hsa-miR-511-3p;Derives_from=MI0003127
#   chr10 hairpin 18134036 18134122 + ID=MI0003127_2;Alias=MI0003127;Name=hsa-mir-511
#   chr10 mature  18134051 18134071 + ID=MIMAT0002808_1;Alias=MIMAT0002808;Name=hsa-miR-511-5p;Derives_from=MI0003127
#   chr10 mature  18134089 18134108 + ID=MIMAT0026606_1;Alias=MIMAT0026606;Name=hsa-miR-511-3p;Derives_from=MI0003127
# Note: Even though all 4 mature miRNAs have Derives_from=MI0003127 in the GFF,
#   we assign MIMAT0002808_1 and MIMAT0026606_1 to hairpin MI0003127_2
sub b24_MirInfo_dupHp : Test(67) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $res = getGffInfo();
   ok( $res,                               "getGffInfo() ok" );
   
   # 1st of 2 hsa-mir-511 dups
   my $hp1 = $res->{hpid}->{'MI0003127'};
   is( ref($hp1),      'HASH',             "hpid MI0003127" );
   is( $hp1->{name},     'hsa-mir-511',    "  name   hsa-mir-511" );
   is( $hp1->{id},       'MI0003127',      "  id     MI0003127" );
   is( $hp1->{alias},    'MI0003127',      "  alias  MI0003127" );
   is( $hp1->{type},     'hairpin',        "  type   hairpin" );
   is( $hp1->{chr},      'chr10',          "  chr    chr10" );
   is( $hp1->{start},    17887107,         "  start  17887107" );
   is( $hp1->{end},      17887193,         "  end    17887193" );
   is( $hp1->{strand},   '+',              "  strand +" );
   my $hp2 = $hp1->{nextCopy};
   is( ref($hp2),        'HASH',           "  nexCopy HASH" );

   my $refCh = $hp1->{children};
   is( ref($refCh), 'ARRAY',               "MI0003127 children ARRAY ref" );
   is( @$refCh, 2,                         "  has 2 children" );

   my $ch = @$refCh[0];
   is( ref($ch),        'HASH',            "MI0003127 child 1 HASH ref" );
   is( $ch->{name},     'hsa-miR-511-5p',  "    name   hsa-miR-511-5p" );
   is( $ch->{id},       'MIMAT0002808',    "    id     MIMAT0002808" );
   is( $ch->{alias},    'MIMAT0002808',    "    alias  MIMAT0002808" );
   is( $ch->{type},     'mature',          "    type   mature" );
   is( $ch->{chr},      'chr10',           "    chr    chr10" );
   is( $ch->{start},    17887122,          "    start  17887122" );
   is( $ch->{end},      17887142,          "    end    17887142" );
   is( $ch->{strand},   '+',               "    strand +" );
   is( $ch->{parent},   'MI0003127',       "    parent MI0003127" );
   is( $ch->{pobj},     $hp1,              "    parent obj correct" );

   $ch = @$refCh[1];
   is( ref($ch),        'HASH',            "MI0003127 child 2 HASH ref" );
   is( $ch->{name},     'hsa-miR-511-3p',  "    name   hsa-miR-511-3p" );
   is( $ch->{id},       'MIMAT0026606',    "    id     MIMAT0026606" );
   is( $ch->{alias},    'MIMAT0026606',    "    alias  MIMAT0026606" );
   is( $ch->{type},     'mature',          "    type   mature" );
   is( $ch->{chr},      'chr10',           "    chr    chr10" );
   is( $ch->{start},    17887160,          "    start  17887160" );
   is( $ch->{end},      17887179,          "    end    17887179" );
   is( $ch->{strand},   '+',               "    strand +" );
   is( $ch->{parent},   'MI0003127',       "    parent MI0003127" );
   is( $ch->{pobj},     $hp1,              "    parent obj correct" );

   # 2nd of 2 hsa-mir-511 dups
   is( $hp2->{id},       'MI0003127_2',    "hpid MI0003127_2" );
   is( $hp2->{alias},    'MI0003127',      "  alias  MI0003127" );
   is( $hp2->{name},     'hsa-mir-511',    "  name   hsa-mir-511" );
   is( $hp2->{type},     'hairpin',        "  type   hairpin" );
   is( $hp2->{chr},      'chr10',          "  chr    chr10" );
   is( $hp2->{start},    18134036,         "  start  18134036" );
   is( $hp2->{end},      18134122,         "  end    18134122" );
   is( $hp2->{strand},   '+',              "  strand +" );

   $refCh = $hp2->{children};
   is( ref($refCh), 'ARRAY',               "MI0003127_2 children ARRAY ref" );
   is( @$refCh, 2,                         "  has 2 children" );
   
   $ch = @$refCh[0];
   is( ref($ch),        'HASH',            "MI0003127_2 child 1 HASH ref" );
   is( $ch->{name},     'hsa-miR-511-5p',  "    name   hsa-miR-511-5p" );
   is( $ch->{id},       'MIMAT0002808_1',  "    id     MIMAT0002808_1" );
   is( $ch->{alias},    'MIMAT0002808',    "    alias  MIMAT0002808" );
   is( $ch->{type},     'mature',          "    type   mature" );
   is( $ch->{chr},      'chr10',           "    chr    chr10" );
   is( $ch->{start},    18134051,          "    start  18134051" );
   is( $ch->{end},      18134071,          "    end    18134071" );
   is( $ch->{strand},   '+',               "    strand +" );
   is( $ch->{parent},   'MI0003127_2',     "    parent MI0003127_2" );
   is( $ch->{pobj},     $hp2,              "    parent obj correct" );

   $ch = @$refCh[1];
   is( ref($ch),        'HASH',            "MI0003127_2 child 2 HASH ref" );
   is( $ch->{name},     'hsa-miR-511-3p',  "    name   hsa-miR-511-3p" );
   is( $ch->{id},       'MIMAT0026606_1',  "    id     MIMAT0026606_1" );
   is( $ch->{alias},    'MIMAT0026606',    "    alias  MIMAT0026606" );
   is( $ch->{type},     'mature',          "    type   mature" );
   is( $ch->{chr},      'chr10',           "    chr    chr10" );
   is( $ch->{start},    18134089,          "    start  18134089" );
   is( $ch->{end},      18134108,          "    end    18134108" );
   is( $ch->{strand},   '+',               "    strand +" );
   is( $ch->{parent},   'MI0003127_2',     "    parent MI0003127_2" );
   is( $ch->{pobj},     $hp2,              "    parent obj correct" );
}

sub b25_MirInfo_matseq : Test(40) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $res = getGffInfo();
   ok( $res,                                     "getGffInfo() ok" );

   # hsa-mir-7
   # chr15   hairpin 89155056  89155165 + ID=MI0000264;Alias=MI0000264;Name=hsa-mir-7-2
   # chr15   mature  89155087  89155109 + ID=MIMAT0000252;Alias=MIMAT0000252;Name=hsa-miR-7-5p;Derives_from=MI0000264
   # chr15   mature  89155127  89155148 + ID=MIMAT0004554;Alias=MIMAT0004554;Name=hsa-miR-7-2-3p;Derives_from=MI0000264
   # chr19   hairpin 4770682   4770791  + ID=MI0000265;Alias=MI0000265;Name=hsa-mir-7-3
   # chr19   mature  4770712   4770734  + ID=MIMAT0000252_1;Alias=MIMAT0000252;Name=hsa-miR-7-5p;Derives_from=MI0000265
   # chr9    hairpin 86584663  86584772 - ID=MI0000263;Alias=MI0000263;Name=hsa-mir-7-1
   # chr9    mature  86584727  86584749 - ID=MIMAT0000252_2;Alias=MIMAT0000252;Name=hsa-miR-7-5p;Derives_from=MI0000263
   # chr9    mature  86584686  86584707 - ID=MIMAT0004553;Alias=MIMAT0004553;Name=hsa-miR-7-1-3p;Derives_from=MI0000263         
   my $ms = $res->{matseq}->{'MIMAT0004554'};
   is( ref($ms),          'HASH',                "matseq MIMAT0004554" );
   is( $ms->{type},       'matseq',              "  type   matseq" );
   is( $ms->{id},         'MIMAT0004554',        "  id     MIMAT0004554" );
   is( $ms->{name},       'hsa-miR-7-2-3p',      "  name   hsa-miR-7-2-3p" );
   is( $ms->{dname},      'hsa-miR-7-2-3p[1]',   "  dname  hsa-miR-7-5p[1]" );
   is( $ms->{numCh},       1,                    "  numCh  1" );
   is( @{$ms->{children}}, 1,                    "  children 1" );

   my $mir = $res->{mature}->{'MIMAT0004554'};
   is( ref($mir),         'HASH',                "  mature MIMAT0004554" );
   is( $mir->{type},      'mature',              "    type   mature" );
   is( $mir->{id},        'MIMAT0004554',        "    id     MIMAT0004554" );
   is( $mir->{alias},     'MIMAT0004554',        "    alias  MIMAT0004554" );
   is( $mir->{name},      'hsa-miR-7-2-3p',      "    name   hsa-miR-7-2-3p" );
   is( $mir->{matseqObj}, $ms,                   "    matseqObj correct" );
   ok(!$res->{mature}->{'MIMAT0004554_1'},       "  no mature MIMAT0004554_1" );

   # matseq w/multiple mature loci
   $ms = $res->{matseq}->{'MIMAT0000252'};
   is( ref($ms),          'HASH',                "matseq MIMAT0000252" );
   is( $ms->{type},       'matseq',              "  type   matseq" );
   is( $ms->{id},         'MIMAT0000252',        "  id     MIMAT0000252" );
   is( $ms->{name},       'hsa-miR-7-5p',        "  name   hsa-miR-7-5p" );
   is( $ms->{dname},      'hsa-miR-7-5p[3]',     "  dname  hsa-miR-7-5p[3]" );
   is( $ms->{numCh},       3,                    "  numCh  3" );
   is( @{$ms->{children}}, 3,                    "  children 3" );

   $mir = $res->{mature}->{'MIMAT0000252'};
   is( ref($mir),         'HASH',                "  mature MIMAT0000252" );
   is( $mir->{type},      'mature',              "    type   mature" );
   is( $mir->{id},        'MIMAT0000252',        "    id     MIMAT0000252" );
   is( $mir->{alias},     'MIMAT0000252',        "    alias  MIMAT0000252" );
   is( $mir->{name},      'hsa-miR-7-5p',        "    name   hsa-miR-7-5p" );
   is( $mir->{matseqObj}, $ms,                   "    matseqObj correct" );

   $mir = $res->{mature}->{'MIMAT0000252_1'};
   is( ref($mir),         'HASH',                "  mature MIMAT0000252_1" );
   is( $mir->{type},      'mature',              "    type   mature" );
   is( $mir->{id},        'MIMAT0000252_1',      "    id     MIMAT0000252_1" );
   is( $mir->{alias},     'MIMAT0000252',        "    alias  MIMAT0000252" );
   is( $mir->{name},      'hsa-miR-7-5p',        "    name   hsa-miR-7-5p" );
   is( $mir->{matseqObj}, $ms,                   "    matseqObj correct" );

   $mir = $res->{mature}->{'MIMAT0000252_2'};
   is( ref($mir),         'HASH',                "  mature MIMAT0000252_2" );
   is( $mir->{type},      'mature',              "    type   mature" );
   is( $mir->{id},        'MIMAT0000252_2',      "    id     MIMAT0000252_2" );
   is( $mir->{alias},     'MIMAT0000252',        "    alias  MIMAT0000252" );
   is( $mir->{name},      'hsa-miR-7-5p',        "    name   hsa-miR-7-5p" );
   is( $mir->{matseqObj}, $ms,                   "    matseqObj correct" );
}

sub b31_MirInfo_groups_1 : Test(20) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $res = getGffInfo();
   ok( $res,                               "getGffInfo() ok" );

   my $nHpin = $res->{stats}->{nHairpin};
   my $nGrp  = $res->{stats}->{nGroup};
   my $nMult = $res->{stats}->{nMultiGrp};
   is( $nGrp,  1702,                       "  has 1702 hairpin groups" );
   is( $nMult,  125,                       "  has  125 multi-memeber groups" );
   is( $res->getObjects('group'), $nGrp,   "  has $nGrp group objects" );

   lives_ok { $res->addGroupInfo() }       "addGroupInfo again ok";
   $nGrp  = $res->{stats}->{nGroup};
   $nMult = $res->{stats}->{nMultiGrp};
   is( $nGrp,  1702,                       "  still has 1702 hairpin groups" );
   is( $nMult,  125,                       "  still has  125 multi-memeber groups" );
   is( $res->getObjects('group'), $nGrp,   "  still has 1702 group objects" );
   
   my $gobj = $res->{group}->{'hsa-mir-21'};
   ok( $gobj,                              "hsa-mir-21 group obj" );
   
   is( ref($gobj), 'HASH',                 "  is HASH" );
   is( $gobj->{name},  'hsa-mir-21',       "  name hsa-mir-21" );
   is( $gobj->{numCh}, 1,                  "  numCh 1" );
   is( $gobj->{dname}, 'hsa-mir-21[1]',    "  name hsa-mir-21[1]" );

   my $refCh = $gobj->{children};
   is( ref($refCh), 'ARRAY',               "hsa-mir-21 children ARRAY ref" );
   is( @$refCh, 1,                         "  has 1 child" );

   # Order of group children is order read from GFF
   my $ch = @$refCh[0];
   is( ref($ch),        'HASH',            "hsa-let-7a child 1 HASH ref" );
   is( $ch->{name},     'hsa-mir-21',      "  name   hsa-mir-21" );
   is( $ch->{type},     'hairpin',         "  type   hairpin" );
   is( $ch->{strand},   '+',               "  strand +" );
   is( $ch->{groupObj},   $gobj,           "  groupObj ok" );  
}
sub b32_MirInfo_groups_2 : Test(24) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $res = getGffInfo();
   ok( $res,                               "getGffInfo() ok" );

   my ($nGrp, $nMult);
   my $nHpin  = $res->{stats}->{nHairpin};
   $res->addGroupInfo();
   ok( $res,                               "addGroupInfo ok" );
   
   #   chr11 hairpin 122017230 122017301 - ID=MI0000061;Alias=MI0000061;Name=hsa-let-7a-2
   #   chr11 mature  122017276 122017297 - ID=MIMAT0000062;Alias=MIMAT0000062;Name=hsa-let-7a-5p;Derives_from=MI0000061
   #   chr11 mature  122017231 122017252 - ID=MIMAT0010195;Alias=MIMAT0010195;Name=hsa-let-7a-2-3p;Derives_from=MI0000061
   #   chr22 hairpin  46508629  46508702 + ID=MI0000062;Alias=MI0000062;Name=hsa-let-7a-3
   #   chr22 mature   46508632  46508653 + ID=MIMAT0000062_1;Alias=MIMAT0000062;Name=hsa-let-7a-5p;Derives_from=MI0000062
   #   chr22 mature   46508680  46508700 + ID=MIMAT0004481;Alias=MIMAT0004481;Name=hsa-let-7a-3p;Derives_from=MI0000062
   #   chr9  hairpin  96938239  96938318 + ID=MI0000060;Alias=MI0000060;Name=hsa-let-7a-1
   #   chr9  mature   96938244  96938265 + ID=MIMAT0000062_2;Alias=MIMAT0000062;Name=hsa-let-7a-5p;Derives_from=MI0000060
   #   chr9  mature   96938295  96938315 + ID=MIMAT0004481_1;Alias=MIMAT0004481;Name=hsa-let-7a-3p;Derives_from=MI0000060
   my $gobj = $res->{group}->{'hsa-let-7a'};
   ok( $gobj,                              "hsa-let-7a group obj" );
   is( ref($gobj), 'HASH',                 "  is HASH" );
   is( $gobj->{name},  'hsa-let-7a',       "  name hsa-let-7a" );
   is( $gobj->{numCh}, 3,                  "  numCh 3" );
   is( $gobj->{dname}, 'hsa-let-7a[3]',    "  name hsa-let-7a[3]" );

   my $refCh = $gobj->{children};
   is( ref($refCh), 'ARRAY',               "hsa-let-7a children ARRAY ref" );
   is( @$refCh, 3,                         "  has 3 children" );

   # Order of group children is order read from GFF
   my $ch = @$refCh[0];
   is( ref($ch),        'HASH',            "hsa-let-7a child 1 HASH ref" );
   is( $ch->{name},     'hsa-let-7a-2',    "  name   hsa-let-7a-2" );
   is( $ch->{type},     'hairpin',         "  type   hairpin" );
   is( $ch->{strand},   '-',               "  strand -" );
   is( $ch->{groupObj}, $gobj,             "  groupObj ok" );  

   $ch = @$refCh[1];
   is( ref($ch),        'HASH',            "hsa-let-7a child 2 HASH ref" );
   is( $ch->{name},     'hsa-let-7a-3',    "  name   hsa-let-7a-3" );
   is( $ch->{type},     'hairpin',         "  type   hairpin" );
   is( $ch->{strand},   '+',               "  strand +" );
   is( $ch->{groupObj}, $gobj,             "  groupObj ok" );  

   $ch = @$refCh[2];
   is( ref($ch),        'HASH',            "hsa-let-7a child 3 HASH ref" );
   is( $ch->{name},     'hsa-let-7a-1',    "    name   hsa-let-7a-1" );
   is( $ch->{type},     'hairpin',         "    type   hairpin" );
   is( $ch->{strand},   '+',               "    strand +" );
   is( $ch->{groupObj}, $gobj,             "  groupObj ok" );  
}
sub b33_MirInfo_groups_3: Test(23) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfo();
   ok( $res,                                            "getGffInfo() ok" );
   is( $res->{stats}->{nGroup}, 1702,                   "  has 1702 groups" );
   
   ok( $res->{hairpin}->{'hsa-mir-5683'}->{groupObj},   "  hsa-mir-5683   groupObj found" );
   ok( $res->{group}->{'hsa-mir-5683'},                 "  hsa-mir-5683   group    found" );
   
   ok( $res->{hairpin}->{'hsa-mir-6083'}->{groupObj},   "  hsa-mir-6083   groupObj found" );
   ok( $res->{group}->{'hsa-mir-6083'},                 "  hsa-mir-6083   group    found" );
   
   ok( $res->{hairpin}->{'hsa-mir-192'}->{groupObj},    "  hsa-mir-192    groupObj found" );
   ok( $res->{group}->{'hsa-mir-192'},                  "  hsa-mir-192    group    found" );
   
   ok( $res->{hairpin}->{'hsa-mir-598'}->{groupObj},    "  hsa-mir-598    groupObj found" );
   ok( $res->{group}->{'hsa-mir-598'},                  "  hsa-mir-598    group    found" );
   
   ok( $res->{hairpin}->{'hsa-let-7f-1'}->{groupObj},   "  hsa-let-7f-1   groupObj found" );
   ok( $res->{hairpin}->{'hsa-let-7f-2'}->{groupObj},   "  hsa-let-7f-2   groupObj found" );
   ok( $res->{group}->{'hsa-let-7f'},                   "  hsa-let-7f     group    found" );

   ok( $res->{hairpin}->{'hsa-mir-1-1'}->{groupObj},    "  hsa-mir-1-1    groupObj found" );
   ok( $res->{hairpin}->{'hsa-mir-1-2'}->{groupObj},    "  hsa-mir-1-2    groupObj found" );
   ok( $res->{group}->{'hsa-mir-1'},                    "  hsa-mir-1      group    found" );

   ok( $res->{hairpin}->{'hsa-mir-196a-1'}->{groupObj}, "  hsa-mir-196a-1 groupObj found" );
   ok( $res->{hairpin}->{'hsa-mir-196a-2'}->{groupObj}, "  hsa-mir-196a-2 groupObj found" );
   ok( $res->{group}->{'hsa-mir-196a'},                 "  hsa-mir-196a   group    found" );
   
   ok( $res->{hairpin}->{'hsa-mir-1254-1'}->{groupObj}, "  hsa-mir-1254-1 groupObj found" );
   ok( $res->{hairpin}->{'hsa-mir-1254-2'}->{groupObj}, "  hsa-mir-1254-2 groupObj found" );
   ok( $res->{group}->{'hsa-mir-1254'},                 "  hsa-mir-1254   group    found" );

   ok(!$res->{group}->{'hsa-mir-1273e'},                "  hsa-mir-1273e  group NOT found" );
}

# AC   MIPF0000002
# ID   let-7
# MI   MI0000001  cel-let-7
# MI   MI0000060  hsa-let-7a-1
# MI   MI0000061  hsa-let-7a-2
# MI   MI0000062  hsa-let-7a-3
# MI   MI0000063  hsa-let-7b
# MI   MI0000064  hsa-let-7c
# MI   MI0000065  hsa-let-7d
# MI   MI0000066  hsa-let-7e
# MI   MI0000067  hsa-let-7f-1
# MI   MI0000068  hsa-let-7f-2
# MI   MI0000100  hsa-mir-98
# MI   MI0000137  mmu-let-7g
sub b40_MirInfo_family : Test(35) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $res = getGffInfo();
   ok( $res,                                 "getGffInfo() ok" );

   lives_ok { $res->addFamilyInfo(); }       "addFamilyInfo ok";
   return "error" unless $res->{stats}->{nFamily};

   my $nFam  = $res->{stats}->{nFamily};
   my $nHpin = $res->{stats}->{nHairpin}; 
   is( $nFam, 1440,                          "  has 1440 hsa mir families" );
   is( $res->getObjects('family'), 1440,     "  has 1440 family objects" );
   
   lives_ok { $res->addFamilyInfo(); }       "addFamilyInfo again ok";
   $nFam  = $res->{stats}->{nFamily};
   is( $nFam, 1440,                          "  still has 1440 hsa mir families" );
   is( $res->getObjects('family'), $nFam,    "  still has 1440 family objects" );

   # let-7 family has 12 members
   my $fobj = $res->{family}->{'let-7'};
   ok( $fobj,                                "let-7 family obj" );
   is( ref($fobj),     'HASH',               "  is HASH" );
   is( $fobj->{name},  'let-7',              "  name  let-7" );
   is( $fobj->{dname}, 'let-7[12]',          "  dname let-7[12]" );
   is( $fobj->{id},    'MIPF0000002',        "  id    MIPF0000002" );
   is( $fobj->{numCh}, 12,                   "  numCh 12" );

   my $refCh = $fobj->{children};
   is( ref($refCh), 'ARRAY',                 "let-7a children ARRAY ref" );
   is( @$refCh, 12,                          "  has 12 children" );

   # Order of group children is order read from GFF
   my $ch = @$refCh[0];
   is( ref($ch),         'HASH',             "let-7 child 1 HASH ref" );
   is( $ch->{name},      'hsa-let-7a-1',     "  name   hsa-let-7a-1" );
   is( $ch->{type},      'hairpin',          "  type   hairpin" );
   is( $ch->{familyObj}, $fobj,              "  familyObj ok" );
   
   $ch = @$refCh[1];
   is( ref($ch),         'HASH',             "let-7a child 2 HASH ref" );
   is( $ch->{name},      'hsa-let-7a-2',     "  name   hsa-let-7a-2" );
   is( $ch->{type},      'hairpin',          "  type   hairpin" );
   is( $ch->{familyObj}, $fobj,              "  familyObj ok" );


   # no explicit family info for hsa-mir-4284 in miFam, but one will have been created
   $fobj = $res->{family}->{'hsa-mir-4284'};
   ok( $fobj,                                "hsa-mir-4284 family obj" );
   is( ref($fobj),     'HASH',               "  is HASH" );
   is( $fobj->{name},  'hsa-mir-4284',       "  name  hsa-mir-4284" );
   is( $fobj->{dname}, 'hsa-mir-4284[unk]',  "  dname hsa-mir-4284[unk]" );
   is( $fobj->{id},    'hsa-mir-4284',       "  id    hsa-mir-4284" );
   is( $fobj->{numCh}, 1,                    "  numCh 1" );

   $refCh = $fobj->{children};
   is( ref($refCh), 'ARRAY',                 "hsa-mir-4284 children ARRAY ref" );
   is( @$refCh, 1,                           "  has 1 child" );
   
   $ch = @$refCh[0];
   is( ref($ch),         'HASH',             "hsa-mir-4284 child 1 HASH ref" );
   is( $ch->{name},      'hsa-mir-4284',     "  name   hsa-mir-4284" );
   is( $ch->{type},      'hairpin',          "  type   hairpin" );
   is( $ch->{familyObj}, $fobj,              "  familyObj ok" );
}
sub b41_MirInfo_families: Test(21) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfoFull();
   ok( $res,                                             "getGffInfoFull() ok" );
   
   ok( $res->{hairpin}->{'hsa-mir-215'}->{familyObj},    "  hsa-mir-215    familyObj found" );
   ok( $res->{hairpin}->{'hsa-mir-192'}->{familyObj},    "  hsa-mir-192    familyObj found" );
   ok( $res->{family}->{'mir-192'},                      "  mir-192        family    found" );
   
   ok( $res->{hairpin}->{'hsa-mir-598'}->{familyObj},    "  hsa-mir-598    familyObj found" );
   ok( $res->{family}->{'mir-598'},                      "  mir-598        family    found" );
   
   ok( $res->{hairpin}->{'hsa-mir-1-1'}->{familyObj},    "  hsa-mir-1-1    familyObj found" );
   ok( $res->{hairpin}->{'hsa-mir-1-2'}->{familyObj},    "  hsa-mir-1-2    familyObj found" );
   ok( $res->{family}->{'mir-1'},                        "  mir-1          family    found" );

   ok( $res->{hairpin}->{'hsa-mir-196a-1'}->{familyObj}, "  hsa-mir-196a-1 familyObj found" );
   ok( $res->{hairpin}->{'hsa-mir-196a-2'}->{familyObj}, "  hsa-mir-196a-2 familyObj found" );
   ok( $res->{family}->{'mir-196'},                      "  mir-196        family    found" );

   ok( $res->{hairpin}->{'hsa-mir-1254-1'}->{familyObj}, "  hsa-mir-1254-1 familyObj found" );
   ok( $res->{hairpin}->{'hsa-mir-1254-2'}->{familyObj}, "  hsa-mir-1254-2 familyObj found" );
   ok( $res->{family}->{'mir-1254'},                     "  mir-1254       family    found" );
   
   ok( $res->{hairpin}->{'hsa-mir-5683'}->{familyObj},   "  hsa-mir-5683   familyObj found" );
   ok( $res->{family}->{'hsa-mir-5683'},                 "  hsa-mir-5683   family    found" );

   ok( $res->{hairpin}->{'hsa-mir-6083'}->{familyObj},   "  hsa-mir-6083   familyObj found" );
   ok( $res->{family}->{'hsa-mir-6083'},                 "  hsa-mir-6083   family    found" );
   
   ok(!$res->{family}->{'mir-1273e'},                    "  mir-1273e      family NOT found" );
   ok(!$res->{family}->{'hsa-mir-1273e'},                "  hsa-mir-1273e  family NOT found" );
}

sub b50_MirInfo_chromosomes: Test(22) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfo();
   ok( $res,                                          "getGffInfo ok" );

   my @chroms = $res->getChroms();
   ok( @chroms,                                       "MirInfo_obj->getChroms() ok" );
   is( @chroms,         24,                           "  has 24 chromosomes" );
   is( $chroms[0],  'chr1',                           "  first is chr1" );
   is( $chroms[-1], 'chrY',                           "  last is  chrY" );

   is( $res->getChromHps('chr19'), 142,               "has 142 chr19 hps" );
   is( $res->getChromHps('chr19', '+'), 105,          "has 105 chr19 + strand hps" );
   is( $res->getChromHps('chr19', '-'), 37,           "has  37 chr19 - strand hps" );

   is( $res->getChromHps('chr21'), 22,                "has  22 chr21 hps" );
   is( $res->getChromHps('chr21', '+'), 14,           "has  14 chr21 + strand hps" );
   is( $res->getChromHps('chr21', '-'),  8,           "has   8 chr21 - strand hps" );

   is( $res->getChromHps('chrX'), 118,                "has 118 chrX hps" );
   is( $res->getChromHps('chrX', '+'), 42,            "has  42 chrX + strand hps" );
   is( $res->getChromHps('chrX', '-'), 76,            "has  76 chrX - strand hps" );

   is( $res->getChromHps('chrY'), 2,                  "has   2 chrY hps" );
   is( $res->getChromHps('chrY', '+'), 2,             "has   2 chrY + strand hps" );
   is( $res->getChromHps('chrY', '-'), 0,             "has   0 chrY - strand hps" );

   ok(!$res->getChromHps('chr99'),                    "no chr99 hps" );
   ok(!$res->getChromHps('chr99', '+'),               "no chr99 + strand hps" );
   ok(!$res->getChromHps('chr99', '-'),               "no chr99 - strand hps" );
   is( @chroms,         24,                           "still 24 chromosomes" );

   my $numHp = 0;
   foreach my $chr ($res->getChroms()) { $numHp += $res->getChromHps($chr); }
   is( $numHp, $res->getObjects('hpid'),              "total chromHps correct" );
}
sub b51_MirInfo_clusters: Test(9) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfo();
   ok( $res,                                             "getGffInfo ok" );
   lives_ok{ $res->addClusterInfo(); }                   "addClusterInfo lives";

   # access lists of all cluster objects, by type
   ok( $res->getObjects('cluster'),                      "has cluster objects" );
   ok( $res->getObjects('cluster+'),                     "has cluster+ objects" );
   ok( $res->getObjects('cluster-'),                     "has cluster- objects" );
   diag( "cluster: " . scalar($res->getObjects('cluster')) .
         ", cluster+: " . scalar($res->getObjects('cluster+')) .
         ", cluster-: " . scalar($res->getObjects('cluster-')) );

   my $totHp   = $res->getObjects('hpid');
   my ($totW, $totC) = (0,0);
   foreach ($res->getObjects('hpid')) {
      $totW++ if $_->{strand} eq '+'; $totC++ if $_->{strand} eq '-';
   }
   my ($clustHp, $clHpW, $clHpC) = (0, 0, 0);
   foreach ($res->getObjects('cluster'))  { $clustHp += $_->{numCh}; }
   foreach ($res->getObjects('cluster+')) { $clHpW   += $_->{numCh}; }
   foreach ($res->getObjects('cluster-')) { $clHpC   += $_->{numCh}; }
   is( $clustHp, $totHp,                                 "cluster  Hp count $clustHp == $totHp" );
   is( $clHpW,   $totW,                                  "cluster+ Hp count $clHpW == $totW" );
   is( $clHpC,   $totC,                                  "cluster- Hp count $clHpC == $totC" );
   
   my $numBad = 0;
   foreach ($res->getObjects('hpid')) {
      if (!ref($_->{clusterObj})) { $numBad++;
         ok( 0,  "$_->{name} has no clusterObj" );
      }
   }
   is( $numBad, 0,                                       "all $totHp hairpins are assigned to a cluster" );
}
sub b52_MirInfo_clusters_params: Test(54) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   # default parameters (clusterDist = 10000)
   my $res = MirInfo->newFromGff(version => 'v20', organism => 'hsa');
   ok( $res,                                             "newFromGff(version=>'v20', organism=>'hsa') ok" );
   is( $res->{clusterDist}, 10000,                       "  clusterDist 10000" );
   lives_ok{ $res->addClusterInfo(); }                   "  addClusterInfo lives";
   
   is( $res->getChromClusters('chrY'), 2,                "  chrY: 2 cluster objects" );
   is( $res->getChromClusters('chrY', '+'), 2,           "  chrY: 2 cluster+ objects" );
   is( $res->getChromClusters('chrY', '-'), 0,           "  chrY: 0 cluster- objects" );

   my @objs = $res->getChromClusters('chrY');
   my $cl = $objs[0];
   ok( $cl,                                              "first chrY cluster" );
   is( $cl->{id},    "cluster(chrY|1)",                  "  id    cluster(chrY|1)" );
   is( $cl->{name},  "cluster(chrY|1)",                  "  name  cluster(chrY|1)" );
   is( $cl->{start}, 1362811,                            "  start 1362811" );
   is( $cl->{end},   1362885,                            "  end   1362885" );
   is( $cl->{span},  75,                                 "  span  75" );
   is( $cl->{dname}, "cluster(chrY:1362811-1362885)[1]", "  dname cluster(chrY:1362811-1362885)[1]" );
   is( $cl->{numCh}, 1,                                  "  numCh 1" );
   is( ref($cl->{children}), 'ARRAY',                    "  children ARRAY ref" );
   my @ch = @{ $cl->{children} };
   is( @ch,                   1,                         "  has 1 hairpin" );
   is( $ch[0]->{type},       "hairpin",                  "  hp1 type hairpin" );
   is( $ch[0]->{name},       "hsa-mir-3690-2",           "  hp1 name hsa-mir-3690-2" );
   is( $ch[0]->{clusterObj}, $cl,                        "  hp1 clusterObj correct" );
   
   $cl = $objs[1];
   ok( $cl,                                              "second chrY cluster" );
   is( $cl->{id},    "cluster(chrY|2)",                  "  id    cluster(chrY|2)" );
   is( $cl->{name},  "cluster(chrY|2)",                  "  name  cluster(chrY|2)" );
   is( $cl->{start}, 2477232,                            "  start 2477232" );
   is( $cl->{end},   2477295,                            "  end   2477295" );
   is( $cl->{span},  64,                                 "  span  64" );
   is( $cl->{dname}, "cluster(chrY:2477232-2477295)[1]", "  dname cluster(chrY:2477232-2477295)[1]" );
   is( $cl->{numCh}, 1,                                  "  numCh 1" );
   is( ref($cl->{children}), 'ARRAY',                    "  children ARRAY ref" );
   @ch = @{ $cl->{children} };
   is( @ch,                   1,                         "  has 1 hairpin" );
   is( $ch[0]->{type},       "hairpin",                  "  hp1 type hairpin" );
   is( $ch[0]->{name},       "hsa-mir-6089-2",           "  hp1 name hsa-mir-6089-2" );
   is( $ch[0]->{clusterObj}, $cl,                        "  hp1 clusterObj correct" );


   # wider clusterDist parameter
   $res = MirInfo->newFromGff(version => 'v20', organism => 'hsa', clusterDist => 1200000);
   ok( $res,                                             "newFromGff(version=>'v20', organism=>'hsa', clusterDist=>1200000) ok" );
   is( $res->{clusterDist}, 1200000,                     "  clusterDist 1200000" );
   lives_ok{ $res->addClusterInfo(); }                   "  addClusterInfo lives";
   
   is( $res->getChromClusters('chrY'), 1,                "  chrY: 1 cluster objects" );
   is( $res->getChromClusters('chrY', '+'), 1,           "  chrY: 1 cluster+ objects" );
   is( $res->getChromClusters('chrY', '-'), 0,           "  chrY: 0 cluster- objects" );

   @objs = $res->getChromClusters('chrY');
   $cl = $objs[0];
   ok( $cl,                                              "first chrY cluster" );
   is( $cl->{id},    "cluster(chrY|1)",                  "  id    clusterchrY[1]" );
   is( $cl->{name},  "cluster(chrY|1)",                  "  name  clusterchrY[1]" );
   is( $cl->{start}, 1362811,                            "  start 1362811" );
   is( $cl->{end},   2477295,                            "  end   2477295" );
   is( $cl->{span},  1114485,                            "  span  1114485" );
   is( $cl->{dname}, "cluster(chrY:1362811-2477295)[2]", "  dname cluster(chrY:1362811-2477295)[2]" );
   is( $cl->{numCh}, 2,                                  "  numCh 2" );
   is( ref($cl->{children}), 'ARRAY',                    "  children ARRAY ref" );
   @ch = @{ $cl->{children} };
   is( @ch,                   2,                         "  has 2 hairpins" );
   is( $ch[0]->{type},       "hairpin",                  "  hp1 type hairpin" );
   is( $ch[0]->{name},       "hsa-mir-3690-2",           "  hp1 name hsa-mir-3690-2" );
   is( $ch[0]->{clusterObj}, $cl,                        "  hp1 clusterObj correct" );
   is( $ch[1]->{type},       "hairpin",                  "  hp1 type hairpin" );
   is( $ch[1]->{name},       "hsa-mir-6089-2",           "  hp1 name hsa-mir-6089-2" );
   is( $ch[1]->{clusterObj}, $cl,                        "  hp1 clusterObj correct" );

   #foreach ($res->getChromClusters('chr21')) { diag($_->{dname}); }
}

sub b60_MirInfo_newFromGffFull_v20: Test(12) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfoFull();
   ok( $res,                                 "MirInfo->newFromGffFull(version=>'v20', organism=>'hsa') ok" );
   is( $res->getObjects('hpid'),    1871,    "  has 1871 hpid objects" );
   is( $res->getObjects('hairpin'), 1870,    "  has 1870 hairpin objects" );
   is( $res->getObjects('mature'),  2794,    "  has 2794 mature objects" );
   is( $res->getObjects('group'),   1702,    "  has 1702 group objects" );
   is( $res->{stats}->{nMultiGrp},   125,    "  has  125 multi-memeber groups" );
   is( $res->getObjects('family'),  1440,    "  has 1440 family objects" );
   is( $res->getObjects('byChrom'),   24,    "  has   24 byChrom objects" );
   is( $res->getObjects('chrClust'),  24,    "  has   24 chrClust objects" );
   is( $res->getObjects('cluster'), 1559,    "  has 1559 cluster objects" );
   is( $res->getObjects('cluster+'), 804,    "  has  804 cluster+ objects" );
   is( $res->getObjects('cluster-'), 818,    "  has  818 cluster- objects" );
}
sub b61_MirInfo_newFromGffFull_v21 : Test(25) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res;
   lives_ok { $res = MirInfo->newFromGffFull(version => 'v21', organism => 'hsa'); } 
                                              "MirInfo->newFromGffFull(version => 'v21', organism => 'hsa') lives";
   return "error" unless $res;
   diag($res->toString());
   isa_ok( $res, 'MirInfo',                   "  isa MirInfo" );
   is( $res->{version}, 'v21',                "  version v21" );
   is( $res->{organism}, 'hsa',               "  organism hsa" );

   
   my ($nLine, $nEntry, $nHpId, $nHpin, $nMat, $nMatseq, $nUqHp, $nDupHp, $nGrp, $nMGrp, $nFam);
   $nLine   = $res->{stats}->{nLine};
   $nEntry  = $res->{stats}->{nEntry};
   $nMat    = $res->{stats}->{nMature};
   $nMatseq = $res->{stats}->{nMatseq};
   $nHpId   = $res->{stats}->{nHpId};
   $nHpin   = $res->{stats}->{nHairpin};
   $nDupHp  = $res->{stats}->{nDupHpin};
   $nGrp    = $res->{stats}->{nGroup};
   $nMGrp   = $res->{stats}->{nMultiGrp};
   $nFam    = $res->{stats}->{nFamily};
   is( $nLine,   4707,                        "  has 4707 lines" );
   is( $nEntry,  4694,                        "  has 4694 entries" );
   is( $nHpId,   1881,                        "  has 1881 hairpin miRNA loci" );
   is( $nHpin,   1881,                        "  has 1881 hairpin names" );
   is( $nDupHp,     0,                        "  has    0 duplicate hairpin name" );
   is( $nGrp,    1704,                        "  has 1704 miRNA groups" );
   is( $nMGrp,    127,                        "  has  127 multi-member groups" );
   is( $nFam,    1445,                        "  has 1445 miRNA families" );
   is( $nMat,    2813,                        "  has 2813 mature miRNA loci" );
   is( $nMatseq, 2588,                        "  has 2588 mature miRNA sequences" );
   is( $res->getObjects('hpid'),    $nHpId,   "  has $nHpId hpid objects" );
   is( $res->getObjects('hairpin'), $nHpin,   "  has $nHpin hairpin objects" );
   is( $res->getObjects('mature'),  $nMat,    "  has $nMat mature objects" );
   is( $res->getObjects('matseq'),  $nMatseq, "  has $nMatseq mature sequence objects" );
   is( $res->getObjects('group'),   $nGrp,    "  has $nGrp group objects" );
   is( $res->getObjects('family'),  $nFam,    "  has $nFam family objects" );
   is( $res->getObjects('byChrom'),    24,    "  has   24 byChrom objects" );
   is( $res->getObjects('chrClust'),   24,    "  has   24 chrClust objects" );
   is( $res->getObjects('cluster'),  1566,    "  has 1566 cluster objects" );
   is( $res->getObjects('cluster+'),  810,    "  has  810 cluster+ objects" );
   is( $res->getObjects('cluster-'),  818,    "  has  818 cluster- objects" );
}

#=====================================================================================
# MirInfo utility methods
#=====================================================================================

sub b70_MirInfo_writeHairpinInfo: Test(26) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfoFull();
   ok( $res,                                             "getGffInfoFull() ok" );
   is( $res->{version}, 'v20',                           "  version v20" );
   is( $res->{organism}, 'hsa',                          "  organism hsa" );
   
   my $outF = "./hsa_v20_cluster10000.hpInfo";
   unlink($outF);
   ok( ! -e $outF,                                       "no test file '$outF'");
   
   my ($tot, $fil);
   lives_ok { ($tot, $fil) = $res->writeHairpinInfo(); } "writeHairpinInfo lives";
   return "error" unless $fil;

   my $num = $res->getObjects('hpid');
   is( $tot,  $num,                                      "  num hpids $num" );
   ok( -e     $outF,                                     "  expected file '$outF' exists" );
   ok( -e     $fil,                                      "  returned file '$fil' exists" );

   my @lines = __readTestFile($outF);
   is( @lines, $num+1,                                   "  has " . ($num+1) . " lines" );

   my $hdr = $lines[0];
   ok( $hdr,                                             "  hdr not empty" );
   chomp($hdr);
   my @flds = split(/\t/, $hdr);
   my @expected = @MirInfo::HAIRPIN_INFO_FIELDS;
   is( @flds, @expected,                                 "  has " . scalar(@expected) . " fields" );
   for (my $ix=0; $ix<@expected; $ix++) {  
      is( $flds[$ix], $expected[$ix],                    "  fld $expected[$ix] found" );
   }

   unlink( $fil ) unless $KEEP_FILES;
}
sub b71_MirInfo_writeMatureInfo: Test(21) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfoFull();
   ok( $res,                                             "getGffInfoFull() ok" );
   is( $res->{version}, 'v20',                           "  version v20" );
   is( $res->{organism}, 'hsa',                          "  organism hsa" );
   
   my $outF = "./hsa_v20_cluster10000.matInfo";
   unlink($outF);
   ok( ! -e $outF,                                       "no test file '$outF'");
   
   my ($tot, $fil);
   lives_ok { ($tot, $fil) = $res->writeMatureInfo(); }  "writeMatureInfo lives";
   return "error" unless $fil;
   
   my $num = $res->getObjects('mature');
   is( $tot,  $num,                                      "  num mature $num" );
   ok( -e     $outF,                                     "  expected file '$outF' exists" );
   ok( -e     $fil,                                      "  returned file '$fil' exists" );

   my @lines = __readTestFile($outF);
   is( @lines, ($num+1),                                 "  has " . ($num+1) . " lines" );

   my $hdr = $lines[0];
   ok( $hdr,                                             "  hdr not empty" );
   chomp($hdr);
   my @flds = split(/\t/, $hdr);
   my @expected = @MirInfo::MATURE_INFO_FIELDS;
   is( @flds, @expected,                                 "  has " . scalar(@expected) . " fields" );
   for (my $ix=0; $ix<@expected; $ix++) {  
      is( $flds[$ix], $expected[$ix],                    "  fld $expected[$ix] found" );
   }

   unlink( $fil ) unless $KEEP_FILES;
}

sub b81_MirInfo_makeRefFa_all : Test(11) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = MirInfo->new(version => 'v20', organism => 'all'); 
   ok( $res,                                       "MirInfo->new(version => 'v20', organism => 'all') ok" );
   is( $res->{organism}, 'all',                    "  organism all" );
   is( $res->{version}, 'v20',                     "  version v20" );
   ok( $res->{hpFa},                               "  has hpFa: " . $res->{hpFa} );
   ok( -e $res->{hpFa},                            "  hpFa exists" );

   my $expF = "./hairpin_cDNA.fa";
   unlink($expF);
   ok( ! -e $expF,                                 "  No file '$expF'" );

   my ($num, $outF);
   lives_ok { ($num, $outF) = $res->makeRefFa(); } "makeResFa lives";
   return "error" unless $outF;

   is( $num,  24521,                               "  wrote 24521 hairpin entries" );
   ok( -e     $expF,                               "  expected file '$expF' exists" );
   ok( -e     $outF,                               "  returned file '$outF' exists" );
   
   my @lines = __readTestFile($outF);
   is( @lines, 78466,                              "  has 78466 lines" );

   unlink( $expF ) unless $KEEP_FILES;
}
sub b82_MirInfo_makeRefFa_hsa : Test(11) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = MirInfo->new(version => 'v20', organism => 'hsa'); 
   ok( $res,                                       "MirInfo->new(version => 'v20', organism => 'hsa') ok" );
   is( $res->{organism}, 'hsa',                    "  organism hsa" );
   is( $res->{version}, 'v20',                     "  version v20" );
   ok( $res->{hpFa},                               "  has hpFa: " . $res->{hpFa} );
   ok( -e $res->{hpFa},                            "  hpFa exists" );

   my $expF = "./hairpin_cDNA_hsa.fa";
   unlink($expF);
   ok( ! -e $expF,                                 "  No file '$expF'" );

   my ($num, $outF);
   lives_ok { ($num, $outF) = $res->makeRefFa(); } "makeResFa lives";
   return "error" unless $outF;

   is( $num,   1872,                               "  wrote 1872 hairpin entries" );
   ok( -e     $expF,                               "  expected file '$expF' exists" );
   ok( -e     $outF,                               "  returned file '$outF' exists" );
   
   my @lines = __readTestFile($outF);
   cmp_ok( @lines, '>=', (2*1872),                 "  at least " . (2*1872) . " lines" );

   unlink( $expF ) unless $KEEP_FILES;
}
sub b82_MirInfo_makeRefFa_mmu : Test(11) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = MirInfo->new(version => 'v21', organism => 'mmu'); 
   ok( $res,                                       "MirInfo->new(version => 'v21', organism => 'mmu') ok" );
   is( $res->{organism}, 'mmu',                    "  organism mmu" );
   is( $res->{version}, 'v21',                     "  version v21" );
   ok( $res->{hpFa},                               "  has hpFa: " . $res->{hpFa} );
   ok( -e $res->{hpFa},                            "  hpFa exists" );

   my $expF = "./hairpin_cDNA_mmu.fa";
   unlink($expF);
   ok( ! -e $expF,                                 "  No file '$expF'" );

   my ($num, $outF);
   lives_ok { ($num, $outF) = $res->makeRefFa(); } "makeResFa lives";
   return "error" unless $outF;

   is( $num,   1193,                               "  wrote 1193 hairpin entries" );
   ok( -e     $expF,                               "  expected file '$expF' exists" );
   ok( -e     $outF,                               "  returned file '$outF' exists" );
   
   my @lines = __readTestFile($outF);
   cmp_ok( @lines, '>=', (2*1193),                 "  at least " . (2*1193) . " lines" );

   unlink( $expF ) unless $KEEP_FILES;
}
sub b85_MirInfo_getRefFaHash_hsa : Test(16) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = MirInfo->new(version => 'v20', organism => 'hsa'); 
   ok( $res,                                           "MirInfo->new(version => 'v20', organism => 'hsa') ok" );
   is( $res->{organism}, 'hsa',                        "  organism hsa" );
   is( $res->{version}, 'v20',                         "  version v20" );
   ok( $res->{hpFa},                                   "  has hpFa: " . $res->{hpFa} );
   ok( -e $res->{hpFa},                                "  hpFa exists" );

   my ($href, $num);
   lives_ok { ($href, $num) = $res->getRefFaHash(); }  "getRefFaHash hsa lives";
   cmp_ok( $num, '>', 0,                               "  returned some hairpins" );
   return "error" unless $num;
 
   is( $num,   1872,                                   "  returned 1872 hairpin entries" );
   is( ref($href), 'HASH',                             "  refFa HASH ref" );
   is( keys(%$href), 1872,                             "  has 1872 keys" );

   my $str = "GGCTGAGCCGCAGTAGTTCTTCAGTGGCAAGCTTTATGTCCTGACCCAGCTAAAGCTGCCAGTTGAAGAACTGTTGCCCTCTGCC";
   my $fa  = $href->{'hsa-mir-22'};
   ok( $fa,                                            "has hsa-mir-22 fa" );
   is( length($fa), length($str),                      "  fa length correct" );
   is( $fa, $str,                                      "  fa string correct" );

   $str = "TGTGGGAGAGGAACATGGGCTCAGGACAGCGGGTGTCAGCTTGCCTGACCCCCATGTCGCCTCTGTAG";
   $fa  = $href->{'hsa-mir-6859-3'};
   ok( $fa,                                            "has hsa-mir-6859-3 fa" );
   is( length($fa), length($str),                      "  fa length correct" );
   is( $fa, $str,                                      "  fa string correct" );
}

sub z01_MirInfo_toString: Test(3) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res = getGffInfoFull();
   ok( 1,                                  "MirInfo_toString getGffInfoFull ok" );
   isa_ok( $res, 'MirInfo',                "  isa MirInfo" );

   my $str;
   lives_ok { $str = $res->toString(2); }   "  toString ok";
   return ("error") unless $str;
   diag($str);
}

#=====================================================================================
# MirStats helper funcion tests
#=====================================================================================

# From SAM spec:
# The MD field aims to achieve SNP/indel calling without looking at the reference. 
# For example, a string `10A5^AC6' means from the leftmost reference base in the alignment, 
# there are 10 matches followed by an A on the reference which is different from the aligned base;
# the next 5 reference bases are matches followed by a 2bp deletion from the reference; 
# the deleted sequence is AC; the last 6 bases are matches. 
# The MD field ought to match the CIGAR string.
sub c01_MirStats_parseMD_base : Test(65) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   # Invalid MD strings...
   ok(!MirStats::parseMD(''),                   "parseMd('')         undef" );
   ok(!MirStats::parseMD('abc'),                "parseMd('abc')      undef" );
   ok(!MirStats::parseMD('a^b'),                "parseMd('a^b')      undef" );
   ok(!MirStats::parseMD('MD:Z:'),              "parseMd('MD:Z:')    undef" );
   ok(!MirStats::parseMD('MD:Z:abc'),           "parseMd('MD:Z:abc') undef" );
   ok(!MirStats::parseMD('MD:Z:a^b'),           "parseMd('MD:Z:a^b') undef" );

   my ($sz, $mp, $dp, $mb, $db, $str);
   $str = 'MD:Z:101'; ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD($str);
   is($sz,                       101,           "'$str' ref len 101" );
   is(ref($mp),                   '',           "  no mm  pos" );
   is(ref($mb),                   '',           "  no mm  bases" );
   is(ref($dp),                   '',           "  no del pos" );
   is(ref($db),                   '',           "  no del bases" );

   $str = '22'; ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD($str);
   is($sz,                        22,           "'$str' ref len 22" );
   is(ref($mp),                   '',           "  no mm  pos" );
   is(ref($mb),                   '',           "  no mm  bases" );
   is(ref($dp),                   '',           "  no del pos" );
   is(ref($db),                   '',           "  no del bases" );

   $str = 'MD:Z:15T35'; ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD($str);
   is($sz,                        51,           "'$str' ref len 51" );
   is(ref($mp),              'ARRAY',           "  has mm  pos" );
   is(ref($mb),              'ARRAY',           "  has mm  bases" );
   is(@$mp,                        1,           "  has 1 mm pos" );
   is(@$mb,                        1,           "  has 1 mm base" );
   is($mp->[0],                   16,           "    mm pos  1 is 16" );
   is($mb->[0],                  'T',           "    mm base 1 is T" );
   is(ref($dp),                   '',           "  no del pos" );
   is(ref($db),                   '',           "  no del bases" );

   $str = '40G0'; ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD($str);
   is($sz,                        41,           "'$str' ref len 41" );
   is(ref($mp),              'ARRAY',           "  has mm  pos" );
   is(ref($mb),              'ARRAY',           "  has mm  bases" );
   is(@$mp,                        1,           "  has 1 mm pos" );
   is(@$mb,                        1,           "  has 1 mm base" );
   is($mp->[0],                   41,           "    mm pos  1 is 41" );
   is($mb->[0],                  'G',           "    mm base 1 is G" );
   is(ref($dp),                   '',           "  no del pos" );
   is(ref($db),                   '',           "  no del bases" );

   $str = '0A11'; ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD($str);
   is($sz,                        12,           "'$str' ref len 12" );
   is(ref($dp),                   '',           "  no del pos" );
   is(ref($db),                   '',           "  no del bases" );
   is(ref($mp),              'ARRAY',           "  has mm  pos" );
   is(ref($mb),              'ARRAY',           "  has mm  bases" );
   is(@$mp,                        1,           "  has 1 mm pos" );
   is(@$mb,                        1,           "  has 1 mm base" );
   is($mp->[0],                    1,           "    mm pos  1 is 1" );
   is($mb->[0],                  'A',           "    mm base 1 is A" );

   $str = 'MD:Z:25^T13'; ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD($str);
   is($sz,                        39,           "'$str' ref len 39" );
   is(ref($mp),                   '',           "  no mm pos" );
   is(ref($mb),                   '',           "  no mm bases" );
   is(ref($dp),              'ARRAY',           "  has del  pos" );
   is(ref($db),              'ARRAY',           "  has del  bases" );
   is(@$dp,                        1,           "  has 1 del pos" );
   is(@$db,                        1,           "  has 1 del base" );
   is($dp->[0],                   26,           "    del pos  1 is 26" );
   is($db->[0],                  'T',           "    del base 1 is T" );

   $str = '5^T16C3'; ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD($str);
   is($sz,                        26,           "'$str' ref len 26" );
   is(ref($mp),              'ARRAY',           "  has mm  pos" );
   is(ref($mb),              'ARRAY',           "  has mm  bases" );
   is(@$mp,                        1,           "  has 1 mm pos" );
   is(@$mb,                        1,           "  has 1 mm base" );
   is($mp->[0],                   23,           "    mm pos  1 is 23" );
   is($mb->[0],                  'C',           "    mm base 1 is C" );
   is(ref($dp),              'ARRAY',           "  has del  pos" );
   is(ref($db),              'ARRAY',           "  has del  bases" );
   is(@$dp,                        1,           "  has 1 del pos" );
   is(@$db,                        1,           "  has 1 del base" );
   is($dp->[0],                    6,           "    del pos  1 is 6" );
   is($db->[0],                  'T',           "    del base 1 is T" );
}
sub c02_MirStats_parseMD_more : Test(88) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $tests = [ 
      { str => 'MD:Z:5G4T33', sz => 44, mp => [6,11], mb => ['G','T'], dp => undef, db => undef },
      { str => '12C3T0T21C7A13', sz => 61, mp => [13,17,18,40,48], mb => ['C','T','T','C','A'], dp => undef, db => undef },
      { str => 'MD:Z:6^G90T0', sz => 98, mp => [98], mb => ['T'], dp => [7], db => ['G'] },
      { str => '0A5G4T33T7T0G2G5C2A2A8G20C1', sz => 101, mp => [1,7,12,46,54,55,58,64,67,70,79,100], 
                                                         mb => ['A','G','T','T','T','G','G','C','A','A','G','C'], 
                                                         dp => undef, db => undef },
      { str => '13^AAA14A52', sz => 83, mp => [31], mb => ['A'], dp => [14], db => ['AAA'] },
      { str => 'MD:Z:7^CGG16^A3^A20', sz => 51, mp => undef, mb => undef, dp => [8,27,31], db => ['CGG','A','A'] },
      { str => '5C11^T7T38^A35', sz => 100, mp => [6,26], mb => ['C','T'], dp => [18,65], db => ['T','A'] },
      { str => 'MD:Z:6^GC17G0A0G6T13T4C2C9^G4', sz => 71, mp => [26,27,28,35,49,54,57], 
                                                          mb => ['G','A','G','T','T','C','C'], 
                                                          dp => [7,67], 
                                                          db => ['GC','G'] }
   ];  
   foreach (@$tests) {
      my ($sz, $mp, $dp, $mb, $db) = MirStats::parseMD( $_->{str} );
      my $mStr = 'no'; $mStr = 'has' if $_->{mp};
      my $dStr = 'no'; $dStr = 'has' if $_->{dp};
      is($sz,                  $_->{sz},           "'$_->{str}' ref len $_->{sz}" );
      is(ref($mp),        ref($_->{mp}),           "  $mStr mm  pos" );
      is(ref($mb),        ref($_->{mb}),           "  $mStr mm  base" );
      if (ref($_->{mp}) eq 'ARRAY') {
         is(@$mp,          @{ $_->{mp}},           "  has " . scalar(@{ $_->{mp}}) . " mm pos" );
         is(@$mb,          @{ $_->{mb}},           "  has " . scalar(@{ $_->{mb}}) . " mm base" );
         is_deeply($mp,        $_->{mp},           "  mm positions (@{ $_->{mp}})" );
         is_deeply($mb,        $_->{mb},           "  mm bases (@{ $_->{mb}})" );
      }
      is(ref($dp),        ref($_->{dp}),           "  $dStr del pos" );
      is(ref($db),        ref($_->{db}),           "  $dStr del base" );
      if (ref($_->{dp}) eq 'ARRAY') {
         is(@$dp,          @{ $_->{dp}},           "  has " . scalar(@{ $_->{dp}}) . " del pos" );
         is(@$db,          @{ $_->{db}},           "  has " . scalar(@{ $_->{db}}) . " del base" );
         is_deeply($dp,        $_->{dp},           "  del positions (@{ $_->{dp}})" );
         is_deeply($db,        $_->{db},           "  del bases (@{ $_->{db}})" );
      }
   }
}
# other examples from a Yeast BAM:
# MD:Z:39^G5^T16C3C9G3G0C7A12G0
# MD:Z:5A9T0G9T8G2G14T38
# MD:Z:43A7T0G7C15
# MD:Z:20A7T0G7C15A1C3G2G11G7T3A5T8
# MD:Z:7T5A20T2C42G0
# MD:Z:17A4G4G1C11T7G5G1C4C9C3G0C5A6T7
# MD:Z:36^CGG16^A49
# MD:Z:7^CGG16^A58^A20
# MD:Z:28^A33^A40
# MD:Z:15^A33^A53
# MD:Z:19G18^AA53^T10
# MD:Z:36^A15^AAT50
# MD:Z:14^C7G6^T16T55
# MD:Z:17^TTCGTAGTGGTAAA10^GC27
# MD:Z:21^GG11A4G6A0C7^TC44
# MD:Z:34A3^A4^A59
# MD:Z:11A3^A4^A82
# MD:Z:6^GT42^A3A49
# MD:Z:19^A43^TT39
# MD:Z:40^G33^T13
# MD:Z:45^GCT15^A41
# MD:Z:0C24^CG24^A12
# MD:Z:24^CG24^A12
# MD:Z:85^G2^T14
# MD:Z:47^TG44^AT10
# MD:Z:28^TG44^AT29
# MD:Z:52^TT26^T23
# MD:Z:0A18^T46^A27
# MD:Z:24^TC41^TG19C0T4
# MD:Z:19^TC9C31^TG25

sub c03_MirStats_parseCigar_base : Test(31) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   # Invalid MD strings...
   ok(!MirStats::parseCigar(''),                "parseCigar('')      undef" );
   ok(!MirStats::parseCigar('abc'),             "parseCigar('abc')   undef" ); 

   my ($sz, $ip, $dp, $cig);
   $cig = '60M'; ($sz, $ip, $dp) = MirStats::parseCigar($cig);
   is($sz,                        60,           "'$cig' ref len 60" );
   is(ref($ip),                   '',           "  no ins pos" );
   is(ref($dp),                   '',           "  no del pos" );

   $cig = '5S60M'; ($sz, $ip, $dp) = MirStats::parseCigar($cig);
   is($sz,                        60,           "'$cig' ref len 60" );
   is(ref($ip),                   '',           "  no ins pos" );
   is(ref($dp),                   '',           "  no del pos" );

   $cig = '60M10S'; ($sz, $ip, $dp) = MirStats::parseCigar($cig);
   is($sz,                        60,           "'$cig' ref len 60" );
   is(ref($ip),                   '',           "  no ins pos" );
   is(ref($dp),                   '',           "  no del pos" );

   $cig = '4S60M10S'; ($sz, $ip, $dp) = MirStats::parseCigar($cig);
   is($sz,                        60,           "'$cig' ref len 60" );
   is(ref($ip),                   '',           "  no ins pos" );
   is(ref($dp),                   '',           "  no del pos" );

   $cig = '9M1D2M'; ($sz, $ip, $dp) = MirStats::parseCigar($cig);
   is($sz,                        12,           "'$cig' ref len 12" );
   is(ref($ip),                   '',           "  no ins pos" );
   is(ref($dp),              'ARRAY',           "  has del pos" );
   is(@$dp,                        1,           "  has 1 del pos" );
   is($dp->[0],                   10,           "    del pos  1 is 10" );

   $cig = '10M1I3M'; ($sz, $ip, $dp) = MirStats::parseCigar($cig);
   is($sz,                        13,           "'$cig' ref len 13" );
   is(ref($dp),                   '',           "  no del pos" );
   is(ref($ip),              'ARRAY',           "  has ins pos" );
   is(@$ip,                        1,           "  has 1 ins pos" );
   is($ip->[0],                   11,           "    ins pos  1 is 11" );

   $cig = '4M1D2M1I8M'; ($sz, $ip, $dp) = MirStats::parseCigar($cig);
   is($sz,                        15,           "'$cig' ref len 15" );
   is(ref($dp),              'ARRAY',           "  has del pos" );
   is(@$dp,                        1,           "  has 1 del pos" );
   is($dp->[0],                    5,           "    del pos  1 is 5" );
   is(ref($ip),              'ARRAY',           "  has ins pos" );
   is(@$ip,                        1,           "  has 1 ins pos" );
   is($ip->[0],                    8,           "    ins pos  1 is 8" );
}
sub c04_MirStats_parseCigar_more : Test(34) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $tests = [ 
      { cig => '25S25M1D13M38S',        sz => 39, ip => undef,     dp => [26] },
      { cig => '5S6M2D58M1D4M',         sz => 71, ip => undef,     dp => [7,67] },
      { cig => '7M2I2M1D26M',           sz => 36, ip => [8],       dp => [10] },
      { cig => '4S31M1I8M1I6M',         sz => 45, ip => [32,40],   dp => undef },
      { cig => '7M3D16M1D58M1D2M',      sz => 88, ip => undef,     dp => [8,27,86] },
      { cig => '9M1I10M1D9M1D10M2I10M', sz => 50, ip => [10,41],   dp => [20,30] }
   ];  
   foreach (@$tests) {
      my ($sz, $ip, $dp) = MirStats::parseCigar( $_->{cig} );
      my $iStr = 'no'; $iStr = 'has' if $_->{ip};
      my $dStr = 'no'; $dStr = 'has' if $_->{dp};
      is($sz,                  $_->{sz},           "'$_->{cig}' ref len $_->{sz}" );
      is(ref($ip),        ref($_->{ip}),           "  $iStr ins  pos" );
      if (ref($_->{ip}) eq 'ARRAY') {
         is(@$ip,          @{ $_->{ip}},           "  has " . scalar(@{ $_->{ip}}) . " ins pos" );
         is_deeply($ip,        $_->{ip},           "  ins positions (@{ $_->{ip}})" );
      }
      is(ref($dp),        ref($_->{dp}),           "  $dStr del pos" );
      if (ref($_->{dp}) eq 'ARRAY') {
         is(@$dp,          @{ $_->{dp}},           "  has " . scalar(@{ $_->{dp}}) . " del pos" );
         is_deeply($dp,        $_->{dp},           "  del positions (@{ $_->{dp}})" );
      }
   }
}

#=====================================================================================
# MirStats object tests
#=====================================================================================

sub d01_MirStats_globals : Test(3) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   is( $MirStats::DEFAULT_BAM_FLAGS,   '-F 0x4',      "DEFAULT_BAM_FLAGS  -F 0x4" );
   is( $MirStats::MIN_MATURE_OVERLAP,        13,      "MIN_MATURE_OVERLAP     13" );
   is( $MirStats::START_END_MARGIN,           5,      "START_END_MARGIN        5" );
}
sub d02_MirStats_new : Test(20) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $bamF     = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $minOlap  = $MirStats::MIN_MATURE_OVERLAP;
   my $margin   = $MirStats::START_END_MARGIN;
   my $bamFlags = $MirStats::DEFAULT_BAM_FLAGS;
   my $res = MirStats->new(bam => $bamF);
   ok( $res,                               "MirStats->new(bam=>bamFile) ok" );
   isa_ok( $res, 'MirStats',               "  isa MirStats" );
   is( $res->{bam}, $bamF,                 "  bam '$bamF'" );
   is( $res->{bamOpts}, $bamFlags,         "  bamOpts $bamFlags" );
   is( $res->{bamLoc}, undef,              "  bamLoc undef" );
   is( $res->{minOlap}, $minOlap,          "  minOlap $minOlap" );
   is( $res->{margin}, $margin,            "  minOlap $minOlap" );
   is( $res->{mirInfo}, undef,             "  mirInfo undef" );
   is( $res->{stats}->{nAlign}, undef,     "  nAlign undef" );
   is( $res->getObjects('hairpin'), undef, "  no hairpin objects" );

   $res = MirStats->new(bam => $bamF, minOlap => 10, margin => 1, 
                        bamOpts => '-F 0x4 -f 0x20', bamLoc => 'hsa-mir-21');
   ok( $res,                               "MirStats->new(bam=>bamFile) ok" );
   isa_ok( $res, 'MirStats',               "  isa MirStats" );
   is( $res->{bam}, $bamF,                 "  bam '$bamF'" );
   is( $res->{bamOpts}, '-F 0x4 -f 0x20',  "  bamOpts -F 0x4 -F 0x4 -f 0x20" );
   is( $res->{bamLoc}, 'hsa-mir-21',       "  bamLoc hsa-mir-21" );
   is( $res->{minOlap}, 10,                "  minOlap 10" );
   is( $res->{margin}, 1,                  "  minOlap 1" );
   is( $res->{mirInfo}, undef,             "  mirInfo undef" );
   is( $res->{stats}->{nAlign}, undef,     "  nAlign undef" );
   is( $res->getObjects('hairpin'), undef, "  no hairpin objects" );
}

sub d10_MirStats_newFromBamLoc_base : Test(16) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $hInf = getGffInfo();

   # hsa-mir-636 with 1 alignment
   my $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-636');  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-636') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 1,            "  nAlign 1" );
   is( $res->getObjects('hairpin'), 1,        "  has 1 hairpin stats object" ); 

   # hsa-mir-636 with 1 alignment
   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-6807');  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-6807') lives";   
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 2,            "  nAlign 2" );
   is( $res->getObjects('hairpin'), 1,        "  has 1 hairpin stats object" );

   # hsa-mir-636 with 1 alignment
   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-504');  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-504') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 3,            "  nAlign 3" );
   is( $res->getObjects('hairpin'), 1,        "  has 1 hairpin stats objects" );

   # all 3
   $res = undef;
   my $locStr = 'hsa-mir-6807 hsa-mir-636 hsa-mir-504';
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => $locStr);  }          
                                              "MirStats->newFromBam(bamLoc=>'$locStr') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 6,            "  nAlign 6" );
   is( $res->getObjects('hairpin'), 3,        "  has 3 hairpin stats objects" );

}
sub d11_MirStats_newFromBamLoc_hairpin : Test(100) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $hInf = getGffInfo();
   my ($res, $obj);

   my $locStr = 'hsa-mir-6807 hsa-mir-636 hsa-mir-504 hsa-mir-214';
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => $locStr);  }          
                                              "MirStats->newFromBam(bamLoc=>'$locStr') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 7,            "  nAlign 7" );
   is( $res->getObjects('hairpin'), 4,        "  has 4 hairpin stats objects" );

   # hsa-mir-6807 hairpin len 92; mature 5p len 22 [pos 1 - 22]; mature 3p len 23 [pos 70 - 92]
   #   chr19 hairpin 59061652 59061743 + ID=MI0022652;Alias=MI0022652;Name=hsa-mir-6807
   #   chr19 mature  59061652 59061673 + ID=MIMAT0027514;Alias=MIMAT0027514;Name=hsa-miR-6807-5p;Derives_from=MI0022652
   #   chr19 mature  59061721 59061743 + ID=MIMAT0027515;Alias=MIMAT0027515;Name=hsa-miR-6807-3p;Derives_from=MI0022652
   # 2 alignments: 5p: len 19 [pos 1 - 19], olap 19;  3p: len 9+1+7=17 [pos 58 - 84] olap 84-70+1=15
   #   HWI-ST975:100:D0D00ABXX:5:1215:9975:3028   0x400 hsa-mir-6807   1  24  6S19M         ... NM:i:0 MD:Z:19
   #   HWI-ST975:100:D0D00ABXX:5:1207:10787:58326 0x400 hsa-mir-6807  58  22  63S9M1D17M12S ... NM:i:3 MD:Z:2C6^A2C14 XO:i:1
   $obj = $res->{hairpin}->{'hsa-mir-6807'};
   is( ref($obj),      'HASH',                "hsa-mir-6807 hairpin stats" );
   is( $obj->{name},   'hsa-mir-6807',        "  name hsa-mir-6807" );
   is( $obj->{rank},       2,                 "  rank      2" );
   is( $obj->{count},      2,                 "  count     2" );
   is( $obj->{dup},        2,                 "  dup       2" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        1,                 "  mm0       1" );
   is( $obj->{mm1},        0,                 "  mm1       0" );
   is( $obj->{mm2},        1,                 "  mm2       1" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      1,                 "  indel     1" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  2,                 "  mq20-29   2" );
   is( $obj->{mq30p},      0,                 "  mq30p     0" );
   is( $obj->{'5pOnly'},   1,                 "  5pOnly    1" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus    1" );
   is( $obj->{'5and3p'},   0,                 "  5and3p    0" );
   is( $obj->{totBase},   46,                 "  totBase  46" );
   is( $obj->{'5pBase'},  19,                 "  5pBase   19" );
   is( $obj->{'3pBase'},  15,                 "  3pBase   15" );
   is( ref($obj->{hairpin}), 'HASH',          "  has MirInfo hairpin" );

   # hsa-mir-636 hairpin len 99; mature is len 23 [pos 61-83], will be called 3p (- strand)
   #   chr17 hairpin 74732532 74732630 - ID=MI0003651;Alias=MI0003651;Name=hsa-mir-636
   #   chr17 mature  74732548 74732570 - ID=MIMAT0003306;Alias=MIMAT0003306;Name=hsa-miR-636;Derives_from=MI0003651
   # alignment: 3p: len 40 [pos 45-84] olap 23
   #   HWI-ST975:100:D0D00ABXX:5:2105:14537:73905 0x400 hsa-mir-636  45  42  6S40M ... NM:i:0 MD:Z:40
   $obj = $res->{hairpin}->{'hsa-mir-636'};
   is( ref($obj),      'HASH',                "hsa-mir-636 hairpin stats" );
   cmp_ok( $obj->{rank}, '>=', 3,             "  rank   >= 3" );
   is( $obj->{name},   'hsa-mir-636',         "  name hsa-mir-636" );
   is( $obj->{count},      1,                 "  count     1" );
   is( $obj->{dup},        1,                 "  dup       1" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        1,                 "  mm0       1" );
   is( $obj->{mm1},        0,                 "  mm1       0" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   1" );
   is( $obj->{mq30p},      1,                 "  mq30p     1" );
   is( $obj->{'5pOnly'},   0,                 "  5pOnly    0" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus    1" );
   is( $obj->{'5and3p'},   0,                 "  5and3p    0" );
   is( $obj->{totBase},   40,                 "  totBase  40" );
   is( $obj->{'5pBase'},   0,                 "  5pBase    0" );
   is( $obj->{'3pBase'},  23,                 "  3pBase   23" ); 
   is( ref($obj->{hairpin}), 'HASH',          "  has MirInfo hairpin" );

   # hsa-mir-504 hairpin len 83; mature 5p len 22 [pos 13-34]; mature 3p len 21 [pos 50-70]
   #   chrX hairpin 137749872 137749954 - ID=MI0003189;Alias=MI0003189;Name=hsa-mir-504
   #   chrX mature  137749921 137749942 - ID=MIMAT0002875;Alias=MIMAT0002875;Name=hsa-miR-504-5p;Derives_from=MI0003189
   #   chrX mature  137749885 137749905 - ID=MIMAT0026612;Alias=MIMAT0026612;Name=hsa-miR-504-3p;Derives_from=MI0003189
   # 3 alignments; len 29 [7-35] 5p olap 22; len 23 [12-34] 5p olap 22; len 37 [35-71] 3p olap 21
   #               only the 2nd looks like real mature
   #   HWI-ST975:100:D0D00ABXX:5:2203:17382:62419      0x400   hsa-mir-504     7       42      29M   ... NM:i:1 MD:Z:4G24
   #   HWI-ST975:100:D0D00ABXX:5:2203:15604:65576      0x400   hsa-mir-504     12      36      5S23M ... NM:i:0 MD:Z:23
   #   HWI-ST975:100:D0D00ABXX:5:2208:8803:3457        0x400   hsa-mir-504     35      42      6S37M ... NM:i:0 MD:Z:37
   $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{name},   'hsa-mir-504',         "  name hsa-mir-504" );
   is( $obj->{rank},       1,                 "  rank      1" );
   is( $obj->{count},      3,                 "  count     3" );
   is( $obj->{dup},        3,                 "  dup       3" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        2,                 "  mm0       2" );
   is( $obj->{mm1},        1,                 "  mm1       1" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   0" );
   is( $obj->{mq30p},      3,                 "  mq30p     3" ); 
   is( $obj->{'5pOnly'},   1,                 "  5pOnly    1" );
   is( $obj->{'5pPlus'},   1,                 "  5pPlus    1" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus    1" );
   is( $obj->{'5and3p'},   0,                 "  5and3p    0" ); 
   is( $obj->{totBase},   (29+23+37),         "  totBase  89" );
   is( $obj->{'5pBase'},  44,                 "  5pBase   44" );
   is( $obj->{'3pBase'},  21,                 "  3pBase   21" );
   is( ref($obj->{hairpin}), 'HASH',          "  has MirInfo hairpin" );

   # hsa-mir-214 hairpin len 110; mature 5p len 22 [pos 30-51]; mature 3p len 22 [pos 71-92]
   #   chr1 hairpin 172107938 172108047 - ID=MI0000290;Alias=MI0000290;Name=hsa-mir-214
   #   chr1 mature  172107997 172108018 - ID=MIMAT0004564;Alias=MIMAT0004564;Name=hsa-miR-214-5p;Derives_from=MI0000290
   #   chr1 mature  172107956 172107977 - ID=MIMAT0000271;Alias=MIMAT0000271;Name=hsa-miR-214-3p;Derives_from=MI0000290
   # 1 alignment to - strand; len 23 [29-51] 5p olap 22; 
   #   HWI-ST975:100:D0D00ABXX:5:1208:18477:30142  0x410  hsa-mir-214     29      1       1S23M5S ... NM:i:0 MD:Z:23
   #                       seq: A CTGCCTGTCTACACTTGCTGTGC GCCTT
   # GGCCTGGCTGGACAGAGTTGTCATGTGT CTGCCTGTCTACACTTGCTGTGC AGAACATCCGCTCACCTGTACAGCAGGCACAGACAGGCAGTCACATGACAACCCAGCCT
   $obj = $res->{hairpin}->{'hsa-mir-214'};
   is( ref($obj),      'HASH',                "hsa-mir-214 hairpin stats" );
   cmp_ok( $obj->{rank}, '>=', 3,             "  rank   >= 3" );
   is( $obj->{name},   'hsa-mir-214',         "  name hsa-mir-214" );
   is( $obj->{count},      1,                 "  count     1" );
   is( $obj->{dup},        1,                 "  dup       1" );
   is( $obj->{oppStrand},  1,                 "  oppStrand 1" );
   is( $obj->{mm0},        1,                 "  mm0       1" );
   is( $obj->{mm1},        0,                 "  mm1       0" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   1,                 "  mq1-19    1" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   0" );
   is( $obj->{mq30p},      0,                 "  mq30p     0" ); 
   is( $obj->{'5pOnly'},   1,                 "  5pOnly    1" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus    0" );
   is( $obj->{'5and3p'},   0,                 "  5and3p    0" ); 
   is( $obj->{totBase},   23,                 "  totBase  23" );
   is( $obj->{'5pBase'},  22,                 "  5pBase   22" );
   is( $obj->{'3pBase'},   0,                 "  3pBase    0" );
   is( ref($obj->{hairpin}), 'HASH',          "  has MirInfo hairpin" );
}
sub d12_MirStats_newFromBamLoc_mature : Test(70) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $hInf = getGffInfo();
   my ($res, $obj);

   # use relaxed margin parameter to capture a few less-than-optimal alignments
   my $locStr = 'hsa-mir-6807 hsa-mir-504 hsa-mir-214';
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => $locStr, margin => 10);  }          
                                              "MirStats->newFromBam(bamLoc=>'$locStr') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{margin}, 10,                    "  margin 10" );
   is( $res->getObjects('hairpin'), 3,        "  has 3 hairpin stats objects" );
   is( $res->getObjects('mature'),  3,        "  has 3 mature locus stats objects" );
   is( $res->{stats}->{nGoodMat},   4,        "  nGoodMat 4" );

   # hsa-mir-636 hairpin len 99; mature is len 23 [pos 61-83], will be called 3p (- strand)
   #   chr17 hairpin 74732532 74732630 - ID=MI0003651;Alias=MI0003651;Name=hsa-mir-636
   #   chr17 mature  74732548 74732570 - ID=MIMAT0003306;Alias=MIMAT0003306;Name=hsa-miR-636;Derives_from=MI0003651
   # alignment: 3p: len 40 [pos 45-84] olap 23, not good fit
   #   HWI-ST975:100:D0D00ABXX:5:2105:14537:73905 0x400 hsa-mir-636  45  42  6S40M ... NM:i:0 MD:Z:40
   ok(!ref($res->{mature}->{'MI0003651'}),    "no MI0003651 hsa-miR-636 matseq object" ); 

   # hsa-mir-6807 hairpin len 92; mature 5p len 22 [pos 1 - 22]; mature 3p len 23 [pos 70 - 92]
   #   chr19 hairpin 59061652 59061743 + ID=MI0022652;Alias=MI0022652;Name=hsa-mir-6807
   #   chr19 mature  59061652 59061673 + ID=MIMAT0027514;Alias=MIMAT0027514;Name=hsa-miR-6807-5p;Derives_from=MI0022652
   #   chr19 mature  59061721 59061743 + ID=MIMAT0027515;Alias=MIMAT0027515;Name=hsa-miR-6807-3p;Derives_from=MI0022652
   # 2 alignments: 5p: len 19 [pos 1 - 19], olap 19;  3p: len 9+1+7=17 [pos 58 - 84] olap 84-70+1=15
   #   HWI-ST975:100:D0D00ABXX:5:1215:9975:3028   0x400 hsa-mir-6807   1  24  6S19M         ... NM:i:0 MD:Z:19
   #   HWI-ST975:100:D0D00ABXX:5:1207:10787:58326 0x400 hsa-mir-6807  58  22  63S9M1D17M12S ... NM:i:3 MD:Z:2C6^A2C14 XO:i:1
   # the 3p alignment does not satisfy "good fit" criteria so will not be counted
   ok( !$res->{mature}->{'MIMAT0027515'},     "no MIMAT0027515 mature locus stats (3p)" );
   $obj = $res->{mature}->{'MIMAT0027514'};
   is( ref($obj),      'HASH',                "has MIMAT0027514 mature locus stats (5p)" );
   cmp_ok( $obj->{rank}, '>=', 2,             "  rank   >= 2" );
   is( $obj->{count},      1,                 "  count     1" ); 
   is( $obj->{dup},        1,                 "  dup       1" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        1,                 "  mm0       1" );
   is( $obj->{mm1},        0,                 "  mm1       0" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  1,                 "  mq20-29   1" );
   is( $obj->{mq30p},      0,                 "  mq30p     0" );
   is( $obj->{totBase},   19,                 "  totBase  19" );
   is( $obj->{id},     'MIMAT0027514',        "  id       MIMAT0027514");
   is( $obj->{alias},  'MIMAT0027514',        "  alias    MIMAT0027514");
   is( $obj->{name},   'hsa-miR-6807-5p',     "  name     hsa-miR-6807-5p");
   is( $obj->{dname},  'hsa-mir-6807(hsa-miR-6807-5p)',   "  dname    hsa-mir-6807(hsa-miR-6807-5p");
   is( ref($obj->{mature}), 'HASH',           "  has MirInfo mature locus obj" );

   # hsa-mir-504 hairpin len 83; mature 5p len 22 [pos 13-34]; mature 3p len 21 [pos 50-70]
   #   chrX hairpin 137749872 137749954 - ID=MI0003189;Alias=MI0003189;Name=hsa-mir-504
   #   chrX mature  137749921 137749942 - ID=MIMAT0002875;Alias=MIMAT0002875;Name=hsa-miR-504-5p;Derives_from=MI0003189
   #   chrX mature  137749885 137749905 - ID=MIMAT0026612;Alias=MIMAT0026612;Name=hsa-miR-504-3p;Derives_from=MI0003189
   # 3 alignments; len 29 [7-35] 3p olap 22; len 23 [12-34] 3p olap 22; len 37 [35-71] 5p olap 21
   #   HWI-ST975:100:D0D00ABXX:5:2203:17382:62419      0x400   hsa-mir-504     7       42      29M   ... NM:i:1 MD:Z:4G24
   #   HWI-ST975:100:D0D00ABXX:5:2203:15604:65576      0x400   hsa-mir-504     12      36      5S23M ... NM:i:0 MD:Z:23
   #   HWI-ST975:100:D0D00ABXX:5:2208:8803:3457        0x400   hsa-mir-504     35      42      6S37M ... NM:i:0 MD:Z:37
   # the 1st and 2nd (5p) alignments will satisfy "good fit" with our relaxed margin
   # the 1st alignment has a mismatch, but outside the mature region (so won't be counted)
   ok( !$res->{mature}->{'MIMAT0026612'},     "no MIMAT0026612 mature locus stats (3p)" );
   $obj = $res->{mature}->{'MIMAT0002875'};
   is( ref($obj),      'HASH',                "has MIMAT0002875 mature locus stats (5p)" ); 
   is( $obj->{rank},       1,                 "  rank      1" ); 
   is( $obj->{count},      2,                 "  count     2" );
   is( $obj->{dup},        2,                 "  dup       2" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        2,                 "  mm0       2" );
   is( $obj->{mm1},        0,                 "  mm1       1" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   0" );
   is( $obj->{mq30p},      2,                 "  mq30p     2" ); 
   is( $obj->{totBase},   44,                 "  totBase  44" );
   is( $obj->{id},     'MIMAT0002875',        "  id       MIMAT0002875");
   is( $obj->{alias},  'MIMAT0002875',        "  alias    MIMAT0002875");
   is( $obj->{name},   'hsa-miR-504-5p',      "  name     hsa-miR-504-5p");
   is( $obj->{dname},  'hsa-mir-504(hsa-miR-504-5p)',  "  dname    hsa-mir-504(hsa-miR-504-5p)");
   is( ref($obj->{mature}), 'HASH',           "  has MirInfo mature locus obj" );

   # hsa-mir-214 hairpin len 110; mature 5p len 22 [pos 30-51]; mature 3p len 22 [pos 71-92]
   #   chr1 hairpin 172107938 172108047 - ID=MI0000290;Alias=MI0000290;Name=hsa-mir-214
   #   chr1 mature  172107997 172108018 - ID=MIMAT0004564;Alias=MIMAT0004564;Name=hsa-miR-214-5p;Derives_from=MI0000290
   #   chr1 mature  172107956 172107977 - ID=MIMAT0000271;Alias=MIMAT0000271;Name=hsa-miR-214-3p;Derives_from=MI0000290
   # 1 alignment to - strand; len 23 [29-51] 5p olap 22; (good fit)
   #   HWI-ST975:100:D0D00ABXX:5:1208:18477:30142  0x410  hsa-mir-214     29      1       1S23M5S ... NM:i:0 MD:Z:23
   ok( !$res->{mature}->{'MIMAT0000271'},     "no MIMAT0000271 mature locus stats (3p)" );
   $obj = $res->{mature}->{'MIMAT0004564'};
   is( ref($obj),      'HASH',                "has MIMAT0004564 mature locus stats (5p)" ); 
   cmp_ok( $obj->{rank}, '>=', 2,             "  rank   >= 2" );
   is( $obj->{count},      1,                 "  count     1" );
   is( $obj->{dup},        1,                 "  dup       1" );
   is( $obj->{oppStrand},  1,                 "  oppStrand 1" );
   is( $obj->{mm0},        1,                 "  mm0       1" );
   is( $obj->{mm1},        0,                 "  mm1       0" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   1,                 "  mq1-19    1" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   0" );
   is( $obj->{mq30p},      0,                 "  mq30p     0" ); 
   is( $obj->{totBase},   22,                 "  totBase  22" );
   is( $obj->{id},     'MIMAT0004564',        "  id       MIMAT0004564");
   is( $obj->{alias},  'MIMAT0004564',        "  alias    MIMAT0004564");
   is( $obj->{name},   'hsa-miR-214-5p',      "  name     hsa-miR-214-5p");
   is( $obj->{dname},  'hsa-mir-214(hsa-miR-214-5p)',  "  dname    hsa-mir-214(hsa-miR-214-5p)");
   is( ref($obj->{mature}), 'HASH',           "  has MirInfo mature locus obj" );
}
sub d13_MirStats_newFromBamLoc_matseq_base : Test(67) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $hInf = getGffInfo();
   my ($res, $obj);

   my $locStr = 'hsa-mir-6807 hsa-mir-636 hsa-mir-504 hsa-mir-214';
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => $locStr, margin => 6);  }          
                                              "MirStats->newFromBam(bamLoc=>'$locStr') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->getObjects('hairpin'), 4,        "  has 4 hairpin stats objects" );
   is( $res->getObjects('mature'),  3,        "  has 3 mature locus stats objects" ); 
   is( $res->getObjects('matseq'),  3,        "  has 3 mature sequence stats objects" ); 
   is( $res->{stats}->{nGoodMat},   4,        "  nGoodMat 4" );

   # hsa-mir-636 hairpin len 99; mature is len 23 [pos 61-83], will be called 3p (- strand)
   #   chr17 hairpin 74732532 74732630 - ID=MI0003651;Alias=MI0003651;Name=hsa-mir-636
   #   chr17 mature  74732548 74732570 - ID=MIMAT0003306;Alias=MIMAT0003306;Name=hsa-miR-636;Derives_from=MI0003651
   # alignment: 3p: len 40 [pos 45-84] olap 23, not good fit
   #   HWI-ST975:100:D0D00ABXX:5:2105:14537:73905 0x400 hsa-mir-636  45  42  6S40M ... NM:i:0 MD:Z:40
   ok(!ref($res->{matseq}->{'MI0003651'}),    "no MI0003651 hsa-miR-636 matseq object" ); 

   # hsa-mir-6807 hairpin len 92; mature 5p len 22 [pos 1 - 22]; mature 3p len 23 [pos 70 - 92]
   #   chr19 hairpin 59061652 59061743 + ID=MI0022652;Alias=MI0022652;Name=hsa-mir-6807
   #   chr19 mature  59061652 59061673 + ID=MIMAT0027514;Alias=MIMAT0027514;Name=hsa-miR-6807-5p;Derives_from=MI0022652
   #   chr19 mature  59061721 59061743 + ID=MIMAT0027515;Alias=MIMAT0027515;Name=hsa-miR-6807-3p;Derives_from=MI0022652
   # 2 alignments: 5p: len 19 [pos 1 - 19], olap 19;  3p: len 9+1+7=17 [pos 58 - 84] olap 84-70+1=15
   #   HWI-ST975:100:D0D00ABXX:5:1215:9975:3028   0x400 hsa-mir-6807   1  24  6S19M         ... NM:i:0 MD:Z:19
   #   HWI-ST975:100:D0D00ABXX:5:1207:10787:58326 0x400 hsa-mir-6807  58  22  63S9M1D17M12S ... NM:i:3 MD:Z:2C6^A2C14 XO:i:1
   # the 3p alignment does not satisfy "good fit" criteria so will not be counted
   ok( !$res->{matseq}->{'MIMAT0027515'},     "no MIMAT0027515 matseq stats (3p)" );
   $obj = $res->{matseq}->{'MIMAT0027514'};
   is( ref($obj),      'HASH',                "has MIMAT0027514 matseq stats (5p)" ); 
   cmp_ok( $obj->{rank}, '>=', 2,             "  rank   >= 2" );
   is( $obj->{count},      1,                 "  count     1" ); 
   is( $obj->{dup},        1,                 "  dup       1" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        1,                 "  mm0       1" );
   is( $obj->{mm1},        0,                 "  mm1       0" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  1,                 "  mq20-29   1" );
   is( $obj->{mq30p},      0,                 "  mq30p     0" );
   is( $obj->{totBase},   19,                 "  totBase  19" );
   is( $obj->{id},      'MIMAT0027514',       "  id       MIMAT0027514");
   is( $obj->{name},    'hsa-miR-6807-5p',    "  name     hsa-miR-6807-5p");
   is( $obj->{dname},   'hsa-miR-6807-5p[1]', "  dname    hsa-miR-6807-5p[1]"); 
   is( ref($obj->{matseq}), 'HASH',           "  has MirInfo matseq obj" );  

   # hsa-mir-504 hairpin len 83; mature 5p len 22 [pos 13-34]; mature 3p len 21 [pos 50-70]
   #   chrX hairpin 137749872 137749954 - ID=MI0003189;Alias=MI0003189;Name=hsa-mir-504
   #   chrX mature  137749921 137749942 - ID=MIMAT0002875;Alias=MIMAT0002875;Name=hsa-miR-504-5p;Derives_from=MI0003189
   #   chrX mature  137749885 137749905 - ID=MIMAT0026612;Alias=MIMAT0026612;Name=hsa-miR-504-3p;Derives_from=MI0003189
   # 3 alignments; len 29 [7-35] 3p olap 22; len 23 [12-34] 3p olap 22; len 37 [35-71] 5p olap 21
   #   HWI-ST975:100:D0D00ABXX:5:2203:17382:62419      0x400   hsa-mir-504     7       42      29M   ... NM:i:1 MD:Z:4G24
   #   HWI-ST975:100:D0D00ABXX:5:2203:15604:65576      0x400   hsa-mir-504     12      36      5S23M ... NM:i:0 MD:Z:23
   #   HWI-ST975:100:D0D00ABXX:5:2208:8803:3457        0x400   hsa-mir-504     35      42      6S37M ... NM:i:0 MD:Z:37
   # the 1st and 2nd (5p) alignments will satisfy "good fit" with our relaxed margin
   # the 1st alignment has a mismatch, but outside the mature region (so won't be counted)
   ok( !$res->{matseq}->{'MIMAT0026612'},     "no MIMAT0026612 matseq stats (3p)" );
   $obj = $res->{matseq}->{'MIMAT0002875'};
   is( ref($obj),      'HASH',                "has MIMAT0002875 matseq stats (5p)" ); 
   is( $obj->{rank},       1,                 "  rank      1" );
   is( $obj->{count},      2,                 "  count     2" );
   is( $obj->{dup},        2,                 "  dup       2" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        2,                 "  mm0       2" );
   is( $obj->{mm1},        0,                 "  mm1       1" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   0" );
   is( $obj->{mq30p},      2,                 "  mq30p     2" ); 
   is( $obj->{totBase},   44,                 "  totBase  44" );
   is( $obj->{id},      'MIMAT0002875',       "  id       MIMAT0002875");
   is( $obj->{name},    'hsa-miR-504-5p',     "  name     hsa-miR-504-5p");
   is( $obj->{dname},   'hsa-miR-504-5p[1]',  "  dname    hsa-miR-504-5p[1]"); 
   is( ref($obj->{matseq}), 'HASH',           "  has MirInfo matseq obj" );  

   # hsa-mir-214 hairpin len 110; mature 5p len 22 [pos 30-51]; mature 3p len 22 [pos 71-92]
   #   chr1 hairpin 172107938 172108047 - ID=MI0000290;Alias=MI0000290;Name=hsa-mir-214
   #   chr1 mature  172107997 172108018 - ID=MIMAT0004564;Alias=MIMAT0004564;Name=hsa-miR-214-5p;Derives_from=MI0000290
   #   chr1 mature  172107956 172107977 - ID=MIMAT0000271;Alias=MIMAT0000271;Name=hsa-miR-214-3p;Derives_from=MI0000290
   # 1 alignment to - strand; len 23 [29-51] 5p olap 22; (good fit)
   #   HWI-ST975:100:D0D00ABXX:5:1208:18477:30142  0x410  hsa-mir-214     29      1       1S23M5S ... NM:i:0 MD:Z:23
   ok( !$res->{matseq}->{'MIMAT0000271'},     "no MIMAT0000271 matseq stats (3p)" );
   $obj = $res->{matseq}->{'MIMAT0004564'};
   is( ref($obj),      'HASH',                "has MIMAT0004564 matseq stats (5p)" ); 
   cmp_ok( $obj->{rank}, '>=', 2,             "  rank   >= 2" );
   is( $obj->{count},      1,                 "  count     1" );
   is( $obj->{dup},        1,                 "  dup       1" );
   is( $obj->{oppStrand},  1,                 "  oppStrand 1" );
   is( $obj->{mm0},        1,                 "  mm0       1" );
   is( $obj->{mm1},        0,                 "  mm1       0" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   1,                 "  mq1-19    1" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   0" );
   is( $obj->{mq30p},      0,                 "  mq30p     0" ); 
   is( $obj->{totBase},   22,                 "  totBase  22" );
   is( $obj->{id},     'MIMAT0004564',        "  id       MIMAT0004564");
   is( $obj->{name},   'hsa-miR-214-5p',      "  name     hsa-miR-214-5p");
   is( $obj->{dname},  'hsa-miR-214-5p[1]',   "  dname    hsa-miR-214-5p[1]"); 
   is( ref($obj->{matseq}), 'HASH',           "  has MirInfo matseq obj" );
}

sub d21_MirStats_newFromBamLoc_coverage : Test(175) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfo();
   my ($res, $obj, $cov);

   # hsa-mir-636: 1 alignment: len 40 [pos 45 - 84] 
   #   HWI-ST975:100:D0D00ABXX:5:2105:14537:73905      0x400   hsa-mir-636     45      42      6S40M ... NM:i:0 MD:Z:40
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-636');  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-636') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 1,            "  nAlign 1" );
   $obj = $res->{hairpin}->{'hsa-mir-636'};
   is( ref($obj),      'HASH',                "hsa-mir-636 hairpin stats" );
   is( $obj->{count},      1,                 "  count    1" );
   is( $obj->{totBase},   40,                 "  totBase 40" );
   $cov = $obj->{coverage};
   is( ref($cov),      'ARRAY',               "  coverage ARRAY ref" );
   cmp_ok( @$cov,      '>=',  84,             "    length >= 84" );
   for (my $ix=0; $ix<=84; $ix++) {
      if ($ix < 45) {
         is( $cov->[$ix], undef,              "    pos $ix undef" );
      } else {
         is( $cov->[$ix], 1,                  "    pos $ix 1" );
      }
   }

   # hsa-mir-504: 3 alignments; lens 29 [7-35], 23 [12-34], 37 [35-71]; 
   #   HWI-ST975:100:D0D00ABXX:5:2203:17382:62419      0x400   hsa-mir-504     7       42      29M   ... NM:i:1 MD:Z:4G24
   #   HWI-ST975:100:D0D00ABXX:5:2203:15604:65576      0x400   hsa-mir-504     12      36      5S23M ... NM:i:0 MD:Z:23
   #   HWI-ST975:100:D0D00ABXX:5:2208:8803:3457        0x400   hsa-mir-504     35      42      6S37M ... NM:i:0 MD:Z:37
   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-504');  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-504') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 3,            "  nAlign 3" );
   $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{count},      3,                 "  count    3" );
   is( $obj->{totBase},    29+23+37,          "  totBase  " . (29+23+37) . "");
   $cov = $obj->{coverage};
   is( ref($cov),      'ARRAY',               "  coverage ARRAY ref" );
   cmp_ok( @$cov,      '>=',  71,             "    length >= 71" );
   
   my $expected = []; 
   for (my $ix=7; $ix<=35; $ix++)  { $expected->[$ix] = ($expected->[$ix] || 0) + 1; }
   for (my $ix=12; $ix<=34; $ix++) { $expected->[$ix] = ($expected->[$ix] || 0) + 1; }
   for (my $ix=35; $ix<=71; $ix++) { $expected->[$ix] = ($expected->[$ix] || 0) + 1; }
   for (my $ix=0; $ix<=@$expected; $ix++) {
      is( $cov->[$ix], $expected->[$ix],       "    pos $ix " . ( $expected->[$ix] || 'undef') . "");
   }
   #diag("expect (@$expected)");
   #diag("got    (@$cov)");
}

sub d31_MirStats_newFromBamLoc_params : Test(67) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfo();
   my ($res, $obj);

   # hsa-mir-22: hairpin is len 85; mature 5p len 22 [pos 15-36]; mature 3p len 22 [pos 53-74]
   #   chr17 hairpin 1617197 1617281 - ID=MI0000078;Alias=MI0000078;Name=hsa-mir-22
   #   chr17 mature  1617246 1617267 - ID=MIMAT0004495;Alias=MIMAT0004495;Name=hsa-miR-22-5p;Derives_from=MI0000078
   #   chr17 mature  1617208 1617229 - ID=MIMAT0000077;Alias=MIMAT0000077;Name=hsa-miR-22-3p;Derives_from=MI0000078
   # 28 total alignments
   #  5p (3): lens and olaps 21,22,19 with [pos 15 - ] 
   #        HWI-ST975:100:D0D00ABXX:5:1115:16289:27812 0x400   hsa-mir-22  15  28  6S21M    ... NM:i:0 MD:Z:21
   #        HWI-ST975:100:D0D00ABXX:5:1216:12453:79212 0x400   hsa-mir-22  15  28  6S22M2S  ... NM:i:0 MD:Z:22
   #        HWI-ST975:100:D0D00ABXX:5:2108:8469:65000  0x400   hsa-mir-22  15  22  6S19M2S  ... NM:i:0 MD:Z:19
   #  3p: 23 are len 22 [pos 53 - 74] (olap 19), like the following:
   #    21: HWI-ST975:100:D0D00ABXX:5:1111:10324:78799 0x400   hsa-mir-22  53  36  6S22M    ... NM:i:0 MD:Z:22
   #     1: HWI-ST975:100:D0D00ABXX:5:1106:18948:89738 0x400   hsa-mir-22  53  22  6S22M    ... NM:i:0 MD:Z:18C3
   #   2 others: 
   #        HWI-ST975:100:D0D00ABXX:5:1105:6167:89483  0x400   hsa-mir-22  53  22  6S19M2S  ... NM:i:0 MD:Z:19
   #        HWI-ST975:100:D0D00ABXX:5:2115:6748:64397  0x400   hsa-mir-22  53  28  6S21M1S  ... NM:i:0 MD:Z:21

   # Use default parameters for minOlap (13), margin (5)
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-22');  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-22') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 28,           "  nAlign 28" );
   $obj = $res->{hairpin}->{'hsa-mir-22'};
   is( ref($obj),      'HASH',                "hsa-mir-22 hairpin stats" );
   is( $obj->{name},   'hsa-mir-22',          "  name hsa-mir-22" );
   is( $obj->{rank},       1,                 "  rank     1" );
   is( $obj->{count},     28,                 "  count   28" );
   is( $obj->{dup},       28,                 "  dup     28" ); 
   is( $obj->{mm0},       27,                 "  mm0     27" );
   is( $obj->{mm1},        1,                 "  mm1      1" );
   is( $obj->{mm2},        0,                 "  mm2      0" );
   is( $obj->{mm3p},       0,                 "  mm3p     0" );
   is( $obj->{indel},      0,                 "  indel    0" );
   is( $obj->{mq0},        0,                 "  mq0      0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19   0" );
   is( $obj->{'mq20-29'},  8,                 "  mq20-29  8" );
   is( $obj->{mq30p},     20,                 "  mq30p   20" ); 

   is( $obj->{'5pOnly'},   3,                 "  5pOnly   3" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus   0" );
   is( $obj->{'3pOnly'},  25,                 "  3pOnly  25" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus   0" );
   is( $obj->{'5and3p'},   0,                 "  5and3p   0" );  

   # Use stringent minOlap parameter for mature sequence alignment counts
   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-22',
                                          minOlap => 22,margin => 0);  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-22' minOlap=>22, margin=>0) lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 28,           "  nAlign 28" );
   $obj = $res->{hairpin}->{'hsa-mir-22'};
   is( ref($obj),      'HASH',                "hsa-mir-22 hairpin stats" );
   is( $obj->{name},   'hsa-mir-22',         "  name hsa-mir-22" );
   is( $obj->{rank},       1,                 "  rank     1" );
   is( $obj->{count},     28,                 "  count   28" );
   is( $obj->{dup},       28,                 "  dup     28" ); 
   is( $obj->{mm0},       27,                 "  mm0     27" );
   is( $obj->{mm1},        1,                 "  mm1      1" );
   is( $obj->{mm2},        0,                 "  mm2      0" );
   is( $obj->{mm3p},       0,                 "  mm3p     0" );
   is( $obj->{indel},      0,                 "  indel    0" );
   is( $obj->{mq0},        0,                 "  mq0      0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19   0" );
   is( $obj->{'mq20-29'},  8,                 "  mq20-29  8" );
   is( $obj->{mq30p},     20,                 "  mq30p   20" ); 
   
   is( $obj->{'5pOnly'},   1,                 "  5pOnly   1" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus   0" );
   is( $obj->{'3pOnly'},  23,                 "  3pOnly  23" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus   0" );
   is( $obj->{'5and3p'},   0,                 "  5and3p   0" );

   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-22',
                                          minOlap => 20, margin => 0);  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-22' minOlap=>20, margin=>0) lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 28,           "  nAlign 28" );
   $obj = $res->{hairpin}->{'hsa-mir-22'};
   is( ref($obj),      'HASH',                "hsa-mir-22 hairpin stats" );
   is( $obj->{name},   'hsa-mir-22',         "  name hsa-mir-22" );
   is( $obj->{rank},       1,                 "  rank     1" );
   is( $obj->{count},     28,                 "  count   28" );
   is( $obj->{dup},       28,                 "  dup     28" ); 
   is( $obj->{mm0},       27,                 "  mm0     27" );
   is( $obj->{mm1},        1,                 "  mm1      1" );
   is( $obj->{mm2},        0,                 "  mm2      0" );
   is( $obj->{mm3p},       0,                 "  mm3p     0" );
   is( $obj->{indel},      0,                 "  indel    0" );
   is( $obj->{mq0},        0,                 "  mq0      0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19   0" );
   is( $obj->{'mq20-29'},  8,                 "  mq20-29  8" );
   is( $obj->{mq30p},     20,                 "  mq30p   20" ); 
   
   is( $obj->{'5pOnly'},   2,                 "  5pOnly   2" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus   0" );
   is( $obj->{'3pOnly'},  24,                 "  3pOnly  24" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus   0" );
   is( $obj->{'5and3p'},   0,                 "  5and3p   0" );
}
sub d32_MirStats_newFromBamLoc_params2 : Test(57) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfo();
   my ($res, $obj);

   # Use default parameters for minOlap (13), margin (5)
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-504');  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-504') lives";
   return("error") if !$res;  
   $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{name},   'hsa-mir-504',         "  name hsa-mir-504" );
   is( $obj->{count},      3,                 "  count    3" );
   is( $obj->{mm0},        2,                 "  mm0      2" );
   is( $obj->{mm1},        1,                 "  mm1      1" );
   is( $obj->{'5pOnly'},   1,                 "  5pOnly   1" );
   is( $obj->{'5pPlus'},   1,                 "  5pPlus   1" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly   0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus   1" );
   is( $obj->{'5and3p'},   0,                 "  5and3p   0" ); 
   is( $obj->{totBase},   (29+23+37),         "  totBase 89" );
   is( $obj->{'5pBase'},  44,                 "  5pBase  44" );
   is( $obj->{'3pBase'},  21,                 "  3pBase  21" ); 

   # hsa-mir-504 hairpin len 83; mature 5p len 22 [pos 13-34]; mature 3p len 21 [pos 50-70]
   #   chrX hairpin 137749872 137749954 - ID=MI0003189;Alias=MI0003189;Name=hsa-mir-504
   #   chrX mature  137749921 137749942 - ID=MIMAT0002875;Alias=MIMAT0002875;Name=hsa-miR-504-5p;Derives_from=MI0003189
   #   chrX mature  137749885 137749905 - ID=MIMAT0026612;Alias=MIMAT0026612;Name=hsa-miR-504-3p;Derives_from=MI0003189
   # 3 alignments; len 29 [7-35] 5p olap 22; len 23 [12-34] 5p olap 22; len 37 [35-71] 3p olap 21
   #               only the 2nd looks like real mature
   #   HWI-ST975:100:D0D00ABXX:5:2203:17382:62419      0x400   hsa-mir-504     7       42      29M   ... NM:i:1 MD:Z:4G24
   #   HWI-ST975:100:D0D00ABXX:5:2203:15604:65576      0x400   hsa-mir-504     12      36      5S23M ... NM:i:0 MD:Z:23
   #   HWI-ST975:100:D0D00ABXX:5:2208:8803:3457        0x400   hsa-mir-504     35      42      6S37M ... NM:i:0 MD:Z:37
   
   # Use more stringent minOlap parameter; the length 21 3p alignment will not be counted in 3pOnly
   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-504', minOlap => 22);  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-504' minOlap=>22) lives";
   return("error") if !$res;  
   $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{name},   'hsa-mir-504',         "  name hsa-mir-504" );
   is( $obj->{count},      3,                 "  count    3" );
   is( $obj->{mm0},        2,                 "  mm0      2" );
   is( $obj->{mm1},        1,                 "  mm1      1" );
   is( $obj->{'5pOnly'},   1,                 "  5pOnly   1" );
   is( $obj->{'5pPlus'},   1,                 "  5pPlus   1" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly   0" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus   0" );
   is( $obj->{'5and3p'},   0,                 "  5and3p   0" ); 
   is( $obj->{totBase},   (29+23+37),         "  totBase 89" );
   is( $obj->{'5pBase'},  44,                 "  5pBase  44" );
   is( $obj->{'3pBase'},  21,                 "  3pBase  21" ); 
   
   # Use more stringent margin parameter; will shift the 5pOnly to 5pPlus
   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-504', minOlap => 22, margin => 0);  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-504' minOlap => 22 margin=>0) lives";
   return("error") if !$res;  
   $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{name},   'hsa-mir-504',         "  name hsa-mir-504" );
   is( $obj->{count},      3,                 "  count    3" );
   is( $obj->{mm0},        2,                 "  mm0      2" );
   is( $obj->{mm1},        1,                 "  mm1      1" );
   is( $obj->{'5pOnly'},   0,                 "  5pOnly   0" );
   is( $obj->{'5pPlus'},   2,                 "  5pPlus   2" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly   0" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus   0" );
   is( $obj->{'5and3p'},   0,                 "  5and3p   0" ); 
   is( $obj->{totBase},   (29+23+37),         "  totBase 89" );
   is( $obj->{'5pBase'},  44,                 "  5pBase  44" );
   is( $obj->{'3pBase'},  21,                 "  3pBase  21" );
   
   # Use less stringent margin parameter; will shift the 5pPlus to 5pOnly
   $res = undef;
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-504', minOlap => 22, margin => 6);  }          
                                              "MirStats->newFromBam(bamLoc=>'hsa-mir-504' minOlap => 22 margin=>6) lives";
   return("error") if !$res;  
   $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{name},   'hsa-mir-504',         "  name hsa-mir-504" );
   is( $obj->{count},      3,                 "  count    3" );
   is( $obj->{mm0},        2,                 "  mm0      2" );
   is( $obj->{mm1},        1,                 "  mm1      1" );
   is( $obj->{'5pOnly'},   2,                 "  5pOnly   2" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus   0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly   0" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus   0" );
   is( $obj->{'5and3p'},   0,                 "  5and3p   0" ); 
   is( $obj->{totBase},   (29+23+37),         "  totBase 89" );
   is( $obj->{'5pBase'},  44,                 "  5pBase  44" );
   is( $obj->{'3pBase'},  21,                 "  3pBase  21" );
}

sub d41_MirStats_newFromBamLocs_hp_groups : Test(37) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfoFull();
   my ($res);

   # hsa-mir-105-1 and hsa-mir-105-2 form a transript group hsa-mir-105[2] and matseq groups hsa-miR-105-5p[2] hsa-miR-105-3p[2]
   #   chrX hairpin 151560691 151560771 - ID=MI0000111;Alias=MI0000111;Name=hsa-mir-105-1
   #   chrX mature  151560737 151560759 - ID=MIMAT0000102;Alias=MIMAT0000102;Name=hsa-miR-105-5p;Derives_from=MI0000111
   #   chrX mature  151560700 151560721 - ID=MIMAT0004516;Alias=MIMAT0004516;Name=hsa-miR-105-3p;Derives_from=MI0000111
   #   chrX hairpin 151562884 151562964 - ID=MI0000112;Alias=MI0000112;Name=hsa-mir-105-2
   #   chrX mature  151562930 151562952 - ID=MIMAT0000102_1;Alias=MIMAT0000102;Name=hsa-miR-105-5p;Derives_from=MI0000112
   #   chrX mature  151562893 151562914 - ID=MIMAT0004516_1;Alias=MIMAT0004516;Name=hsa-miR-105-3p;Derives_from=MI0000112
   # test data has 36 alignments to hsa-mir-105-1, 24 to hsa-mir-105-2; all are "good fit" 5p
   lives_ok { $res = MirStats->newFromBamFull(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-105-1 hsa-mir-105-2');  }          
                                                "MirStats->newFromBam(bamLoc=>'hsa-mir-105-1 hsa-mir-105-2') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                    "  isa MirStats" );
   is( $res->getObjects('hairpin'), 2,          "  2 hairpin objects" );
   is( $res->getObjects('group'),   1,          "  1 group object" );
   is( $res->{stats}->{nAlign},    60,          "  nAlign    60" );
   is( $res->{stats}->{totBase}, 1418,          "  totBase 1418" );  

   my $hp1 = $res->{hairpin}->{'hsa-mir-105-1'};
   is( ref($hp1),       'HASH',                 "hsa-mir-105-1 hairpin" );
   is( $hp1->{name},    'hsa-mir-105-1',        "  name  hsa-mir-105-1" );
   is( $hp1->{rank},         1,                 "  rank       1" );
   is( $hp1->{count},       36,                 "  count     36" );
   is( $hp1->{'5pOnly'},    36,                 "  5pOnly    36" );
   is( $hp1->{'3pOnly'},     0,                 "  3pOnly     0" );
   is( $hp1->{totBase},    856,                 "  totBase  856" );
   is( $hp1->{'5pBase'},   814,                 "  5pBase   814" ); 
   is( $hp1->{'3pBase'},     0,                 "  3pBase     0" ); 
   is( ref($hp1->{hairpin}), 'HASH',            "  has MirInfo hairpin" );

   my $hp2 = $res->{hairpin}->{'hsa-mir-105-2'};
   is( ref($hp2),       'HASH',                 "hsa-mir-105-2 hairpin" );
   is( $hp2->{name},    'hsa-mir-105-2',        "  name  hsa-mir-105-2" );
   is( $hp2->{rank},         2,                 "  rank       2" );
   is( $hp2->{count},       24,                 "  count     24" );
   is( $hp2->{'5pOnly'},    24,                 "  5pOnly    24" );
   is( $hp2->{'3pOnly'},     0,                 "  3pOnly     0" );
   is( $hp2->{totBase},    562,                 "  totBase  562" );
   is( $hp2->{'5pBase'},   536,                 "  5pBase   536" );
   is( $hp2->{'3pBase'},     0,                 "  3pBase     0" ); 
   is( ref($hp2->{hairpin}), 'HASH',            "  has MirInfo hairpin" );

   my $hpg = $res->{group}->{'hsa-mir-105'};
   is( ref($hpg),       'HASH',                 "hsa-mir-105 group" ); 
   is( $hpg->{name},    'hsa-mir-105',          "  name  hsa-mir-105" );
   is( $hpg->{dname},   'hsa-mir-105[2]',       "  dname hsa-mir-105[2]" );
   is( $hpg->{count},       60,                 "  count     60" );
   is( $hpg->{'5pOnly'},    60,                 "  5pOnly    60" );
   is( $hpg->{'3pOnly'},     0,                 "  3pOnly     0" );
   is( $hpg->{totBase},   1418,                 "  totBase 1418" );
   is( $hpg->{'5pBase'},  1350,                 "  5pBase  1350" );  
   is( $hpg->{'3pBase'},     0,                 "  3pBase     0" );
   is( ref($hpg->{group}), 'HASH',              "  has MirInfo group" );
}
sub d42_MirStats_newFromBamLocs_mature_matseqs : Test(33) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfoFull();
   my ($res);

   # hsa-mir-105-1 and hsa-mir-105-2 form a transript group hsa-mir-105[2] and matseq groups hsa-miR-105-5p[2] hsa-miR-105-3p[2]
   #   chrX hairpin 151560691 151560771 - ID=MI0000111;Alias=MI0000111;Name=hsa-mir-105-1
   #   chrX mature  151560737 151560759 - ID=MIMAT0000102;Alias=MIMAT0000102;Name=hsa-miR-105-5p;Derives_from=MI0000111
   #   chrX mature  151560700 151560721 - ID=MIMAT0004516;Alias=MIMAT0004516;Name=hsa-miR-105-3p;Derives_from=MI0000111
   #   chrX hairpin 151562884 151562964 - ID=MI0000112;Alias=MI0000112;Name=hsa-mir-105-2
   #   chrX mature  151562930 151562952 - ID=MIMAT0000102_1;Alias=MIMAT0000102;Name=hsa-miR-105-5p;Derives_from=MI0000112
   #   chrX mature  151562893 151562914 - ID=MIMAT0004516_1;Alias=MIMAT0004516;Name=hsa-miR-105-3p;Derives_from=MI0000112
   # test data has 36 alignments to hsa-mir-105-1, 24 to hsa-mir-105-2; all are "good fit" 5p
   lives_ok { $res = MirStats->newFromBamFull(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-105-1 hsa-mir-105-2');  }          
                                                "MirStats->newFromBam(bamLoc=>'hsa-mir-105-1 hsa-mir-105-2') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                    "  isa MirStats" );
   is( $res->getObjects('hairpin'), 2,          "  2 hairpin objects" );
   is( $res->getObjects('mature'),  2,          "  2 mature locus object" );
   is( $res->getObjects('matseq'),  1,          "  1 matseq object" );
   is( $res->{stats}->{nAlign},    60,          "  nAlign    60" );
   is( $res->{stats}->{nGoodMat},  60,          "  nGoodMat  60" );  

   my $ma1 = $res->{mature}->{'MIMAT0000102'};
   is( ref($ma1),       'HASH',                          "MIMAT0000102 mature" );
   is( $ma1->{id},      'MIMAT0000102',                  "  id      MIMAT0000102" );
   is( $ma1->{name},    'hsa-miR-105-5p',                "  name    hsa-miR-105-5p" );
   is( $ma1->{dname},   'hsa-mir-105-1(hsa-miR-105-5p)', "  dname   hsa-mir-105-1(hsa-miR-105-5p)" );
   is( $ma1->{rank},             1,                      "  rank       1" );
   is( $ma1->{count},           36,                      "  count     36" );
   is( $ma1->{totBase},        814,                      "  totBase  814" );
   is( ref($ma1->{mature}), 'HASH',                      "  has MirInfo mature obj" ); 

   my $ma2 = $res->{mature}->{'MIMAT0000102_1'};
   is( ref($ma2),       'HASH',                          "MIMAT0000102_1 mature" );
   is( $ma2->{id},      'MIMAT0000102_1',                "  id      MIMAT0000102_1" );
   is( $ma2->{name},    'hsa-miR-105-5p',                "  name    hsa-miR-105-5p" );
   is( $ma2->{dname},   'hsa-mir-105-2(hsa-miR-105-5p)', "  dname   hsa-mir-105-1(hsa-miR-105-5p)" );
   is( $ma2->{rank},             2,                      "  rank       2" );
   is( $ma2->{count},           24,                      "  count     24" );
   is( $ma2->{totBase},        536,                      "  totBase  536" );
   is( ref($ma2->{mature}), 'HASH',                      "  has MirInfo mature obj" ); 

   ok(!$res->{matseq}->{'MIMAT0004516'},                 "no MIMAT0004516 hsa-miR-105-3p matseq" );
   my $ms3 = $res->{matseq}->{'MIMAT0000102'};
   is( ref($ms3),       'HASH',                          "MIMAT0000102 hsa-miR-105-5p matseq" ); 
   is( $ms3->{id},      'MIMAT0000102',                  "  id      MIMAT0000102" );
   is( $ms3->{name},    'hsa-miR-105-5p',                "  name  hsa-miR-105-5p" );
   is( $ms3->{dname},   'hsa-miR-105-5p[2]',             "  dname hsa-miR-105-5p[2]" );
   is( $ms3->{rank},         1,                          "  rank       1" );
   is( $ms3->{count},       60,                          "  count     60" );
   is( $ms3->{totBase},   1350,                          "  totBase 1350" );
   is( ref($ms3->{matseq}), 'HASH',                      "  has MirInfo matseq" );
}
sub d43_MirStats_newFromBamLocs_mature_mm : Test(51) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfoFull();
   my ($res);

   # hsa-mir-22: hairpin is len 85; mature 5p len 22 [pos 15-36]; mature 3p len 22 [pos 53-74]
   #   chr17 hairpin 1617197 1617281 - ID=MI0000078;Alias=MI0000078;Name=hsa-mir-22
   #   chr17 mature  1617246 1617267 - ID=MIMAT0004495;Alias=MIMAT0004495;Name=hsa-miR-22-5p;Derives_from=MI0000078
   #   chr17 mature  1617208 1617229 - ID=MIMAT0000077;Alias=MIMAT0000077;Name=hsa-miR-22-3p;Derives_from=MI0000078
   # 28 total alignments
   #  5p (3): lens and olaps 21,22,19 with [pos 15 - ] 
   #        HWI-ST975:100:D0D00ABXX:5:1115:16289:27812 0x400   hsa-mir-22  15  28  6S21M    ... NM:i:0 MD:Z:21
   #        HWI-ST975:100:D0D00ABXX:5:1216:12453:79212 0x400   hsa-mir-22  15  28  6S22M2S  ... NM:i:0 MD:Z:22
   #        HWI-ST975:100:D0D00ABXX:5:2108:8469:65000  0x400   hsa-mir-22  15  22  6S19M2S  ... NM:i:0 MD:Z:19
   #  3p: 23 are len 22 [pos 53 - 74] (olap 19), like the following:
   #    21: HWI-ST975:100:D0D00ABXX:5:1111:10324:78799 0x400   hsa-mir-22  53  36  6S22M    ... NM:i:0 MD:Z:22
   #     1: HWI-ST975:100:D0D00ABXX:5:1106:18948:89738 0x400   hsa-mir-22  53  22  6S22M    ... NM:i:0 MD:Z:18C3
   #   2 others: 
   #        HWI-ST975:100:D0D00ABXX:5:1105:6167:89483  0x400   hsa-mir-22  53  22  6S19M2S  ... NM:i:0 MD:Z:19
   #        HWI-ST975:100:D0D00ABXX:5:2115:6748:64397  0x400   hsa-mir-22  53  28  6S21M1S  ... NM:i:0 MD:Z:21
   # Alignment HWI-ST975:100:D0D00ABXX [53-74] has a mismatch at relative position 19, hp position 71
   #     1: HWI-ST975:100:D0D00ABXX:5:1106:18948:89738 0x400   hsa-mir-22  53  22  6S22M    ... NM:i:0 MD:Z:18C3
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-22');  }          
                                                         "MirStats->newFromBam(bamLoc=>'hsa-mir-22') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                             "  isa MirStats" );
   is( $res->{stats}->{nAlign},    28,                   "  nAlign   28" );
   is( $res->{stats}->{nGoodMat},  28,                   "  nGoodMat 28" );
   is( $res->getObjects('hairpin'), 1,                   "  has 1 hairpin stats obj" );
   is( $res->getObjects('mature'),  2,                   "  has 2 mature stats objs" );
   is( $res->getObjects('matseq'),  2,                   "  has 2 matseq stats objs" );

   my $obj = $res->{hairpin}->{'hsa-mir-22'};
   is( ref($obj),      'HASH',                           "hsa-mir-22 hairpin stats" );
   is( $obj->{name},   'hsa-mir-22',                     "  name hsa-mir-22" );
   is( $obj->{rank},       1,                            "  rank     1" );
   is( $obj->{count},     28,                            "  count   28" );
   is( $obj->{mm0},       27,                            "  mm0     27" );
   is( $obj->{mm1},        1,                            "  mm1      1" );
   is( $obj->{indel},      0,                            "  indel    0" );
   is( $obj->{'5pOnly'},   3,                            "  5pOnly   3" );
   is( $obj->{'3pOnly'},  25,                            "  3pOnly  25" ); 

   my $mat = $res->{mature}->{'MIMAT0004495'};
   is( ref($mat),       'HASH',                          "hsa-miR-22-5p MIMAT0004495 mature" );
   is( $mat->{id},      'MIMAT0004495',                  "  id      MIMAT0004495" );
   is( $mat->{name},    'hsa-miR-22-5p',                 "  name    hsa-miR-22-5p" );
   is( $mat->{dname},   'hsa-mir-22(hsa-miR-22-5p)',     "  dname   hsa-mir-22(hsa-miR-22-5p)" );
   is( $mat->{count},      3,                            "  count    3" );
   is( $mat->{mm0},        3,                            "  mm0      3" );
   is( $mat->{mm1},        0,                            "  mm1      0" ); 
   is( $mat->{indel},      0,                            "  indel    0" );

   $mat = $res->{mature}->{'MIMAT0000077'};
   is( ref($mat),       'HASH',                          "hsa-miR-22-3p MIMAT0000077 mature" );
   is( $mat->{id},      'MIMAT0000077',                  "  id      MIMAT0000077" );
   is( $mat->{name},    'hsa-miR-22-3p',                 "  name    hsa-miR-22-3p" );
   is( $mat->{dname},   'hsa-mir-22(hsa-miR-22-3p)',     "  dname   hsa-mir-22(hsa-miR-22-3p)" );
   is( $mat->{count},     25,                            "  count   25" );
   is( $mat->{mm0},       24,                            "  mm0     24" );
   is( $mat->{mm1},        1,                            "  mm1      1" );
   is( $mat->{indel},      0,                            "  indel    0" );

   # this isn't used right now, but test it anyway...
   my $mmHist = $mat->{mmhist};
   is( ref($mmHist),    'ARRAY',                         "MIMAT0000077 mmhist ARRAY ref" );
   is( $mmHist->[19],         1,                         "  mir pos 19 has mm count 1" );

   my $msq = $res->{matseq}->{'MIMAT0004495'};
   is( ref($msq),       'HASH',                          "hsa-miR-22-5p MIMAT0004495 matseq" );
   is( $msq->{id},      'MIMAT0004495',                  "  id      MIMAT0004495" );
   is( $msq->{name},    'hsa-miR-22-5p',                 "  name    hsa-miR-22-5p" );
   is( $msq->{dname},   'hsa-miR-22-5p[1]',              "  dname   hsa-miR-22-5p[1]" );
   is( $msq->{count},      3,                            "  count    3" );
   is( $msq->{mm0},        3,                            "  mm0      3" );
   is( $msq->{mm1},        0,                            "  mm1      0" ); 
   is( $msq->{indel},      0,                            "  indel    0" );

   $msq = $res->{matseq}->{'MIMAT0000077'};
   is( ref($msq),       'HASH',                          "hsa-miR-22-3p MIMAT0000077 matseq" );
   is( $msq->{id},      'MIMAT0000077',                  "  id      MIMAT0000077" );
   is( $msq->{name},    'hsa-miR-22-3p',                 "  name    hsa-miR-22-3p" );
   is( $msq->{dname},   'hsa-miR-22-3p[1]',              "  dname   hsa-miR-22-3p[1]" );
   is( $msq->{count},     25,                            "  count   25" );
   is( $msq->{mm0},       24,                            "  mm0     24" );
   is( $msq->{mm1},        1,                            "  mm1      1" );
   is( $msq->{indel},      0,                            "  indel    0" );
}
sub d44_MirStats_newFromBamLocs_mature_indel_mm : Test(70) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfoFull();
   my ($res);
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-30c-1 hsa-mir-30c-2');  }          
                                                         "MirStats->newFromBam(bamLoc=>'hsa-mir-30c-1 hsa-mir-30c-2') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                             "  isa MirStats" );
   #is( $res->{stats}->{nAlign},    30,                   "  nAlign   30" );
   #is( $res->{stats}->{nGoodMat},  30,                   "  nGoodMat 30" );
   is( $res->getObjects('hairpin'), 2,                   "  has 2 hairpin stats obj" );
   is( $res->getObjects('mature'),  2,                   "  has 2 mature stats objs" );
   is( $res->getObjects('matseq'),  1,                   "  has 1 matseq stats objs" ); 

   # hsa-mir-30c-2: hairpin is len 72; mature 5p len 23 [pos 7-29]; mature 3p len 22 [pos 47-68]
   #   chr6 hairpin 72086663 72086734 - ID=MI0000254;Alias=MI0000254;Name=hsa-mir-30c-2
   #   chr6 mature  72086706 72086728 - ID=MIMAT0000244_1;Alias=MIMAT0000244;Name=hsa-miR-30c-5p;Derives_from=MI0000254
   #   chr6 mature  72086667 72086688 - ID=MIMAT0004550;Alias=MIMAT0004550;Name=hsa-miR-30c-2-3p;Derives_from=MI0000254
   # 9 total alignments, all 5p "good fit" w/default params
   #   HWI-ST975:100:D0D00ABXX:5:2214:16031:64007      0x400   hsa-mir-30c-2   2       1       5M1I24M MD:Z:29 NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1214:20292:2804       0x400   hsa-mir-30c-2   6       11      4S24M   MD:Z:24 NM:i:0
   #   HWI-ST975:100:D0D00ABXX:5:1109:9862:81089       0x400   hsa-mir-30c-2   7       0       10S24M  MD:Z:24 NM:i:0
   #   HWI-ST975:100:D0D00ABXX:5:1115:12318:4947       0x400   hsa-mir-30c-2   7       0       11S24M  MD:Z:24 NM:i:0
   #   HWI-ST975:100:D0D00ABXX:5:1116:13696:42973      0x400   hsa-mir-30c-2   7       1       8S24M   MD:Z:24 NM:i:0
   #   HWI-ST975:100:D0D00ABXX:5:1213:6836:29026       0x400   hsa-mir-30c-2   7       1       5S23M1S MD:Z:23 NM:i:0
   #   HWI-ST975:100:D0D00ABXX:5:1215:7303:29215       0x400   hsa-mir-30c-2   7       1       7S24M   MD:Z:24 NM:i:0
   #   HWI-ST975:100:D0D00ABXX:5:1205:4782:9747        0x400   hsa-mir-30c-2   8       1       6S22M   MD:Z:22 NM:i:0
   #   HWI-ST975:100:D0D00ABXX:5:1208:1431:33169       0x400   hsa-mir-30c-2   10      0       6S20M   MD:Z:20 NM:i:0   
   # Alignment WI-ST975:100:D0D00ABXX:5:2214:16031:64007 len 29 [2-30] has insertion at relative pos 6, hp pos 7, mir pos 1
   my $obj = $res->{hairpin}->{'hsa-mir-30c-2'};
   is( ref($obj),      'HASH',                           "hsa-mir-30c-2 hairpin stats" );
   is( $obj->{name},   'hsa-mir-30c-2',                  "  name hsa-mir-30c-2" );
   is( $obj->{rank},       2,                            "  rank     2" );
   is( $obj->{count},      9,                            "  count    9" );
   is( $obj->{mm0},        9,                            "  mm0      9" );
   is( $obj->{mm1},        0,                            "  mm1      0" );
   is( $obj->{indel},      1,                            "  indel    1" );
   is( $obj->{'5pOnly'},   9,                            "  5pOnly   9" );
   is( $obj->{'3pOnly'},   0,                            "  3pOnly   0" );  

   is( ref($res->{mature}->{'MIMAT0004550'}), '',        "no hsa-miR-30c-2-3p MIMAT0004550 mature" );
   my $mat = $res->{mature}->{'MIMAT0000244_1'};
   is( ref($mat),       'HASH',                          "hsa-miR-30c-2-5p MIMAT0000244_1 mature" );
   is( $mat->{id},      'MIMAT0000244_1',                "  id      MIMAT0000244_1" );
   is( $mat->{name},    'hsa-miR-30c-5p',                "  name    hsa-miR-30c-5p" );
   is( $mat->{dname},   'hsa-mir-30c-2(hsa-miR-30c-5p)', "  dname   hsa-mir-30c-2(hsa-miR-30c-5p)" );
   is( $mat->{count},      9,                              "  count    9" );
   is( $mat->{mm0},        9,                              "  mm0      9" );
   is( $mat->{mm1},        0,                              "  mm1      0" ); 
   is( $mat->{indel},      1,                              "  indel    1" ); 

   # this isn't used right now, but test it anyway...
   my $insHist = $mat->{inshist}; 
   is( ref($insHist),    'ARRAY',                          "MIMAT0000244 inshist ARRAY ref" );
   is( $insHist->[1],          1,                          "  mir pos 1 has ins count 1" );  

   # hsa-mir-30c-1: hairpin is len 89; mature 5p len 23 [pos 17-39]
   #   chr1 hairpin 40757284 40757372 + ID=MI0000736;Alias=MI0000736;Name=hsa-mir-30c-1
   #   chr1 mature  40757300 40757322 + ID=MIMAT0000244;Alias=MIMAT0000244;Name=hsa-miR-30c-5p;Derives_from=MI0000736
   #   chr1 mature  40757339 40757360 + ID=MIMAT0004674;Alias=MIMAT0004674;Name=hsa-miR-30c-1-3p;Derives_from=MI0000736
   # 336 total alignments, 335 are 5p "good fit" w/default params
   # 1 alignment w/3+ mm and deletion (not "good fit")
   #   HWI-ST975:100:D0D00ABXX:5:1105:1587:12865 0x400  hsa-mir-30c-1  16  2 5S26M1D26M44S MD:Z:26^T0G1G0C0T3G0G0T1G0C0T9T1 NM:i:12
   # 1 good fit 5p alignment w/2 mm [16-40] at rel pos 4 and 8, mir pos 3 and 7
   #   HWI-ST975:100:D0D00ABXX:5:1213:7093:77520 0x400  hsa-mir-30c-1  16  2 5S25M         MD:Z:3T3C17 NM:i:2
   # 14 good fit alignments w/1 mismatch  
   # all alignments start at 16, one base before 5p startPos 17
   # mir pos mm: 4 => 1, 6 => 2, 8 => 2, 10 => 2, 11 => 2, 12 => 1, 16 => 1, 20 => 2, 21 => 1
   #   HWI-ST975:100:D0D00ABXX:5:2216:13452:82517      0x400   hsa-mir-30c-1   16   2    5S22M74S MD:Z:4A17       NM:i:1   
   #   HWI-ST975:100:D0D00ABXX:5:2214:18630:12098      0x400   hsa-mir-30c-1   16   2    5S25M    MD:Z:6A18       NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1206:13737:67266      0x400   hsa-mir-30c-1   16   2    5S22M74S MD:Z:6A15       NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1104:8865:94986       0x400   hsa-mir-30c-1   16   2    5S22M2S  MD:Z:8A13       NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1116:20930:16242      0x400   hsa-mir-30c-1   16   2    5S24M1S  MD:Z:8A15       NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1214:3045:88377       0x400   hsa-mir-30c-1   16   2    5S24M1S  MD:Z:10C13      NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:2112:16271:32071      0x400   hsa-mir-30c-1   16   2    5S25M    MD:Z:10C14      NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:2214:12168:52265      0x400   hsa-mir-30c-1   16   2    5S23M    MD:Z:11C11      NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1212:10505:8175       0x400   hsa-mir-30c-1   16   2    5S25M5S  MD:Z:11C13      NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1213:12328:69117      0x400   hsa-mir-30c-1   16   2    5S24M1S  MD:Z:12T11      NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:2103:10782:3097       0x400   hsa-mir-30c-1   16   2    5S25M    MD:Z:16C8       NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1202:6231:80079       0x400   hsa-mir-30c-1   16   2    5S24M    MD:Z:20C3       NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1212:20483:90886      0x400   hsa-mir-30c-1   16   2    5S25M    MD:Z:20C4       NM:i:1
   #   HWI-ST975:100:D0D00ABXX:5:1104:13594:38237      0x400   hsa-mir-30c-1   16  11    5S25M    MD:Z:21A3       NM:i:1
   $obj = $res->{hairpin}->{'hsa-mir-30c-1'};
   is( ref($obj),      'HASH',                           "hsa-mir-30c-1 hairpin stats" );
   is( $obj->{name},   'hsa-mir-30c-1',                  "  name hsa-mir-30c-1" );
   is( $obj->{rank},       1,                            "  rank      1" );
   is( $obj->{count},    336,                            "  count   336" );
   is( $obj->{mm0},      320,                            "  mm0     320" );
   is( $obj->{mm1},       14,                            "  mm1      14" );
   is( $obj->{mm2},        1,                            "  mm2       1" );
   is( $obj->{mm3p},       1,                            "  mm3p      1" );
   is( $obj->{indel},      1,                            "  indel     1" );
   is( $obj->{'5pOnly'}, 335,                            "  5pOnly  335" );
   is( $obj->{'3pOnly'},   0,                            "  3pOnly    0" );  
   
   is( ref($res->{mature}->{'MIMAT0004674'}), '',        "no hsa-miR-30c-1-3p MIMAT0004674 mature" );
   $mat = $res->{mature}->{'MIMAT0000244'};
   is( ref($mat),       'HASH',                          "hsa-miR-30c-2-5p MIMAT0000244 mature" );
   is( $mat->{id},      'MIMAT0000244',                  "  id      MIMAT0000244" );
   is( $mat->{name},    'hsa-miR-30c-5p',                "  name    hsa-miR-30c-5p" );
   is( $mat->{dname},   'hsa-mir-30c-1(hsa-miR-30c-5p)', "  dname   hsa-mir-30c-1(hsa-miR-30c-5p)" );
   is( $mat->{count},    335,                            "  count   335" );
   is( $mat->{mm0},      320,                            "  mm0     320" );
   is( $mat->{mm1},       14,                            "  mm1      14" );
   is( $mat->{mm2},        1,                            "  mm2       1" );
   is( $mat->{mm3p},       0,                            "  mm3p      0" );
   is( $mat->{indel},      0,                            "  indel     0" ); 

   # this isn't used right now, but test it anyway...
   my $hExp = { 3 => 1, 4 => 1, 6 => 2, 7 => 1, 8 => 2, 10 => 2, 11 => 2, 12 => 1, 16 => 1, 20 => 2, 21 => 1 };
   my $mmHist = $mat->{mmhist}; 
   is( ref($mmHist),     'ARRAY',                        "MIMAT0000244 mmhist ARRAY ref" );
   my @positions = sort {$a <=> $b} keys(%$hExp); 
   #diag("(@positions), (@$mmHist)");
   foreach (@positions) {
      is( $mmHist->[$_],   $hExp->{$_},                  "  mir pos $_ has mm count $hExp->{$_}" );  
   }
   
   my $msq =  $res->{matseq}->{'MIMAT0000244'};
   is( ref($msq),       'HASH',                          "hsa-miR-30c-5p MIMAT0000244 matseq" );
   is( $msq->{id},      'MIMAT0000244',                  "  id      MIMAT0000244" );
   is( $msq->{name},    'hsa-miR-30c-5p',                "  name    hsa-miR-30c-5p" );
   is( $msq->{dname},   'hsa-miR-30c-5p[2]',             "  dname   hsa-miR-30c-5p[2]" );
   is( $msq->{count},      9+335,                        "  count    344" );
   is( $msq->{mm0},        9+320,                        "  mm0      329" );
   is( $msq->{mm1},           14,                        "  mm1       14" ); 
   is( $msq->{mm2},            1,                        "  mm2        1" ); 
   is( $msq->{mm3p},           0,                        "  mm3p       0" ); 
   is( $msq->{indel},          1,                        "  indel      1" );
}

sub d51_MirStats_newFromBamLocs_cluster : Test(64) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                             "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfoFull();
   my ($res);

   lives_ok { $res = MirStats->newFromBamFull(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-345 hsa-mir-342 hsa-mir-151b');  }          
                                                "MirStats->newFromBamFull(bamLoc=>'hsa-mir-345 hsa-mir-342 hsa-mir-151b') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                    "  isa MirStats" );
   is( $res->getObjects('hairpin'), 3,          "  3 hairpin objects" );
   is( $res->getObjects('cluster'), 2,          "  2 cluster objects" );
   is( $res->{stats}->{nAlign},  2589,          "  nAlign 2589" );

   # hsa-mir-345 is in its own cluster (no other mir within 10k)
   #   chr14 hairpin 100774196	100774293 + ID=MI0000825;Alias=MI0000825;Name=hsa-mir-345
   # test data has 6 alignments to hsa -mir-151b
   my $hp1 = $res->{hairpin}->{'hsa-mir-345'};
   is( ref($hp1),       'HASH',                 "hsa-mir-345 hairpin" );
   is( $hp1->{name},    'hsa-mir-345',          "  name  hsa-mir-345" );
   is( $hp1->{rank},         3,                 "  rank       3" );
   is( $hp1->{count},        6,                 "  count      6" );
   is( $hp1->{'5pOnly'},     6,                 "  5pOnly     6" );
   is( $hp1->{'3pOnly'},     0,                 "  3pOnly     0" );
   is( ref($hp1->{hairpin}), 'HASH',            "  has MirInfo hairpin" );
   my $ob1 = $hp1->{hairpin}->{clusterObj};
   is( ref($ob1),            'HASH',            "hsa-mir-345 has MirInfo cluster object" );
   is( $ob1->{dname}, "cluster(chr14:100774196-100774293)[1]",     
                                                "  cluster dname cluster(chr14:100774196-100774293)[1]" );
   my $cl1 = $res->{cluster}->{ $ob1->{id} };
   is( ref($cl1),            'HASH',            "  found cluster stats for hsa-mir-345 using cluster id" );
   is( $cl1->{dname},        $ob1->{dname},     "  dname      " . $ob1->{dname} );
   is( $cl1->{rank},         2,                 "  rank       2" );
   is( $cl1->{count},        6,                 "  count      6" );
   is( $cl1->{'5pOnly'},     6,                 "  5pOnly     6" );
   is( $cl1->{'3pOnly'},     0,                 "  3pOnly     0" );
  
   # hsa-mir-342 and hsa-mir-151b are in the same 10k cluster, but different cluster+ and cluster-
   #   chr14 hairpin 100575756	100575851 - ID=MI0003772;Alias=MI0003772;Name=hsa-mir-151b
   #   chr14 hairpin 100575992	100576090 + ID=MI0000805;Alias=MI0000805;Name=hsa-mir-342
   # test data has 2564 alignments to hsa-mir-342, 19 to hsa -mir-151b

   my $hp2 = $res->{hairpin}->{'hsa-mir-342'};
   is( ref($hp2),       'HASH',                 "hsa-mir-345 hairpin" );
   is( $hp2->{name},    'hsa-mir-342',          "  name  hsa-mir-342" );
   is( $hp2->{rank},         1,                 "  rank       1" );
   is( $hp2->{count},     2564,                 "  count   2564" );
   is( $hp2->{'5pOnly'},     1,                 "  5pOnly     1" );
   is( $hp2->{'3pOnly'},  2562,                 "  3pOnly  2562" );
   is( $hp2->{'3pPlus'},     1,                 "  3pPlus     1" );
   is( ref($hp2->{hairpin}), 'HASH',            "  has MirInfo hairpin" );
   my $ob2 = $hp2->{hairpin}->{clusterObj};
   is( ref($ob2),            'HASH',            "hsa-mir-345 has MirInfo cluster object" );
   is( $ob2->{dname}, "cluster(chr14:100575756-100576090)[2]",     
                                                "  cluster dname cluster(chr14:100575756-100576090)[2]" );
   my $cl2 = $res->{cluster}->{ $ob2->{name} };
   is( ref($cl2),            'HASH',            "  found cluster stats for hsa-mir-345 using cluster name" );

   my $hp3 = $res->{hairpin}->{'hsa-mir-151b'};
   is( ref($hp3),       'HASH',                 "hsa-mir-151b hairpin" );
   is( $hp3->{name},    'hsa-mir-151b',         "  name  hsa-mir-151b" );
   is( $hp3->{rank},         2,                 "  rank       2" );
   is( $hp3->{count},       19,                 "  count     19" );
   is( $hp3->{'5pOnly'},     0,                 "  5pOnly     1" );
   is( $hp3->{'3pOnly'},    19,                 "  3pOnly    19" );
   is( ref($hp3->{hairpin}), 'HASH',            "hsa-mir-345 has MirInfo hairpin" );
   my $ob3 = $hp3->{hairpin}->{clusterObj};
   is( ref($ob3),            'HASH',            "hsa-mir-151b has MirInfo cluster object" );
   is( $ob3->{dname}, "cluster(chr14:100575756-100576090)[2]",     
                                                "  cluster dname cluster(chr14:100575756-100576090)[2]" );
   my $cl3 = $res->{cluster}->{ $ob3->{name} };
   is( ref($cl3),            'HASH',            "  found cluster stats for hsa-mir-151b using cluster name" );

   is( $ob2,                 $ob3,              "  cluster info objects same" );
   is( $cl2,                 $cl3,              "  cluster stats objects same" );

   is( $cl3->{dname},        $ob3->{dname},     "  dname " . $ob3->{dname} );
   is( $cl3->{rank},         1,                 "  rank       1" );
   is( $cl3->{count},     2583,                 "  count   2583" );
   is( $cl3->{'5pOnly'},     1,                 "  5pOnly     1" );
   is( $cl3->{'3pOnly'},  2581,                 "  3pOnly  2581" );
   is( $cl3->{'3pPlus'},     1,                 "  3pPlus     1" );

   # cluster+ and cluster- objects should be different 
   #  hsa-mir-342 and hsa-mir-345 are cluster+
   #  hsa-mir-151b is cluster-
   is( $res->getObjects('cluster+'), 2,         "  2 cluster+ objects" );
   is( $res->getObjects('cluster-'), 1,         "  1 cluster- objects" );

   ok(!$hp2->{hairpin}->{'cluster-Obj'},        "hsa-mir-342 does not have MirInfo cluster- object" );
   my $obj = $hp2->{hairpin}->{'cluster+Obj'};
   is( ref($obj),            'HASH',            "hsa-mir-342 has MirInfo cluster+ object" );
   is( $obj->{dname}, "cluster+(chr14:100575992-100576090)[1]",     
                                                "  cluster+ dname cluster+(chr14:100575992-100576090)[1]" );
   my $clr = $res->{'cluster+'}->{ $obj->{name} };
   is( ref($clr),            'HASH',            "  found cluster+ stats for hsa-mir-342 using cluster+ name" );
   is( $clr->{dname},        $obj->{dname},     "  dname " . $obj->{dname} );
   is( $clr->{count},     2564,                 "  count   2564" );

   ok(!$hp3->{hairpin}->{'cluster+Obj'},        "hsa-mir-151b does not have MirInfo cluster+ object" );
   $obj = $hp3->{hairpin}->{'cluster-Obj'};
   is( ref($obj),            'HASH',            "hsa-mir-151b has MirInfo cluster- object" );
   is( $obj->{dname}, "cluster-(chr14:100575756-100575851)[1]",     
                                                "  cluster- dname cluster-(chr14:100575756-100575851)[1]" );
   $clr = $res->{'cluster-'}->{ $obj->{name} };
   is( ref($clr),            'HASH',            "  found cluster- stats for hsa-mir-151b using cluster- name" );
   is( $clr->{dname},        $obj->{dname},     "  dname " . $obj->{dname} );
   is( $clr->{count},       19,                 "  count     19" );
}

#=====================================================================================
# Test stats for large bam file
#=====================================================================================

my $MIR_STATS;
sub getTestMirStats {
   if (!$MIR_STATS) {
      my $hInf = getGffInfo();
      my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
      $MIR_STATS = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf);
   }
   return $MIR_STATS;
}
my $FULL_MIR_STATS;
sub getTestMirStatsFull {
   if (!$FULL_MIR_STATS) {
      my $hInf = getGffInfoFull();
      my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
      $FULL_MIR_STATS = MirStats->newFromBamFull(bam => $bamF, mirInfo => $hInf);
   }
   return $FULL_MIR_STATS;
}

sub e11_MirStats_newFromBam : Test(81) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res;
   lives_ok { $res = getTestMirStats();  }     "MirStats->newFromBam(known_bam) lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                   "  isa MirStats" );
   ok( $res->{stats}->{nAlign},                "  nAlign ok ($res->{stats}->{nAlign})" );
   is( $res->{stats}->{nAlign}, 47566,         "  nAlign 47566" );
   is( $res->getObjects('hairpin'), 462,       "  has 462 hairpin stats objects" );

   my $obj = $res->{hairpin}->{'hsa-mir-149'};
   is( ref($obj),       'HASH',                "hsa-mir-149 hairpin stats" );
   is( $obj->{name},    'hsa-mir-149',         "  name hsa-mir-149" );
   is( $obj->{rank},       30,                 "  rank       30" );  
   is( $obj->{count},     386,                 "  count     386" );  
   is( $obj->{dup},       385,                 "  dup       385" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );
   is( $obj->{mm0},       377,                 "  mm0       377" );
   is( $obj->{mm1},         8,                 "  mm1         8" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        1,                 "  mm3p        1" );
   is( $obj->{indel},       2,                 "  indel       2" ); 
   is( $obj->{mq0},         1,                 "  mq0         1" );
   is( $obj->{'mq1-19'},    2,                 "  mq1-19      2" );
   is( $obj->{'mq20-29'},  52,                 "  mq20-29    52" );
   is( $obj->{mq30p},     331,                 "  mq30p     331" );
   is( $obj->{'5pOnly'},  383,                 "  5pOnly    383" );
   is( $obj->{'3pOnly'},    1,                 "  3pOnly      1" ); 

   $obj = $res->{hairpin}->{'hsa-mir-27b'};
   is( ref($obj),       'HASH',                "hsa-mir-27b hairpin stats" );
   is( $obj->{name},    'hsa-mir-27b',         "  name hsa-mir-27b" );
   is( $obj->{rank},       36,                 "  rank       36" );  
   is( $obj->{count},     293,                 "  count     293" );  
   is( $obj->{dup},       293,                 "  dup       293" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );
   is( $obj->{mm0},       288,                 "  mm0       288" );
   is( $obj->{mm1},         5,                 "  mm1         5" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       0,                 "  indel       0" ); 
   is( $obj->{mq0},         1,                 "  mq0         1" );
   is( $obj->{'mq1-19'},  286,                 "  mq1-19    286" );
   is( $obj->{'mq20-29'},   3,                 "  mq20-29     3" );
   is( $obj->{mq30p},       3,                 "  mq30p       3" );
   is( $obj->{'5pOnly'},    3,                 "  5pOnly      3" );
   is( $obj->{'3pOnly'},  289,                 "  3pOnly    289" );

   # no GFF entry for this mir in v20
   # HWI-ST975:100:D0D00ABXX:5:1207:11132:96351 0x400 hsa-mir-1273e   1   2  54S47M         MD:Z:14T22C9  NM:i:2
   # HWI-ST975:100:D0D00ABXX:5:2215:8424:11509  0x400 hsa-mir-1273e  36  22  2S20M5S        MD:Z:3T16     NM:i:1   
   # HWI-ST975:100:D0D00ABXX:5:2110:3399:84131  0x400 hsa-mir-1273e  31  16  5S6M2D58M1D4M  MD:Z:6^GC17G0A0G6T13T4C2C9^G4 NM:i:10
   # Note that one of these alignments has 2 deletions
   $obj = $res->{hairpin}->{'hsa-mir-1273e'};
   is( ref($obj),       'HASH',                "hsa-mir-1273e hairpin stats" );
   is( $obj->{name},    'hsa-mir-1273e',       "  name  hsa-mir-1273e" );
   is( $obj->{dname},   'hsa-mir-1273e(unk)',  "  dname hsa-mir-1273e(unk)" );
   ok( $obj->{rank}     > 200,                 "  rank     >200" );  
   is( $obj->{count},       3,                 "  count       3" );  
   is( $obj->{dup},         3,                 "  dup         3" );
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );
   is( $obj->{mm0},         0,                 "  mm0         0" );
   is( $obj->{mm1},         1,                 "  mm1         1" );
   is( $obj->{mm2},         1,                 "  mm2         1" );
   is( $obj->{mm3p},        1,                 "  mm3p        1" );
   is( $obj->{indel},       2,                 "  indel       2" ); 
   is( $obj->{mq0},         0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},    2,                 "  mq1-19      2" );
   is( $obj->{'mq20-29'},   1,                 "  mq20-29     1" );
   is( $obj->{mq30p},       0,                 "  mq30p       0" );
   # these counts are 0 because there is no gff entry for this mir in v20
   is( $obj->{'5pOnly'},    0,                 "  5pOnly      0" );
   is( $obj->{'5pPlus'},    0,                 "  5pOnly      0" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" ); 
   is( $obj->{'3pPlus'},    0,                 "  3pOnly      0" ); 
   is( $obj->{'5and3p'},    0,                 "  5and3p      0" );
   is( $obj->{totBase},   138,                 "  totBase   138" );
   is( $obj->{'5pBase'},    0,                 "  5pBase      0" );
   is( $obj->{'3pBase'},    0,                 "  3pBase      0" );
   is( ref($obj->{hairpin}), '',               "  no MirInfo hairpin" );

   $obj = $res->{hairpin}->{'hsa-mir-21'};
   is( ref($obj),       'HASH',                "hsa-mir-21 hairpin stats" );
   is( $obj->{name},    'hsa-mir-21',          "  name hsa-mir-21" );
   is( $obj->{rank},       71,                 "  rank       71" );  
   is( $obj->{count},      84,                 "  count      84" );  
   is( $obj->{dup},        84,                 "  dup        84" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );
   is( $obj->{mm0},        82,                 "  mm0        82" );
   is( $obj->{mm1},         2,                 "  mm1         2" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       0,                 "  indel       9" );
   is( $obj->{mq0},         0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},    0,                 "  mq1-19      0" );
   is( $obj->{'mq20-29'},  14,                 "  mq20-29    14" );
   is( $obj->{mq30p},      70,                 "  mq30p      70" );
   is( $obj->{'5pOnly'},   84,                 "  5pOnly     84" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" );
}

sub e20_MirStats_groupCounts : Test(109) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res;
   lives_ok { $res = getTestMirStats();  }     "MirStats->newFromBam(known_bam) lives";
   return("error") if !$res;  
   is( $res->getObjects('group'), 419,         "  has 419 group stats objects" ); 

   #
   # hsa-mir-21 group
   #
   # hsa-mir-21 is the only member of its group, so its counts should be
   # the same as the hairpin counts
   my $obj = $res->{group}->{'hsa-mir-21'};
   is( ref($obj),       'HASH',                "hsa-mir-21 group stats" );
   is( $obj->{name},    'hsa-mir-21',          "  name  hsa-mir-21" );
   is( $obj->{dname},   'hsa-mir-21[1]',       "  dname hsa-mir-21[1]" );
   is( $obj->{count},      84,                 "  count      84" );  
   is( $obj->{dup},        84,                 "  dup        84" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );  
   is( $obj->{mm0},        82,                 "  mm0        82" );
   is( $obj->{mm1},         2,                 "  mm1         2" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       0,                 "  indel       9" );
   is( $obj->{mq0},         0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},    0,                 "  mq1-19      0" );
   is( $obj->{'mq20-29'},  14,                 "  mq20-29    14" );
   is( $obj->{mq30p},      70,                 "  mq30p      70" );
   is( $obj->{'5pOnly'},   84,                 "  5pOnly     84" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" );  

   #
   # hsa-mir-1273e group
   #
   # hsa-mir-1273e does not have a gff entry in v20, so is the only 
   # member of its group
   $obj = $res->{group}->{'hsa-mir-1273e'};
   is( ref($obj),       'HASH',                "hsa-mir-1273e group stats" );
   is( $obj->{name},    'hsa-mir-1273e',       "  name  hsa-mir-1273e" );
   is( $obj->{dname},   'hsa-mir-1273e[unk]',  "  dname hsa-mir-1273e[unk]" );
   ok( $obj->{rank}     > 200,                 "  rank     >200" );  
   is( $obj->{count},       3,                 "  count       3" );  
   is( $obj->{dup},         3,                 "  dup         3" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );  
   is( $obj->{mm0},         0,                 "  mm0         0" );
   is( $obj->{mm1},         1,                 "  mm1         1" );
   is( $obj->{mm2},         1,                 "  mm2         1" );
   is( $obj->{mm3p},        1,                 "  mm3p        1" );
   is( $obj->{indel},       2,                 "  indel       2" ); 
   is( $obj->{mq0},         0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},    2,                 "  mq1-19      2" );
   is( $obj->{'mq20-29'},   1,                 "  mq20-29     1" );
   is( $obj->{mq30p},       0,                 "  mq30p       0" );
   # these counts are 0 because there is no gff entry for this mir in v20
   is( $obj->{'5pOnly'},    0,                 "  5pOnly      0" );
   is( $obj->{'5pPlus'},    0,                 "  5pOnly      0" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" ); 
   is( $obj->{'3pPlus'},    0,                 "  3pOnly      0" ); 

   #
   # hsa-let-7a group
   #
   # hsa-let-7a group has 3 members, hsa-let-7a-1, hsa-let-7a-2 and hsa-let-7a-3
   # counts should be additive. 

   # First look at the hairpin stats...
   $obj = $res->{hairpin}->{'hsa-let-7a-1'};
   is( ref($obj),       'HASH',                "hsa-let-7a-1 hairpin stats" );
   is( $obj->{name},    'hsa-let-7a-1',        "  name  hsa-let-7a-1" );
   ok( $obj->{rank}     > 100,                 "  rank     >100" );  
   is( $obj->{count},       7,                 "  count       7" );  
   is( $obj->{dup},         7,                 "  dup         7" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );  
   is( $obj->{mm0},         4,                 "  mm0         4" );
   is( $obj->{mm1},         3,                 "  mm1         3" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       0,                 "  indel       0" );
   is( $obj->{mq0},         1,                 "  mq0         1" );
   is( $obj->{'mq1-19'},    6,                 "  mq1-19      6" );
   is( $obj->{'mq20-29'},   0,                 "  mq20-29     0" );
   is( $obj->{mq30p},       0,                 "  mq30p       0" );
   is( $obj->{'5pOnly'},    7,                 "  5pOnly      7" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" );

   $obj = $res->{hairpin}->{'hsa-let-7a-2'};
   is( ref($obj),       'HASH',                "hsa-let-7a-2 hairpin stats" );
   is( $obj->{name},    'hsa-let-7a-2',        "  name  hsa-let-7a-2" );
   ok( $obj->{rank}     > 200,                 "  rank     >200" );  
   is( $obj->{count},       1,                 "  count       1" );  
   is( $obj->{dup},         1,                 "  dup         1" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );  
   is( $obj->{mm0},         1,                 "  mm0         1" );
   is( $obj->{mm1},         0,                 "  mm1         0" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       0,                 "  indel       0" );
   is( $obj->{mq0},         0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},    0,                 "  mq1-19      0" );
   is( $obj->{'mq20-29'},   1,                 "  mq20-29     1" );
   is( $obj->{mq30p},       0,                 "  mq30p       0" );
   is( $obj->{'5pOnly'},    1,                 "  5pOnly      1" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" );

   $obj = $res->{hairpin}->{'hsa-let-7a-3'};
   is( ref($obj),       'HASH',                "hsa-let-7a-3 hairpin stats" );
   is( $obj->{name},    'hsa-let-7a-3',        "  name  hsa-let-7a-3" );
   is( $obj->{rank},       42,                 "  rank       42" );  
   is( $obj->{count},     220,                 "  count     220" );  
   is( $obj->{dup},       220,                 "  dup       220" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );  
   is( $obj->{mm0},       216,                 "  mm0       216" );
   is( $obj->{mm1},         4,                 "  mm1         4" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       1,                 "  indel       1" );
   is( $obj->{mq0},         3,                 "  mq0         3" );
   is( $obj->{'mq1-19'},  217,                 "  mq1-19    217" );
   is( $obj->{'mq20-29'},   0,                 "  mq20-29     0" );
   is( $obj->{mq30p},       0,                 "  mq30p       0" );
   is( $obj->{'5pOnly'},  220,                 "  5pOnly    220" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" );
   
   # Now look at group...
   ok( !$res->{group}->{'hsa-let-7a-1'},       "no hsa-let-7a-1 group stats" );
   $obj = $res->{group}->{'hsa-let-7a'};
   is( ref($obj),       'HASH',                "hsa-let-7a group stats" );
   is( $obj->{name},    'hsa-let-7a',          "  name  hsa-let-7a" );
   is( $obj->{dname},   'hsa-let-7a[3]',       "  dname hsa-let-7a[3]" );
   is( $obj->{rank},       37,                 "  rank       37" );  
   is( $obj->{count},     228,                 "  count     228" );
   is( $obj->{dup},       228,                 "  dup       228" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );  
   is( $obj->{mm0},       221,                 "  mm0       221" );
   is( $obj->{mm1},         7,                 "  mm1         7" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       1,                 "  indel       1" );
   is( $obj->{mq0},         4,                 "  mq0         4" );
   is( $obj->{'mq1-19'},  223,                 "  mq1-19    223" );
   is( $obj->{'mq20-29'},   1,                 "  mq20-29     1" );
   is( $obj->{mq30p},       0,                 "  mq30p       0" );
   is( $obj->{'5pOnly'},  228,                 "  5pOnly    228" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" );
}

sub e30_MirStats_familyCounts : Test(83) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res;
   lives_ok { $res = getTestMirStatsFull(); } "MirStats->newFromBamFull(known_bam) lives";
   return("error") if !$res;  
   is( $res->getObjects('hairpin'), 462,      "  has 462 hairpin stats objects" );
   is( $res->getObjects('group'),   419,      "  has 419 group stats objects" ); 
   is( $res->getObjects('family'),  322,      "  has 322 family stats objects" ); 

   #
   # mir-21 family
   #
   # hsa-mir-21 is the only member of its family, so its counts should be
   # the same as the hairpin and group counts
   my $obj = $res->{family}->{'mir-21'};
   is( ref($obj),       'HASH',                "mir-21 family stats" );
   is( $obj->{name},    'mir-21',              "  name  mir-21" );
   is( $obj->{dname},   'mir-21[1]',           "  dname mir-21[1]" );
   is( $obj->{count},      84,                 "  count      84" );  
   is( $obj->{dup},        84,                 "  dup        84" );  
   is( $obj->{oppStrand},   0,                 "  oppStrand   0" );  
   is( $obj->{mm0},        82,                 "  mm0        82" );
   is( $obj->{mm1},         2,                 "  mm1         2" );
   is( $obj->{mm2},         0,                 "  mm2         0" );
   is( $obj->{mm3p},        0,                 "  mm3p        0" );
   is( $obj->{indel},       0,                 "  indel       9" );
   is( $obj->{mq0},         0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},    0,                 "  mq1-19      0" );
   is( $obj->{'mq20-29'},  14,                 "  mq20-29    14" );
   is( $obj->{mq30p},      70,                 "  mq30p      70" );
   is( $obj->{'5pOnly'},   84,                 "  5pOnly     84" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly      0" );  
   is( ref($obj->{family}), 'HASH',            "  has MirInfo family" );
   
   #
   # hsa-mir-1273e family
   #
   # hsa-mir-1273e does not have a gff entry in v20, so is the only 
   # member of its family
   ok( !$res->{family}->{'mir-1273e'},         "no mir-1273e family stats" );
   $obj = $res->{family}->{'hsa-mir-1273e'};
   is( ref($obj),       'HASH',                "hsa-mir-1273e family stats" );
   is( $obj->{name},    'hsa-mir-1273e',       "  name  mir-1273e" );
   is( $obj->{dname},   'hsa-mir-1273e[unk]',  "  dname mir-1273e[unk]" );
   is( $obj->{count},       3,                 "  count     3" );  
   is( $obj->{mm0},         0,                 "  mm0       0" );
   is( $obj->{mm1},         1,                 "  mm1       1" );
   is( $obj->{mm2},         1,                 "  mm2       1" );
   is( $obj->{mm3p},        1,                 "  mm3p      1" );
   is( $obj->{indel},       2,                 "  indel     2" ); 
   is( $obj->{mq0},         0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},    2,                 "  mq1-19    2" );
   is( $obj->{'mq20-29'},   1,                 "  mq20-29   1" );
   is( $obj->{mq30p},       0,                 "  mq30p     0" );
   # these counts are 0 because there is no gff entry for this mir in v20
   is( $obj->{'5pOnly'},    0,                 "  5pOnly    0" );
   is( $obj->{'5pPlus'},    0,                 "  5pOnly    0" );
   is( $obj->{'3pOnly'},    0,                 "  3pOnly    0" ); 
   is( $obj->{'3pPlus'},    0,                 "  3pOnly    0" ); 
   is( ref($obj->{family}), '',                "  no MirInfo family" );

   #
   # let-7 family
   #
   # let-7 family has 12 members, 11 of which have counts in the test data
   # Family counts should be additive

   ok( !$res->{family}->{'let-7a-1'},        "no let-7a-1 family stats" );
   ok( !$res->{family}->{'let-7a'},          "no let-7a   family stats" );
   $obj = $res->{family}->{'let-7'};
   is( ref($obj),     'HASH',                "let-7 family stats" );
   is( $obj->{name},  'let-7',               "  name  let-7" );
   is( $obj->{dname}, 'let-7[12]',           "  dname let-7[12]" );
   is( ref($obj->{family}), 'HASH',          "  has MirInfo family" );

   my $hInfo = $res->{mirInfo};
   isa_ok( $hInfo,    'MirInfo',             "MirInfo from gff" );

   my $gffFam = $hInfo->{family}->{'let-7'};
   is( ref($gffFam),  'HASH',                "  let-7 family mirInfo" );           
   is( @{ $gffFam->{children} }, 12,         "  family of 12 hairpins" );

   my $nFound  = 0;
   my $hTotals = {};
   foreach (@MirStats::HP_COUNT_FIELDS) { $hTotals->{$_} = 0; }
   foreach my $fobj (@{ $gffFam->{children} }) {
      my $name = $fobj->{name};
      my $hp   = $res->{hairpin}->{$name};
      if ($hp) { $nFound++;
         is( ref($hp),   'HASH',             "    found $name hairpin" );
         foreach (@MirStats::HP_COUNT_FIELDS) { $hTotals->{$_} += $hp->{$_}; }
      } else {
         is( ref($hp),   '',                 "    no $name hairpin" );
      }
   }
   is( $nFound,          11,                 "  found stats for 11 let-7 family hairpins" );
   foreach (@MirStats::HP_COUNT_FIELDS) { 
      is( $obj->{$_},   $hTotals->{$_},      "    family $_  $hTotals->{$_}" );
   }
}

sub e40_MirStats_testGoodFitCounts : Test(6) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res;
   lives_ok { $res = getTestMirStats(); } "MirStats->getTestMirStats(known_bam) lives";
   return("error") if !$res;  

   my $numHp = 462; my $numMat = 455;
   ok( $res->{mirInfo},                       "  has mirInfo" );
   is( $res->getObjects('hairpin'), $numHp,   "  has $numHp hairpin stats objects" );
   is( $res->getObjects('mature'),  $numMat,  "  has $numMat mature stats objects" );

   my $hInfo = $res->{mirInfo};
   my $nGood5p = 0;
   my $nGood3p = 0;
   foreach my $hp ($res->getObjects('hairpin')) {
      my $gffHp = $hInfo->{hairpin}->{$hp->{name}};
      next unless $gffHp; # not all alignments have miRBase annotations
      
      if ($hp->{'5pOnly'} > 0) { # has goodFit 5p count
         $nGood5p++;
         my $gffMat = $gffHp->{'5p'};
         if (!$gffMat) {
            ok( $gffMat,   "Found 5p mature locus GFF info for $hp->{name}" );
            next;
         }
         my $mat = $res->{mature}->{$gffMat->{id}};
         if (!$mat) {
            ok( $mat,      "Found 5p mature locus stats for $gffMat->{id} ($gffMat->{dname})" );
            next;
         }
         if ($mat->{count} != $hp->{'5pOnly'}) {
            is( $mat->{count}, $hp->{'5pOnly'}, "5p mature count for $gffMat->{dname} matches 5pOnly for $hp->{name}" );
         }
      }
      if ($hp->{'3pOnly'} > 0) { # has goodFit 3p count
         $nGood3p++;
         my $gffMat = $gffHp->{'3p'};
         if (!$gffMat) {
            ok( $gffMat,   "Found 3p mature locus GFF info for $hp->{name}" );
            next;
         }
         my $mat = $res->{mature}->{$gffMat->{id}};
         if (!$mat) {
            ok( $mat,      "Found 3p mature locus stats for $gffMat->{id} ($gffMat->{dname})" );
            next;
         }
         if ($mat->{count} != $hp->{'3pOnly'}) {
            is( $mat->{count}, $hp->{'3pOnly'}, "3p mature count for $gffMat->{dname} matches 3pOnly for $hp->{name}" );
         }
      }
   }
   ok( $nGood5p,           "Found $nGood5p hairpins with 'good' 5p mature locus stats" );
   ok( $nGood3p,           "Found $nGood3p hairpins with 'good' 3p mature locus stats" );
}

#=====================================================================================
# Combined stats tests
#=====================================================================================

sub h01_MirStats_newCombined : Test(147) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   dies_ok { MirStats->newCombined(); }        "MirStats->newCombined() dies";
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $hInf = getGffInfo();
   
   my @objs; 
   my $res  = MirStats->newFromBamFull(bam=>$bamF, mirInfo=>$hInf, bamLoc=>'hsa-mir-22');
   isa_ok( ref($res), 'MirStats',              "MirStats->newCombined(bamLoc=>'hsa-mir-22') ok" );
   is(  $res->{stats}->{nAlign},   28,         "  nAlign   28" );
   is(  $res->{stats}->{nGoodMat}, 28,         "  nGoodMat 28" );
   push( @objs, $res );
   $res  = MirStats->newFromBamFull(bam=>$bamF, mirInfo=>$hInf, bamLoc=>'hsa-mir-504', margin=>6);
   isa_ok( ref($res), 'MirStats',              "MirStats->newCombined(bamLoc=>'hsa-mir-504') ok" );
   is(  $res->{stats}->{nAlign},    3,         "  nAlign   3" );
   is(  $res->{stats}->{nGoodMat},  2,         "  nGoodMat 2" );
   push( @objs, $res, $res );

   $res = undef;
   lives_ok { $res = MirStats->newCombined(name => 'testCmb', mirInfo => $hInf, objects => \@objs) }   
                                               "MirStats->newCombined(" . scalar(@objs) . " objects) lives";
   return "error" unless $res;
   isa_ok( ref($res), 'MirStats',              "  isa MirStats" );
   is( $res->{stats}->{nAlign},     34,        "  nAlign   34" );
   is( $res->{stats}->{nGoodMat},   32,        "  nGoodMat 32" );
   is( $res->getObjects('hairpin'),  2,        "  has 2 hairpin objects" );
   is( $res->getObjects('mature'),   3,        "  has 3 mature locus objects" );
   is( $res->getObjects('matseq'),   3,        "  has 3 matseq objects" ); 

   # check that basic stats are combined
   my $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin" );
   is( $obj->{name},   'hsa-mir-504',         "  name hsa-mir-504" );
   is( $obj->{count},      6,                 "  count     6" );
   is( $obj->{dup},        6,                 "  dup       6" );
   is( $obj->{oppStrand},  0,                 "  oppStrand 0" );
   is( $obj->{mm0},        4,                 "  mm0       4" );
   is( $obj->{mm1},        2,                 "  mm1       2" );
   is( $obj->{mm2},        0,                 "  mm2       0" );
   is( $obj->{mm3p},       0,                 "  mm3p      0" );
   is( $obj->{indel},      0,                 "  indel     0" );
   is( $obj->{mq0},        0,                 "  mq0       0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19    0" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29   0" );
   is( $obj->{mq30p},      6,                 "  mq30p     6" ); 
   is( $obj->{'5pOnly'},   4,                 "  5pOnly    4" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   2,                 "  3pPlus    2" );
   is( $obj->{'5and3p'},   0,                 "  5and3p    0" ); 
   is( $obj->{totBase},   2*(29+23+37),       "  totBase 188" );
   is( $obj->{'5pBase'},  88,                 "  5pBase   88" );
   is( $obj->{'3pBase'},  42,                 "  3pBase   42" ); 
   is( ref($obj->{hairpin}), 'HASH',          "  has MirInfo hairpin" ); 

   # check that coverage data is combined
   is( $obj->{totBase},    2*(29+23+37),      "  totBase  " . 2*(29+23+37) . "");
   my $cov = $obj->{coverage};
   is( ref($cov),      'ARRAY',               "  coverage ARRAY ref" );
   cmp_ok( @$cov,      '>=',  71,             "    length >= 71" );
   my $expected = []; 
   for (my $ix=7; $ix<=35; $ix++)  { $expected->[$ix] = ($expected->[$ix] || 0) + 2; }
   for (my $ix=12; $ix<=34; $ix++) { $expected->[$ix] = ($expected->[$ix] || 0) + 2; }
   for (my $ix=35; $ix<=71; $ix++) { $expected->[$ix] = ($expected->[$ix] || 0) + 2; }
   for (my $ix=0; $ix<=@$expected; $ix++) {
      is( $cov->[$ix], $expected->[$ix],      "    pos $ix " . ( $expected->[$ix] || 'undef') . "");
   }

   # chrX mature  137749921 137749942 - ID=MIMAT0002875;Alias=MIMAT0002875;Name=hsa-miR-504-5p;Derives_from=MI0003189
   # chrX mature  137749885 137749905 - ID=MIMAT0026612;Alias=MIMAT0026612;Name=hsa-miR-504-3p;Derives_from=MI0003189

   # check that mature locus stats are combined
   ok( !$res->{mature}->{'MIMAT0026612'},     "no MIMAT0026612 mature locus stats (hsa-miR-504-3p)" );
   $obj = $res->{mature}->{'MIMAT0002875'};
   is( ref($obj),      'HASH',                "has MIMAT0002875 mature locus stats (hsa-miR-504-5p)" );  
   is( $obj->{count},      4,                 "  count       4" );
   is( $obj->{dup},        4,                 "  dup         4" );
   is( $obj->{oppStrand},  0,                 "  oppStrand   0" );
   is( $obj->{mm0},        4,                 "  mm0         4" );
   is( $obj->{mm1},        0,                 "  mm1         2" );
   is( $obj->{mm2},        0,                 "  mm2         0" );
   is( $obj->{mm3p},       0,                 "  mm3p        0" );
   is( $obj->{indel},      0,                 "  indel       0" );
   is( $obj->{mq0},        0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19      0" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29     0" );
   is( $obj->{mq30p},      4,                 "  mq30p       4" ); 
   is( $obj->{totBase},   88,                 "  totBase    88" );
   is( ref($obj->{mature}), 'HASH',           "  has MirInfo mature locus obj" ); 

   # check that mature locus stats are combined
   ok( !$res->{matseq}->{'MIMAT0026612'},     "no MIMAT0026612 matseq stats (hsa-miR-504-3p)" );
   $obj = $res->{matseq}->{'MIMAT0002875'};
   is( ref($obj),      'HASH',                "has MIMAT0002875 matseq stats (hsa-miR-504-5p)" ); 
   is( $obj->{name},   'hsa-miR-504-5p',      "  name hsa-miR-504-5p" );
   is( $obj->{dname},  'hsa-miR-504-5p[1]',   "  dname hsa-miR-504-5p[1]" );
   is( $obj->{count},      4,                 "  count       4" );
   is( $obj->{dup},        4,                 "  dup         4" );
   is( $obj->{oppStrand},  0,                 "  oppStrand   0" );
   is( $obj->{mm0},        4,                 "  mm0         4" );
   is( $obj->{mm1},        0,                 "  mm1         2" );
   is( $obj->{mm2},        0,                 "  mm2         0" );
   is( $obj->{mm3p},       0,                 "  mm3p        0" );
   is( $obj->{indel},      0,                 "  indel       0" );
   is( $obj->{mq0},        0,                 "  mq0         0" );
   is( $obj->{'mq1-19'},   0,                 "  mq1-19      0" );
   is( $obj->{'mq20-29'},  0,                 "  mq20-29     0" );
   is( $obj->{mq30p},      4,                 "  mq30p       4" ); 
   is( $obj->{totBase},   88,                 "  totBase    88" );
   is( ref($obj->{matseq}), 'HASH',           "  has MirInfo matseq" ); 
}
sub h02_MirStats_combineStats_full: Test(173) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res  = getTestMirStatsFull(); 
   ok( $res,                                           "getTestMirStatsFull() ok" );  
   my $hInf = getGffInfoFull();
   my $name = 'testDataCmb';
   my $hcmb;
   lives_ok { $hcmb = MirStats->newCombined(name=>$name, objects=>[$res, $res], mirInfo=>$hInf) }
                                                       "MirStats->newCobined(2 objects) ok";
   return ("error") unless $hcmb;
   is( $hcmb->{name}, "$name",                         "  name $name" );
   
   foreach my $type (@MirStats::HP_TYPES) {
      my $stats = $hcmb->{stats}->{$type} ;
      is( ref($stats), 'HASH',                         "  type $type cmb stats HASH" );
      return ("error") unless ref($stats) eq 'HASH';
      foreach (@MirStats::HP_COUNT_FIELDS) { 
         is( ($stats->{$_} || 0), 
             2 * $res->{stats}->{$type}->{$_},         "    cmb $_ $stats->{$_} is double" );
      }
      
      my @objs  = $hcmb->getObjects($type);
      my $nObjs = @objs;
      ok( @objs,                                       "  $type has stats objects" );
      is( $nObjs, $res->getObjects($type),             "    cmb objs $nObjs is res count " );
   }

   foreach my $type (@MirStats::MATURE_TYPES) {
      my $stats = $hcmb->{stats}->{$type} ;
      is( ref($stats), 'HASH',                         "  type $type cmb stats HASH" );
      return ("error") unless ref($stats) eq 'HASH';
      foreach (@MirStats::MATURE_COUNT_FIELDS) { 
         is( ($stats->{$_} || 0), 
             2 * $res->{stats}->{$type}->{$_},         "    cmb $_ $stats->{$_} is double" );
      }
      
      my @objs  = $hcmb->getObjects($type);
      my $nObjs = @objs;
      ok( @objs,                                       "  $type has stats objects" );
      is( $nObjs, $res->getObjects($type),             "    cmb objs $nObjs is res count " );
   }
}

#=====================================================================================
# Stats output tests (large bam file)
#=====================================================================================

sub checkStatsFile {
   my ($res, $name, $type, $flds, $empty) = @_;

   $res->{name} = $name;
   my $hFile = "$name.$type.hist" unless $type eq 'coverage';
   $hFile = "$name.coverage" if $type eq 'coverage';
   unlink( $hFile );
   ok( ! -e $hFile,                                  "no $type file '$hFile'" );

   my $num = $res->getObjects($type) unless $type eq 'coverage';
   $num = $res->getObjects('hairpin') if $type eq 'coverage';

   my $ct = 0;
   if ($type eq 'coverage') {
      lives_ok { $ct = $res->writeCoverage(); }      "writeCoverage() ok";
   } elsif ($type eq 'mature' || $type eq 'matseq') {
      lives_ok { $ct = $res->writeMature($type); }   "writeMature($type) ok";
   } else {
      lives_ok { $ct = $res->writeStats($type); }    "writeStats($type) ok";
   }
   if ($empty) {
      is( $ct, 0,                                    "  wrote 0 stats" );
      ok( ! -e $hFile,                               "  still no $type file '$hFile'" );
   } else {
      cmp_ok( $ct, '>', 0,                           "  wrote some stats" );
   }
   my @lines;
   if ($ct > 0) {
      is( $ct,    $num,                              "  wrote $num $type stats" );
      ok( -e $hFile,                                 "  $type file '$hFile' exists" );
      @lines = __readTestFile($hFile);
      is( @lines, $num+1,                            "  has " . ($num+1) . " lines" );
   }
   if (ref($flds) eq 'ARRAY') {
      my $hdr = $lines[0];
      ok( $hdr,                                      "  hdr not empty" );
      $hdr =~s/\n//;
      my @flds = split(/\t/, $hdr);
      my @expected = @$flds;
      is( @flds,          @expected,                 "  has " . scalar(@expected) . " fields" );
      for (my $ix=0; $ix<@expected; $ix++) {
         is( $flds[$ix], $expected[$ix],             "  fld $expected[$ix] found" );
      }
   }
   return ($ct, $hFile, @lines);
}

sub i01_MirStats_writeStats: Test(61) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $name = 'mirTestData';
   my $res  = getTestMirStatsFull(); 
   ok( $res,                                         "getTestMirStatsFull() ok" );

   # Hairpin stats
   my ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'hairpin', \@MirStats::ALL_HP_FIELDS); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Group stats
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'group'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Family stats
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'family'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Cluster stats
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'cluster'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Cluster+ stats
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'cluster+'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Cluster- stats
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'cluster-'); 
   unlink( $hFile ) unless $KEEP_FILES;
}

sub i11_MirStats_writeMature: Test(47) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $name = 'matureTestData';
   my $res  = getTestMirStats(); 
   ok( $res,                                         "getTestMirStats() ok" );

   # Mature loci stats
   my ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'mature', \@MirStats::ALL_MATURE_FIELDS); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Mature sequence stats
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'matseq', \@MirStats::ALL_MATURE_FIELDS); 
   unlink( $hFile ) unless $KEEP_FILES;
}

sub i21_MirStats_writeCoverage: Test(19) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $name = 'covTestData';
   my $res  = getTestMirStats(); 
   ok( $res,                                         "getTestMirStats() ok" );
   
   # Coverage stats
   # there should be an entry for every hairpin whether or not it has a GFF entry
   my ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'coverage'); 
   my $hdr = $lines[0];
   ok( $hdr,                                         "  hdr not empty" );
   chomp($hdr);
   my @flds = split(/\t/, $hdr);
   my @expected = @MirStats::COVERAGE_FIELDS;
   cmp_ok( @flds, '>', @expected,                    "  at least " . scalar(@expected) . " fields" );
   for (my $ix=0; $ix<@expected; $ix++) {
      is( $flds[$ix], $expected[$ix],                "  fld $expected[$ix] found" );
   }
   unlink( $hFile ) unless $KEEP_FILES;
}

sub i31_MirStats_writeOutput_combined: Test(109) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $res  = getTestMirStatsFull(); 
   ok( $res,                                         "getTestMirStatsFull() ok" );
   
   my $hInf = getGffInfo();
   my $name = 'testDataCmb';
   my $hcmb;
   lives_ok { $hcmb = MirStats->newCombined(name=>$name, objects=>[$res, $res], mirInfo=>$hInf) }
                                                     "MirStats->newCobined(2 objects) ok";
   return ("error") unless $hcmb;

   # Hairpin stats
   my ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'hairpin', \@MirStats::ALL_HP_FIELDS); 
   unlink( $hFile ) unless $KEEP_FILES; 

   # Group stats
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'group'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Family stats
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'family'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Cluster stats
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'cluster'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Cluster+ stats
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'cluster+'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Cluster- stats
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'cluster-'); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Coverage stats
   # there should be an entry for every hairpin whether or not it has a GFF entry
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'coverage'); 
   my $hdr = $lines[0];
   ok( $hdr,                                         "  hdr not empty" );
   chomp($hdr);
   my @flds = split(/\t/, $hdr);
   my @expected = @MirStats::COVERAGE_FIELDS;
   cmp_ok( @flds, '>', @expected,                    "  at least " . scalar(@expected) . " fields" );
   for (my $ix=0; $ix<@expected; $ix++) {
      is( $flds[$ix], $expected[$ix],                "  fld $expected[$ix] found" );
   }
   unlink( $hFile ) unless $KEEP_FILES;

   # Mature loci stats
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'mature', \@MirStats::ALL_MATURE_FIELDS); 
   unlink( $hFile ) unless $KEEP_FILES;

   # Mature sequence stats
   ($ct, $hFile, @lines) = checkStatsFile($hcmb, $name, 'matseq'); 
   unlink( $hFile ) unless $KEEP_FILES;
}

#=====================================================================================
# Output tests (detail)
#=====================================================================================

sub checkLine {
   my ($hdr, $line, $obj, $flds) = @_;
   $flds = \@MirStats::HP_COUNT_FIELDS unless ref($flds) eq 'ARRAY';
   $hdr =~s/\n//; $line =~s/\n//;
   my @flds = split(/\t/, $hdr);
   my @vals = split(/\t/, $line);
   my $name = $obj->{name}; $name = $obj->{dname} if $obj->{dname};
   my $ob2  = {};
   $ob2->{name} = $name;
   for (my $ix=0; $ix<@flds; $ix++) { $ob2->{ $flds[$ix] } = $vals[$ix]; }
   is( $vals[0],   $ob2->{name},                     "  name is $ob2->{name}" );
   foreach (@$flds) {
      my $val = $obj->{$_};
      my $str = defined($val) ? $val : "''";
      is( $ob2->{$_},  $obj->{$_},                   "  fld $_ is $str" );
   }
}
sub j01_MirStats_writeStats_noGff_mir : Test(119) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $hInf = getGffInfoFull();
   my ($res, $obj);

   my $name   = 'mir-1273e';
   my $locStr = 'hsa-mir-1273e';
   lives_ok { $res = MirStats->newFromBamFull(bam => $bamF, mirInfo => $hInf, bamLoc => $locStr);  }          
                                                     "MirStats->newFromBam(bamLoc=>'$locStr') lives";
   return("error") if !$res;      
   isa_ok( $res, 'MirStats',                         "  isa MirStats" );
   is( $res->getObjects('hairpin'), 1,               "  has 1 hairpin stats object" );

   # hsa-mir-1273e has no annotation in v20 miRBase gff, although it is in their hairpin.fa file.
   # our data has 3 alignments to hsa-mir-1273e, all bad
   is( $res->{stats}->{nAlign},    3,                "  nAlign    3" );
   is( $res->{stats}->{nGoodMat},  0,                "  nGoodMat  0" );
   is( $res->{stats}->{totBase}, 138,                "  totBase 138" );

   # hairpin stats
   $obj = $res->{hairpin}->{'hsa-mir-1273e'};
   is( ref($obj),      'HASH',                       "hsa-mir-1273e hairpin stats" );
   is( $obj->{name},   'hsa-mir-1273e',              "  name  hsa-mir-1273e" );
   is( $obj->{dname},  'hsa-mir-1273e(unk)',         "  dname hsa-mir-1273e(unk)" );
   is( $obj->{count},      3,                        "  count     3" );
   
   my ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'hairpin');
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $obj);
   unlink( $hFile ) unless $KEEP_FILES;

   # group stats
   $obj = $res->{group}->{'hsa-mir-1273e'};
   is( ref($obj),      'HASH',                       "hsa-mir-1273e group stats" );
   is( $obj->{name},   'hsa-mir-1273e',              "  name  hsa-mir-1273e" );
   is( $obj->{dname},  'hsa-mir-1273e[unk]',         "  dname hsa-mir-1273e[unk]" );
   is( $obj->{count},      3,                        "  count     3" );
   
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'group');
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $obj);
   unlink( $hFile ) unless $KEEP_FILES;

   # family stats
   $obj = $res->{family}->{'hsa-mir-1273e'};
   is( ref($obj),      'HASH',                       "hsa-mir-1273e family stats" ); 
   is( $obj->{name},   'hsa-mir-1273e',              "  name  hsa-mir-1273e" );
   is( $obj->{dname},  'hsa-mir-1273e[unk]',         "  dname hsa-mir-1273e[unk]" );
   is( $obj->{count},      3,                        "  count     3" );
   
   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'family');
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $obj);
   unlink( $hFile ) unless $KEEP_FILES;

   # none of these stats files will be written since there is no GFF metadata
   checkStatsFile($res, $name, 'mature',   undef, 1);
   checkStatsFile($res, $name, 'matseq',   undef, 1);
   checkStatsFile($res, $name, 'cluster',  undef, 1);
   checkStatsFile($res, $name, 'cluster+', undef, 1);
   checkStatsFile($res, $name, 'cluster-', undef, 1);
}
sub j02_MirStats_MirStats_writeStats_detail : Test(262) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   ok( -e $bamF,                                     "MirStats_newFromBamLoc bam exists" );
   my $hInf = getGffInfoFull();
   my $name = "mir-105";
   my $res;

   # hsa-mir-105-1 and hsa-mir-105-2 form a transript group hsa-mir-105[2] and matseq groups hsa-miR-105-5p[2] hsa-miR-105-3p[2]
   #   chrX hairpin 151560691 151560771 - ID=MI0000111;Alias=MI0000111;Name=hsa-mir-105-1
   #   chrX mature  151560737 151560759 - ID=MIMAT0000102;Alias=MIMAT0000102;Name=hsa-miR-105-5p;Derives_from=MI0000111
   #   chrX mature  151560700 151560721 - ID=MIMAT0004516;Alias=MIMAT0004516;Name=hsa-miR-105-3p;Derives_from=MI0000111
   #   chrX hairpin 151562884 151562964 - ID=MI0000112;Alias=MI0000112;Name=hsa-mir-105-2
   #   chrX mature  151562930 151562952 - ID=MIMAT0000102_1;Alias=MIMAT0000102;Name=hsa-miR-105-5p;Derives_from=MI0000112
   #   chrX mature  151562893 151562914 - ID=MIMAT0004516_1;Alias=MIMAT0004516;Name=hsa-miR-105-3p;Derives_from=MI0000112
   # test data has 36 alignments to hsa-mir-105-1, 24 to hsa-mir-105-2; all are "good fit" 5p
   lives_ok { $res = MirStats->newFromBamFull(bam => $bamF, mirInfo => $hInf, bamLoc => 'hsa-mir-105-1 hsa-mir-105-2');  }          
                                                     "MirStats->newFromBam(bamLoc=>'hsa-mir-105-1 hsa-mir-105-2') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                         "  isa MirStats" );
   is( $res->getObjects('hairpin'), 2,               "  2 hairpin objects" );
   is( $res->getObjects('group'),   1,               "  1 group objects" );
   is( $res->getObjects('family'),  1,               "  1 family objects" );
   is( $res->getObjects('mature'),  2,               "  2 mature locus object" );
   is( $res->getObjects('matseq'),  1,               "  1 matseq object" );
   is( $res->{stats}->{nAlign},    60,               "  nAlign    60" );
   is( $res->{stats}->{nGoodMat},  60,               "  nGoodMat  60" );  

   # hairpin stats
   my $ob1 = $res->{hairpin}->{'hsa-mir-105-1'};
   is( ref($ob1),      'HASH',                       "hsa-mir-105-1 hairpin stats" );
   is( $ob1->{name},   'hsa-mir-105-1',              "  name  hsa-mir-105-1" );
   is( $ob1->{count},     36,                        "  count    36" );
   my $ob2 = $res->{hairpin}->{'hsa-mir-105-2'};
   is( ref($ob2),      'HASH',                       "hsa-mir-105-1 hairpin stats" );
   is( $ob2->{name},   'hsa-mir-105-2',              "  name  hsa-mir-105-2" );
   is( $ob2->{count},     24,                        "  count    24" );

   my ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'hairpin');
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $ob1);
   checkLine($lines[0], $lines[2], $ob2);
   unlink( $hFile ) unless $KEEP_FILES;

   # mature stats
   my $ma1 = $res->{mature}->{'MIMAT0000102'};
   is( ref($ma1),       'HASH',                          "MIMAT0000102 mature" );
   is( $ma1->{id},      'MIMAT0000102',                  "  id      MIMAT0000102" );
   is( $ma1->{name},    'hsa-miR-105-5p',                "  name    hsa-miR-105-5p" );
   is( $ma1->{dname},   'hsa-mir-105-1(hsa-miR-105-5p)', "  dname   hsa-mir-105-1(hsa-miR-105-5p)" );
   is( $ma1->{count},           36,                      "  count     36" );
   my $ma2 = $res->{mature}->{'MIMAT0000102_1'};
   is( ref($ma2),       'HASH',                          "MIMAT0000102_1 mature" );
   is( $ma2->{id},      'MIMAT0000102_1',                "  id      MIMAT0000102_1" );
   is( $ma2->{name},    'hsa-miR-105-5p',                "  name    hsa-miR-105-5p" );
   is( $ma2->{dname},   'hsa-mir-105-2(hsa-miR-105-5p)', "  dname   hsa-mir-105-1(hsa-miR-105-5p)" );
   is( $ma2->{count},           24,                      "  count     24" );

   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'mature');
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $ma1, \@MirStats::MATURE_COUNT_FIELDS);
   checkLine($lines[0], $lines[2], $ma2, \@MirStats::MATURE_COUNT_FIELDS);
   unlink( $hFile ) unless $KEEP_FILES;

   # matseq stats
   my $ms3 = $res->{matseq}->{'MIMAT0000102'};
   is( ref($ms3),       'HASH',                          "MIMAT0000102 hsa-miR-105-5p matseq" ); 
   is( $ms3->{id},      'MIMAT0000102',                  "  id      MIMAT0000102" );
   is( $ms3->{name},    'hsa-miR-105-5p',                "  name  hsa-miR-105-5p" );
   is( $ms3->{dname},   'hsa-miR-105-5p[2]',             "  dname hsa-miR-105-5p[2]" );
   is( $ms3->{count},       60,                          "  count     60" ); 

   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'matseq'); 
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $ms3, \@MirStats::MATURE_COUNT_FIELDS);
   unlink( $hFile ) unless $KEEP_FILES;

   # group stats
   my $hpg = $res->{group}->{'hsa-mir-105'};
   is( ref($hpg),       'HASH',                          "hsa-mir-105 group" ); 
   is( $hpg->{name},    'hsa-mir-105',                   "  name  hsa-mir-105" );
   is( $hpg->{dname},   'hsa-mir-105[2]',                "  dname hsa-mir-105[2]" );
   is( $hpg->{count},       60,                          "  count     60" );

   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'group'); 
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $hpg);
   unlink( $hFile ) unless $KEEP_FILES;

   # family stats
   my $hpf = $res->{family}->{'mir-105'};
   is( ref($hpf),       'HASH',                          "mir-105 family" ); 
   is( $hpf->{name},    'mir-105',                       "  name  mir-105" );
   is( $hpf->{dname},   'mir-105[2]',                    "  dname mir-105[2]" );
   is( $hpf->{count},       60,                          "  count     60" );

   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'group'); 
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $hpf);
   unlink( $hFile ) unless $KEEP_FILES;

   # cluster stats
   my $gffHp1 = $res->{mirInfo}->{hairpin}->{$ob1->{name}};
   isa_ok( $gffHp1, 'HASH',                              "$ob1->{name} MirInfo HASH" );
   my $clid = $gffHp1->{clusterObj}->{id};
   my $cldn = $gffHp1->{clusterObj}->{dname};
   my $hpc  = $res->{cluster}->{$clid};
   is( ref($hpc),       'HASH',                          "$ob1->{name} cluster" ); 
   is( $hpc->{name},     $clid,                          "  name  $clid" );
   is( $hpc->{dname},    $cldn,                          "  dname $cldn" );
   is( $hpc->{count},       60,                          "  count     60" );

   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'cluster'); 
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $hpc);
   unlink( $hFile ) unless $KEEP_FILES;

   # cluster- stats
   $clid = $gffHp1->{'cluster-Obj'}->{id};
   $cldn = $gffHp1->{'cluster-Obj'}->{dname};
   $hpc  = $res->{'cluster-'}->{$clid};
   is( ref($hpc),       'HASH',                          "$ob1->{name} cluster-" ); 
   is( $hpc->{name},     $clid,                          "  name  $clid" );
   is( $hpc->{dname},    $cldn,                          "  dname $cldn" );
   is( $hpc->{count},       60,                          "  count     60" );

   ($ct, $hFile, @lines) = checkStatsFile($res, $name, 'cluster-'); 
   return "error" unless $ct;
   checkLine($lines[0], $lines[1], $hpc);
   unlink( $hFile ) unless $KEEP_FILES;

   # no cluster+ file (hairpins are on - strand)
   checkStatsFile($res, $name, 'cluster+', undef, 1);
}

#=====================================================================================
# Alignment filtering tests
#=====================================================================================

sub k01_MirStats_writeFilteredAlns : Test(40) {
   return($SKIP_ME_MSG) if $SKIP_ME;
   
   my $bamF = __testDataDir() . "/mb_test_1x101.sort.dup.bam";
   my $hInf = getGffInfo();
   my ($res, $obj);

   my $locStr = 'hsa-mir-6807 hsa-mir-636 hsa-mir-504 hsa-mir-214';
   lives_ok { $res = MirStats->newFromBam(bam => $bamF, mirInfo => $hInf, bamLoc => $locStr);  }          
                                              "MirStats->newFromBam(bamLoc=>'$locStr') lives";
   return("error") if !$res;  
   isa_ok( $res, 'MirStats',                  "  isa MirStats" );
   is( $res->{stats}->{nAlign}, 7,            "  nAlign   7" );
   is( $res->{stats}->{nGoodMat}, 3,          "  nGoodMat 3" );
   is( $res->getObjects('hairpin'), 4,        "  has 4 hairpin stats objects" );

   $obj = $res->{hairpin}->{'hsa-mir-6807'};
   is( ref($obj),      'HASH',                "hsa-mir-6807 hairpin stats" );
   is( $obj->{count},      2,                 "  count     2" );
   is( $obj->{'5pOnly'},   1,                 "  5pOnly    1" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus    1" );

   $obj = $res->{hairpin}->{'hsa-mir-636'};
   is( ref($obj),      'HASH',                "hsa-mir-636 hairpin stats" );
   is( $obj->{count},      1,                 "  count     1" );
   is( $obj->{'5pOnly'},   0,                 "  5pOnly    0" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus    1" );
   
   $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{count},      3,                 "  count     3" );
   is( $obj->{'5pOnly'},   1,                 "  5pOnly    1" );
   is( $obj->{'5pPlus'},   1,                 "  5pPlus    1" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus    1" );
   
   $obj = $res->{hairpin}->{'hsa-mir-214'};
   is( ref($obj),      'HASH',                "hsa-mir-214 hairpin stats" );
   is( $obj->{count},      1,                 "  count     1" );
   is( $obj->{'5pOnly'},   1,                 "  5pOnly    1" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus    0" );

   my $fres = MirStats->new(bam => $bamF, mirInfo => $hInf, bamLoc => $locStr);
   isa_ok( $fres, 'MirStats',                 "MirStats->new(bamLoc=>'$locStr') ok" );

   my $name  = "filtAlnTest";
   my $outF1 = "./$name.goodFit.sam";
   my $outF2 = "./$name.other.sam";
   unlink($outF1, $outF2);
   ok( ! -e $outF1,                           "  no file '$outF1'" );
   ok( ! -e $outF2,                           "  no file '$outF2'" );

   my ($nRec, $nGood, $goodF, $nOther, $otherF);
   $fres->{name} = $name;
   lives_ok {  ($nRec, $nGood, $goodF, $nOther, $otherF) = $fres->writeFilteredAlns('sam'); } "writeFilteredAlns(sam) lives";
   return "error" unless $nRec;
   ok( -e $outF1,                             "  file exists: '$outF1'" );
   ok( -e $outF2,                             "  file exists: '$outF2'" );

   my $expTot  = $res->{stats}->{nAlign};
   my $expGood = $res->{stats}->{nGoodMat};
   my $expRest = $expTot - $expGood;
   is( $nRec,   $expTot,                      "  total aligns: $expTot" );
   is( $nGood,  $expGood,                     "    good fit:   $expGood" );
   is( $nOther, $expRest,                     "    other:      $expRest" );

   # output file will have SAM header
   my @lines = __readTestFile($outF1);
   cmp_ok( @lines, '>', $expGood,             "  goodFit file has > $expGood lines" );
   @lines = __readTestFile($outF2);
   cmp_ok( @lines, '>', $expRest,             "  other   file has > $expRest lines" );

   unlink($outF1, $outF2) unless $KEEP_FILES;
}

#=====================================================================================
# SAM file support
#=====================================================================================

# test SAM file contains the following miRs from the larger mb_test_1x101.sort.dup.bam file
#  hsa-let-7a-1 -2 -3, 
#  hsa-let-7e hsa-let-7f-1 hsa-let-7g hsa-let-7i
#  hsa-mir-105-1 hsa-mir-105-2
#  hsa-mir-1273e
#  hsa-mir-217  
#  hsa-mir-22
#  hsa-mir-504
sub l01_MirStats_SAM_file: Test(35) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $samF = __testDataDir() . "/mb_test_small.sam.gz";
   my $hInf = getGffInfoFull();
   
   my $res;
   lives_ok { $res  = MirStats->newFromBamFull(bam=>$samF, mirInfo=>$hInf); } "MirStats->newFromBamFull(SAM file) lives";
   isa_ok( ref($res), 'MirStats',              "  isa MirStats" );
   return "error" unless $res;

   my @hps = qw( hsa-let-7a-1 hsa-let-7a-2 hsa-let-7a-3
                 hsa-let-7e hsa-let-7f-1 hsa-let-7g hsa-let-7i
                 hsa-mir-105-1 hsa-mir-105-2 
                 hsa-mir-1273e hsa-mir-217 hsa-mir-22 hsa-mir-504 );
   my @grps = qw( hsa-let-7a
                  hsa-let-7e hsa-let-7f hsa-let-7g hsa-let-7i
                  hsa-mir-105
                  hsa-mir-1273e hsa-mir-217 hsa-mir-22 hsa-mir-504 );
   my @fams = qw( let-7
                  mir-105
                  hsa-mir-1273e mir-217 mir-22 mir-504 );
   is( $res->{stats}->{nAlign},      3218,     "  nAlign   3218" );

   is( $res->getObjects('hairpin'),  @hps,     "has " . scalar(@hps)  . " hairpin objects" );
   foreach (@hps) {
      is(ref($res->{hairpin}->{$_}), 'HASH',   " hairpin stats $_ found" );
   }
   is( $res->getObjects('group'),    @grps,    "has " . scalar(@grps) . " group objects" );
   foreach (@grps) {
      is(ref($res->{group}->{$_}), 'HASH',     " group stats $_ found" );
   }
   is( $res->getObjects('family'),   @fams,    "has " . scalar(@fams) . " family objects" );
   foreach (@fams) {
      is(ref($res->{family}->{$_}), 'HASH',    " family stats $_ found" );
   }
}
sub l02_MirStats_writeFilteredAlns_fromSAM : Test(32) {
   return($SKIP_ME_MSG) if $SKIP_ME;

   my $samF = __testDataDir() . "/mb_test_small.sam.gz";
   my $hInf = getGffInfoFull();
   
   my $res;
   lives_ok { $res  = MirStats->newFromBamFull(bam=>$samF, mirInfo=>$hInf); } "MirStats->newFromBamFull(SAM file) lives";
   isa_ok( ref($res), 'MirStats',              "  isa MirStats" );
   return "error" unless $res;

   my @hps = qw( hsa-let-7a-1 hsa-let-7a-2 hsa-let-7a-3
                 hsa-let-7e hsa-let-7f-1 hsa-let-7g hsa-let-7i
                 hsa-mir-105-1 hsa-mir-105-2 
                 hsa-mir-1273e hsa-mir-217 hsa-mir-22 hsa-mir-504 );
   is( $res->getObjects('hairpin'),  @hps,     "has " . scalar(@hps)  . " hairpin objects" );
   
   my $obj = $res->{hairpin}->{'hsa-mir-504'};
   is( ref($obj),      'HASH',                "hsa-mir-504 hairpin stats" );
   is( $obj->{count},      3,                 "  count     3" );
   is( $obj->{'5pOnly'},   1,                 "  5pOnly    1" );
   is( $obj->{'5pPlus'},   1,                 "  5pPlus    1" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   1,                 "  3pPlus    1" );
   
   $obj = $res->{hairpin}->{'hsa-mir-105-1'};
   is( ref($obj),      'HASH',                "hsa-mir-105-1 hairpin stats" );
   is( $obj->{count},     36,                 "  count    36" );
   is( $obj->{'5pOnly'},  36,                 "  5pOnly   36" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus    0" );
   
   $obj = $res->{hairpin}->{'hsa-mir-105-2'};
   is( ref($obj),      'HASH',                "hsa-mir-105-2 hairpin stats" );
   is( $obj->{count},     24,                 "  count    24" );
   is( $obj->{'5pOnly'},  24,                 "  5pOnly   24" );
   is( $obj->{'5pPlus'},   0,                 "  5pPlus    0" );
   is( $obj->{'3pOnly'},   0,                 "  3pOnly    0" );
   is( $obj->{'3pPlus'},   0,                 "  3pPlus    0" );

   my $fres = MirStats->new(bam => $samF, mirInfo => $hInf);
   isa_ok( $fres, 'MirStats',                 "MirStats->new(bam=><SAM file>) ok" );

   my $name  = "filtAlnSAMTest";
   my $outF1 = "./$name.goodFit.sam";
   my $outF2 = "./$name.other.sam";
   unlink($outF1, $outF2);
   ok( ! -e $outF1,                           "  no file '$outF1'" );
   ok( ! -e $outF2,                           "  no file '$outF2'" );

   my ($nRec, $nGood, $goodF, $nOther, $otherF);
   $fres->{name} = $name;
   lives_ok {  ($nRec, $nGood, $goodF, $nOther, $otherF) = $fres->writeFilteredAlns('sam'); } "writeFilteredAlns(sam) lives";
   return "error" unless $nRec;
   ok( -e $outF1,                             "  file exists: '$outF1'" );
   ok( -e $outF2,                             "  file exists: '$outF2'" );

   my $expTot  = $res->{stats}->{nAlign};
   my $expGood = $res->{stats}->{nGoodMat};
   my $expRest = $expTot - $expGood;
   is( $nRec,   $expTot,                      "  total aligns: $expTot" );
   is( $nGood,  $expGood,                     "    good fit:   $expGood" );
   is( $nOther, $expRest,                     "    other:      $expRest" );

   # output file will have SAM header
   my @lines = __readTestFile($outF1);
   cmp_ok( @lines, '>', $expGood,             "  goodFit file has > $expGood lines" );
   @lines = __readTestFile($outF2);
   cmp_ok( @lines, '>', $expRest,             "  other   file has > $expRest lines" );

   unlink($outF1, $outF2) unless $KEEP_FILES;
}


#=====================================================================================

1;


