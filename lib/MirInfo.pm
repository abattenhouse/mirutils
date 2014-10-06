
use strict;
use File::Basename;

#####################################################################################
# MirInfo object organizes MirBase miRNA metadata
#####################################################################################

package MirInfo;

#==============================================================================
# Misc helpers
#==============================================================================

sub isMember {
   my ($val, @list) = @_;
   if (defined($val) && @list) {
      $val = "$val"; 
      foreach (@list) { 
         return 1 if defined($_) && ("$_" eq $val);
      }
   }
   return 0;
}
sub openInputSafely {
   my ($path, $bamArgs, $bamEx) = @_;
   $path = '' if !$path;
   $bamArgs = '' if !$bamArgs; $bamEx = '' if !$bamEx;
   die("File '$path' does not exist") if (!-e $path && $path ne '-');
   my $fh;
   if ($path =~ /\.gz$/) {
      open( $fh, "gzip -dc $path |")
         or die("Cannot open '$path' for input using command 'gzip -dc $path': $!");
   } elsif ($path =~ /\.bam$/) {
      if (!open( $fh, "samtools view $bamArgs $path $bamEx |")) {
         if ( -e $path ) { # file exists; probably samtools not installed
            my $msg = "Cannot open '$path' for input using command 'samtools view $bamArgs $path $bamEx'\n\n";
            $msg .= "The samtools program must be installed and accessible in order to process BAM files.\n\n";
            die($msg);
         } else {
            die("Cannot open '$path' for input: $!");
         }
      }
   } else {
      open( $fh, "$path") or die("Cannot open '$path' for input: $!");
   }
   return $fh;
}
sub openOutputSafely {
   my ($path) = @_;
   $path = '' if !$path;
   my $fh;
   if ($path =~ /\.gz$/) {
      open( $fh, "| gzip > $path") 
         or die("Cannot open '$path' for output using command 'gzip > $path': $!");
   } elsif ($path =~ /\.bam$/) {
      open( $fh, "| samtools view -b -S - > $path") 
         or die("Cannot open '$path' for output using command 'samtools view -b -S - > $path': $!");
   } else {
      open( $fh, "> $path") or die("Cannot open '$path' for output: $!");
   }
   return $fh;
}

sub parseGtfAttrs {
   my ($str) = @_;
   my $atH = {};
   my @F = split(/;/, $str);
   # Can be:   Name1=Val1;Name2=Val2
   # Can be:   Name1="Val1"; Name2='Val2'
   # Can be:   Name1 "Val1"; Name2 'Val2'
   foreach (@F) {
      if ($_ =~/([\w().%-]+)[= ]['"]?(\S+?)['"]?$/) {
         my ($name,$val) = ($1, $2);
         $atH->{$name} = $val;
      }
   }
   return $atH;
}
sub chromCmp {
   my ($chr1, $chr2) = @_;
   my ($num1, $num2, $str1, $str2);
   $num1 = $1 if $chr1 =~/^chr(\d+)/;
   $num2 = $1 if $chr2 =~/^chr(\d+)/;
   $str1 = $1 if $chr1 =~/^chr([A-Za-z]+)/;
   $str2 = $1 if $chr1 =~/^chr([A-Za-z]+)/;
   if ($num1 && $num2) { return $num1 <=> $num2;
   } elsif ($num1)     { return -1;
   } elsif ($num2)     { return  1; }
   return $chr1 cmp $chr2;
}

#==============================================================================
# Path helpers
#==============================================================================

our $MIRBASE_VERSION  = 'v21'; 
our $DEFAULT_ORGANISM = 'hsa';
our $CLUSTER_DISTANCE  = 10000;

sub getMirbaseDir {
   my ($version) = @_;
   $version      = $MIRBASE_VERSION  if !$version;
   my $mbRoot    = $ENV{MIRBASE_ROOTDIR};
   if (!$mbRoot) {
      my $hereDir = File::Basename::dirname(__FILE__);
      $mbRoot = "$hereDir/../mirbase";
   }
   return "$mbRoot/$version";
}
sub getMirbaseGff {
   my ($version, $organism) = @_;
   $organism = $DEFAULT_ORGANISM if !$organism;
   my $gff = getMirbaseDir($version) . "/genomes/$organism.gff3";
}
sub getFamilyFile {
   my ($version) = @_;
   my $fams = getMirbaseDir($version) . "/miFam.dat";
}
sub getHairpinFa {
   my ($version) = @_;
   my $fams = getMirbaseDir($version) . "/hairpin.fa";
}
sub getMatureFa {
   my ($version) = @_;
   my $fams = getMirbaseDir($version) . "/mature.fa";
}

#==============================================================================
# Constructors
#==============================================================================

our @INFO_TOTAL_FIELDS = qw(nLine nEntry nMature nMatseq nHpId nHairpin nDupHpin nGroup nMultiGrp nFamily);

# MirInfo object:
#      version:  miRBase version
#     organism:  miRBase organism prefix (e.g. hsa, mmu)
#          gff:  path of GFF for this miRBase organism/version
#        miFam:  path of miR family file for this miRBase version
#    hairpinFa:  path of hairpin fasta file for this miRBase version
#     matureFa:  path of mature fasta file for this miRBase version
# hairpinFaRNA:  HASH of hairpin.fa info for this organism
#  matureFaRNA:  HASH of mature.fa info for this organism
#  clusterDist:  inter-hairpin distance for cluster definition
#        stats:  HASH of statistics (@INFO_TOTAL_FIELDS)
#         hpid:  HASH of unique miRNA hairpin species objects keyed by ID
#      hairpin:  HASH of unique hairpin objects keyed by Name
#       mature:  HASH of unique mature miRNA species objects keyed by ID
#       matseq:  HASH of unique mature miRNA sequences keyed by MIMAT Alias
#        group:  HASH of hairpin group objects
#       family:  HASH of hairpin family objects
#      cluster:  HASH of mir clusters (+ and - strand)
#     cluster+:  HASH of mir clusters (+ strand only)
#     cluster2:  HASH of mir clusters (2 strand only)
#     chrClust:  HASH of clusters by genomic chromosome
#      byChrom:  HASH of hairpins by genomic chromosome
sub new {
   my ($class, %args) = @_;
   my $self = {}; bless $self, $class;
   foreach my $attr ( keys(%args) ) { $self->{$attr} = $args{$attr}; }
   $self->{version}     = $MIRBASE_VERSION  if !$self->{version};
   $self->{organism}    = $DEFAULT_ORGANISM if !$self->{organism};
   $self->{clusterDist} = $CLUSTER_DISTANCE if !defined($self->{clusterDist});
   if (!$self->{gff}) {
      $self->{gff}         = getMirbaseGff($self->{version}, $self->{organism});
   }
   if (!$self->{miFam}) {
      $self->{miFam}       = getFamilyFile($self->{version});
   }
   if (!$self->{hairpinFa}) {
      $self->{hairpinFa}   = getHairpinFa($self->{version});
   }
   if (!$self->{matureFa}) {
      $self->{matureFa}    = getMatureFa($self->{version});
   }
   $self->checkFiles();
   return $self;
}
sub newFromGff {
   my ($class, %args) = @_;
   my $self = $class->new(%args);
   $self->loadInfo();
   return $self;
}
sub newFromGffFull {
   my ($class, %args) = @_;
   my $self = $class->new(%args);
   $self->loadInfoFull();
   return $self;
}
sub loadInfo {
   my ($self) = @_;
   $self->loadGffInfo();
   $self->addGroupInfo();
}
sub loadInfoFull {
   my ($self) = @_;
   $self->loadGffInfo();
   $self->addGroupInfo();
   $self->addFamilyInfo();
   $self->addClusterInfo();
   $self->loadFasta();
}
sub loadFasta {
   my ($self) = @_;
   $self->{hairpinFaRNA} = $self->getRefFasta('hairpin', 'rna');
   $self->{matureFaRNA}  = $self->getRefFasta('mature',  'rna');
}
sub checkFiles {
   my ($self, $noErr) = @_;
   my $fInf = {};
   $fInf->{hairpinFa} = $self->{hairpinFa} if -e $self->{hairpinFa};
   $fInf->{matureFa}  = $self->{matureFa}  if -e $self->{matureFa};
   $fInf->{miFam}     = $self->{miFam}     if -e $self->{miFam};
   if ( -e $self->{gff} ) {
      $fInf->{gff} = $self->{gff};
      my $FH = openInputSafely($self->{gff});
      while (<$FH>) {
         last unless $_ =~/^#/;  # done with header comments section
          $self->{date}    = $1 if $_ =~/date\s+(\S+)/;
          $self->{species} = $1 if $_ =~/Chromosomal coordinates of (.*) microRNAs/;
          $self->{mirbase} = $1 if $_ =~/miRBase\s+(\S+)/;
          $self->{build}   = $1 if $_ =~/genome-build-id:\s+(\S+)/;
          $self->{acc}     = $1 if $_ =~/genome-build-accession:\s+(\S+)/;
      }
      close $FH;
   }
   foreach (qw(date species mirbase build acc) ) { $self->{$_} = '' unless $self->{$_}; }
   $self->{fileInfo} = $fInf;
   return $fInf;
}

#==============================================================================
# Metadata parsing
#==============================================================================

# common object attributes
#           id:  species accession (uniqe ID)
#         name:  species name
#        dname:  display name
#         type:  e.g. hairpin, group, mature, matseq
# composite object attributes:
#     children:  ARRAY ref of composing objects
#        numCh:  count of composing objects
# hairpin and mature object attributes
#        alias:  species alias (Alias attribute from GFF)
#  locus attrs:  chr, start, end, strand
# hairpin-specific attributes:
#           5p:  5p mature object, if any
#           3p:  3p mature object, if any
#     nextCopy:  hairpin object with duplicate name (rare)
#     groupObj:  hairpin group object 
#    familyObj:  hairpin family object (after family info added)
#   clusterObj:  hairpin cluster object (after cluster info added)
#  cluster+Obj:  hairpin cluster+ object (after cluster info added)
#  cluster-Obj:  hairpin cluster- object (after cluster info added)
# mature-specific attributes:
#       parent:  id of parent hairpin
#         pobj:  parent hairpin object
#        p5or3:  '5p' or '3p'
#    matseqObj:  mature sequence set this mature miR belongs to
sub loadGffInfo {
   my ($self) = @_;
   foreach (@INFO_TOTAL_FIELDS) { $self->{stats}->{$_} = 0; }
   my $IN   = openInputSafely($self->{gff});
   my $line = 0;
   my $htmp = {};
   while (<$IN>) { 
      $line++; 
      $self->{stats}->{nLine}++;
      next if $_ =~/^#/;
      $self->{stats}->{nEntry}++;
      chomp($_); $_=~s/\r//;
      # Format (tab-delimited):
      #  chr src(.) class start(1-based) end score(.) strand(+/-) frame(012.) attrs
      my @F      = split(/\t/, $_);
      my $atrs   = parseGtfAttrs($_);
      my $name   = $atrs->{Name}; 
      my $id     = $atrs->{ID};
      my $alias  = $atrs->{Alias} || $atrs->{accession_number};
      die("No ID attribute found for line $line:\n$_")   unless $id;
      die("No Name attribute found for line $line:\n$_") unless $name;
      die("No Alias attribute found for line $line:\n$_") unless $alias;
      my $type;
      my $obj = {};
      $obj->{chr}    = $F[0];
      $obj->{start}  = $F[3];
      $obj->{end}    = $F[4];
      $obj->{strand} = $F[6];
      $obj->{name}   = $name;
      $obj->{dname}  = $name;
      $obj->{id}     = $id;
      $obj->{alias}  = $alias;
      $obj->{length} = $obj->{end} - $obj->{start} + 1;
      if ($F[2] =~/primary/) {
         die("Duplicate hairpin mir ID '$id' line $line:\n$_") if $self->{hpid}->{$id};
         $obj->{type}   = "hairpin";
         $self->{hpid}->{$id} = $obj;
         $self->{stats}->{nHpId}++;
         # Note: hairpin microRNA names are not unique, since gene duplication can create 
         #       exact copies of an ancestral microRNA (e.g. hsa-mir-511, see below)
         # hairpin IDs (MInnnn) will always be unique for different genomic loci.
         # exact hairpin duplicates will have IDs like MInnnn_1 for the 2nd copy, MInnnn_2 for the 3rd copy, etc
         my $prev = $htmp->{name}->{$name};
         if ($prev) { # exact hairpin copy w/same name but different ID
            $self->{stats}->{nDupHpin}++;
            my $ndup = 1; $prev->{dname} = "$name(dup$ndup)"; $ndup++;
            while ($prev->{nextCopy}) {  $prev = $prev->{nextCopy}; $prev->{dname} = "$name(dup$ndup)"; $ndup++; }
            $obj->{dname} = "$name(dup$ndup)";
            $prev->{nextCopy} = $obj; 
         } else {
            $self->{stats}->{nHairpin}++;
            $self->{hairpin}->{$name} = $obj;
            $htmp->{name}->{$name} = $obj;
         }
         push( @{ $self->{byChrom}->{$obj->{chr}}->{ch} },             $obj);
         push( @{ $self->{byChrom}->{$obj->{chr}}->{$obj->{strand}} }, $obj);
      } else {
         # Note: mature microRNA names are not unique b/c the same mature sequence can be derived from 
         #       more than one hairpin. We call these duplicate mature miRNAs 'mature sequences' (matseq) 
         #       although they may or may not have the same sequence! (e.g. hsa-let-7a-3p or  hsa-let-7a-5p)
         $obj->{type}   = "mature";
         $self->{stats}->{nMature}++;
         $self->{mature}->{$id} = $obj;
         my $pid        = $atrs->{Derives_from} || $atrs->{derives_from}; # v19 uses derives_from
         die("No Derives_from attribute found for mature mir $name at line $line:\n$_") unless $pid;
         my $pobj       = $self->{hpid}->{$pid};
         die("No parent hairpin $pid found for mature mir $name") unless $pobj;

         # Tricky: must associate mature mirs with appropriate hairpin when there are duplicate hairpins.
         #         All the matures will have the same Derives_from ID, even though they really
         #         are inside the copy's locus. E.g. hsa-mir-511:
         # chr10 hairpin 17887107 17887193 + ID=MI0003127;Alias=MI0003127;Name=hsa-mir-511
         # chr10 mature  17887122 17887142 + ID=MIMAT0002808;Alias=MIMAT0002808;Name=hsa-miR-511-5p;Derives_from=MI0003127
         # chr10 mature  17887160 17887179 + ID=MIMAT0026606;Alias=MIMAT0026606;Name=hsa-miR-511-3p;Derives_from=MI0003127
         # chr10 hairpin 18134036 18134122 + ID=MI0003127_2;Alias=MI0003127;Name=hsa-mir-511
         # chr10 mature  18134051 18134071 + ID=MIMAT0002808_1;Alias=MIMAT0002808;Name=hsa-miR-511-5p;Derives_from=MI0003127
         # chr10 mature  18134089 18134108 + ID=MIMAT0026606_1;Alias=MIMAT0026606;Name=hsa-miR-511-3p;Derives_from=MI0003127
         while ($pobj->{nextCopy}) { $pobj = $pobj->{nextCopy}; $pid = $pobj->{id}; }
         $obj->{parent} = $pid;
         $obj->{pobj}   = $pobj;
         push( @{ $pobj->{children} },        $obj );

         # find 1-based offset of mature start/end into hairpin coordinates: startPos < endPos
         my ($startPos, $endPos); 
         if ($obj->{strand} eq '+') {
            $startPos = $obj->{start}  - $pobj->{start} + 1;
            $endPos   = $obj->{end}    - $pobj->{start} + 1;
         } else { # minus strand
            $startPos = $pobj->{end}   - $obj->{end}    + 1;
            $endPos   = $pobj->{end}   - $obj->{start}  + 1;
         }
         $obj->{startPos} = $startPos;
         $obj->{endPos}   = $endPos;
         
         # Determine whether this is a 5p or 3p mature miR
         # Note that some mature miRs do not have a 3p or 5p designation in v20 (e.g. hsa-miR-1), 
         #   so we will try to compute it based on where in the hairpin the mature sequence starts
         # chr18 hairpin 19408965 19409049 - ID=MI0000437;Alias=MI0000437;Name=hsa-mir-1-2
         # chr18 mature  19408976 19408997 - ID=MIMAT0000416;Alias=MIMAT0000416;Name=hsa-miR-1;Derives_from=MI0000437
         my $mtyp  = ($name =~/[-]5p$/ ? '5p' 
                      : $name =~/[-]3p$/ ? '3p' : '');
         if ($mtyp) {
            $obj->{dname}  = "$pobj->{name}($name)";
         } else {
            my $mid    = $obj->{start} + (($obj->{end} - $obj->{start} + 1)/2 );
            my $midP   = $pobj->{start} + (($pobj->{end}  - $pobj->{start} + 1)/2 );
            if ($obj->{strand} eq '+') {
               $mtyp   = $mid > $midP ? '3p' : '5p';
            } else { # minus strand
               $mtyp   = $mid > $midP ? '5p' : '3p';
            }
            $obj->{dname} = "$pobj->{name}($name($mtyp))";
         }
         # A complication is that some hairpins have more than one 5p or 3p in some species.
         # For example: mmu-mir-3102 in mouse v20.
         #   chr7 hairpin 100882306	100882409 - ID=MI0014099;Alias=MI0014099;Name=mmu-mir-3102
         #   chr7 mature  100882388	100882409 - ID=MIMAT0014933;Alias=MIMAT0014933;Name=mmu-miR-3102-5p;Derives_from=MI0014099
         #   chr7 mature  100882367	100882387 - ID=MIMAT0014934;Alias=MIMAT0014934;Name=mmu-miR-3102-5p.2-5p;Derives_from=MI0014099
         #   chr7 mature  100882330	100882350 - ID=MIMAT0014935;Alias=MIMAT0014935;Name=mmu-miR-3102-3p.2-3p;Derives_from=MI0014099
         #   chr7 mature  100882307	100882329 - ID=MIMAT0014936;Alias=MIMA`T0014936;Name=mmu-miR-3102-3p;Derives_from=MI0014099
         # Or this, in aca v21, where the two 3p sequences overlap highly and are onlys slightly offset
         #   GL343262.1 hairpin 426448	426535 - ID=MI0018804;Alias=MI0018804;Name=aca-mir-202
         #   GL343262.1 mature  426502	426522 - ID=MIMAT0021848;Alias=MIMAT0021848;Name=aca-miR-202-5p;Derives_from=MI0018804
         #   GL343262.1 mature  426467	426488 - ID=MIMAT0021849;Alias=MIMAT0021849;Name=aca-miR-202-5p.2;Derives_from=MI0018804
         #   GL343262.1	mature  426466	426485 - ID=MIMAT0021850;Alias=MIMAT0021850;Name=aca-miR-202-3p.1;Derives_from=MI0018804
         if ($pobj->{$mtyp}) { # just note presence of these for these for now... **todo** fix this
            print STDERR "** WARNING ** Second mature miRNA '$name' for hairpin '$pobj->{name}\n" unless $self->{quiet};
         }
         $obj->{p5or3}    = $mtyp;
         $pobj->{$mtyp}   = $obj if $mtyp eq '3p' or !$pobj->{$mtyp}; # first 5p/last 3p if multiple

         # Keep track of unique mature sequences, which will have the same MIMATnnnn Alias and the same Name
         # hsa-mir-7
         # chr15   hairpin 89155056  89155165 + ID=MI0000264;Alias=MI0000264;Name=hsa-mir-7-2
         # chr15   mature  89155087  89155109 + ID=MIMAT0000252;Alias=MIMAT0000252;Name=hsa-miR-7-5p;Derives_from=MI0000264
         # chr15   mature  89155127  89155148 + ID=MIMAT0004554;Alias=MIMAT0004554;Name=hsa-miR-7-2-3p;Derives_from=MI0000264
         # chr19   hairpin 4770682   4770791  + ID=MI0000265;Alias=MI0000265;Name=hsa-mir-7-3
         # chr19   mature  4770712   4770734  + ID=MIMAT0000252_1;Alias=MIMAT0000252;Name=hsa-miR-7-5p;Derives_from=MI0000265
         # chr9    hairpin 86584663  86584772 - ID=MI0000263;Alias=MI0000263;Name=hsa-mir-7-1
         # chr9    mature  86584727  86584749 - ID=MIMAT0000252_2;Alias=MIMAT0000252;Name=hsa-miR-7-5p;Derives_from=MI0000263
         # chr9    mature  86584686  86584707 - ID=MIMAT0004553;Alias=MIMAT0004553;Name=hsa-miR-7-1-3p;Derives_from=MI0000263         
         my $matseq = $self->{matseq}->{$alias};
         if (!$matseq) {
            $matseq = {};
            $matseq->{type}   = 'matseq';
            $matseq->{name}   = $name;
            $matseq->{id}     = $alias;
            $self->{matseq}->{$alias} = $matseq;
            $self->{stats}->{nMatseq}++;
         } else {
            if ( $id =~/$alias[_](\d+)/ ) { my $copyNum = $1;
            } else { die("mature miR $name copy $id ID does not have expected format '${alias}_N' at line $line:\n$_"); }
            die("2nd name found for mature miR $alias at line $line:\n$_") if $matseq->{name} ne $name;
         }
         push( @{ $matseq->{children} }, $obj );
         $obj->{matseqObj} = $matseq;
      }
   }
   close($IN);
   # Annotate mature sequence sets with number of children
   my @matseqs = $self->getObjects('matseq');
   foreach my $ms (@matseqs) {
      my $numCh = @{ $ms->{children} };
      $ms->{numCh} = $numCh;
      $ms->{dname} = "$ms->{name}\[$numCh\]";
   }
   return $self;
}
# hairpin names ending with -N (e.g. -1, -2) or belong to the same group and should be merged.
# for plants, the convention is 'MIR' + number + lowercase_letter, e.g. MIR999a MIR999b
#        named, non-group hpin:  hsa-mir-21, hsa-mir-10a, hsa-mir-517a
#            named, group hpin:  hsa-mir-17-1, hsa-let-7a-1
#  named, non-group plant hpin:  ath-MIR5656
#    unnamed, group plant hpin:  ath-MIR0243a
# group object:
#      name:  prefix where prefix is the hairpin name before -1 -2 or MIR999a (plant), etc.
#     dname:  prefix[numCh] where prefix is name and [numCh] is the count of group members
#      type:  group
#  children:  list of hairpin objects belonging to this group
#     numCh:  count of group members
sub addGroupInfo {
   my ($self) = @_;
   if (!$self->getObjects('group')) {
      my @hairpins = values(%{ $self->{hairpin} });
      my $nMulti = 0;
      foreach my $hp (@hairpins) {
         my $name  = $hp->{name};
         my $gname = $name;
         if ($name =~/(\w+[-]\w+[-]\w+)[-]\d+$/) { 
            $gname = $1;
         } elsif ($name =~/(\w+[-]MIR\d+)[a-z]+$/) { # plant convention
            $gname = $1;
         }
         my $grp = $self->{group}->{$gname};
         if (!$grp) { # create a group object for this hairpin
            $grp = {};
            $grp->{name} = $gname;
            $grp->{type} = 'group';
            $self->{group}->{$gname} = $grp;
         }
         $grp->{numCh}++;
         $nMulti++ if $grp->{numCh} == 2;
         push( @{ $grp->{children} }, $hp );
         $hp->{groupObj} = $grp;
      }
      # Add dname that includes counts
      my @grps = values(%{ $self->{group} });
      foreach (@grps) {
         $_->{dname} = "$_->{name}" . "[$_->{numCh}]"; #print "$_->{name}\n";
      } 
      $self->{stats}->{nGroup}    = @grps;
      $self->{stats}->{nMultiGrp} = $nMulti;
   }
   return $self;
}
# family object:
#        id:  family accession (unique)
#      name:  miRNA family name (unique) 
#             for hairpins with no family info, will be the hairpin name
#     dname:  family name and membership count (e.g. mir-21[1] or hsa-mir-9999[unk])
#      type:  family
#  children:  list of hairpin objects belonging to this family
#     numCh:  count of members
sub addFamilyInfo {
   my ($self) = @_;
   my $famF   = $self->{miFam};
   if (-e $famF && !$self->getObjects('family')) {
      my $IN    = openInputSafely($famF);
      my ($line, $ac, $id, $fobj, @fams) = (0);
      # mirbase miFam family data file looks like this:
      #  AC   MIPF0000001 1      (start of family; number is optional)
      #  ID   mir-17
      #  MI   MI0000071  hsa-mir-17
      #  MI   MI0000113  hsa-mir-106a
      #  MI   MI0000406  mmu-mir-106a  
      #  //                      (end of family)
      my $tmp = {};
      while (<$IN>) { $line++;
         chomp(); $_=~s/\r//;
         next if $_=~/^\/\//;
         if ($_=~/^AC\s+(\S+)$/) {              # AC line
            $ac = $1;
         } elsif ($_=~/^ID\s+(\S+)$/) {         # ID line; create a family obj
            $id = $1;
            die("Duplicate family ID (name) '$id' found line $line") if $tmp->{$id};
            $fobj  = {};
            $fobj->{name} = $id;
            $fobj->{id}   = $ac;
            $fobj->{type} = 'family';
            $tmp->{$id}   = $fobj;
         } elsif ($_=~/^MI\s+(\S+)\s+(\S+)$/) { # MI line
            my ($mirAc, $hpName) = ($1, $2);
            my $hp = $self->{hairpin}->{$hpName};
            if ($hp) { # this is a hairpin for our organism
               push( @{ $fobj->{children} }, $hp);
               $fobj->{numCh}++;
               $hp->{familyObj} = $fobj;
            }
         } else { die("Can't parse line $line of '$famF':\n'$_'"); }
      }
      close($IN);
      foreach ($self->getObjects()) { 
         if (!$_->{familyObj}) { # ensure all hairpins have a family
            my $fname = $_->{name};
            $fobj  = {};
            $fobj->{name}   = $fname;
            $fobj->{dname}  = "$fname" . "[unk]";
            $fobj->{id}     = $fname;
            $fobj->{type}   = 'family';
            $fobj->{numCh}  = 1;
            push( @{ $fobj->{children} }, $_);
            $_->{familyObj} = $fobj;
            $tmp->{$fname}  = $fobj;
         }
      }
      foreach (values(%$tmp)) { # only keep families with mirs for our organism
         if ( ref($_->{children}) eq 'ARRAY' ) {
            my $name = $_->{name};
            $self->{stats}->{nFamily}++;
            $self->{family}->{$name} = $_;
            $_->{dname} = "$name" . "[$_->{numCh}]" unless $_->{dname};
         }
      }
   }
   return $self;
}

# cluster, cluster+ and cluster- objects:
#        id:  based on chromosome and number on chromosome (unique)
#      name:  same as id
#     dname:  cluster[chr:start-end][numCh]
#      type:  cluster, cluster+ or cluster-
#  children:  list of hairpin objects belonging to this cluster
#     numCh:  count of members
our @CLUSTER_TYPES = qw( ch + - );
sub addClusterInfo {
   my ($self) = @_;
   my $dist   = $self->{clusterDist} || $CLUSTER_DISTANCE;
   foreach my $ctyp ( @CLUSTER_TYPES ) {
      my $ctyp2 = $ctyp eq 'ch' ? '' : $ctyp;
      my $typeN = "cluster$ctyp2";
      if (!$self->getObjects($typeN)) {
         foreach my $chr ($self->getChroms()) {
            my $cnum  = 0;
            my @hps   = $self->getChromHps($chr, $ctyp);
            my $hp1   = $hps[0];  next if !$hp1; $cnum++;
            my $pos   = $hp1->{start};
            my $clust = {};
            $clust->{id}    = "$typeN($chr|$cnum)";
            #$clust->{id}    = "$typeN($hp1->{id})";
            $clust->{name}  = $clust->{id};
            $clust->{chr}   = $chr;
            $clust->{start} = $hp1->{start};
            $clust->{children} = [ $hp1 ];
            $hp1->{"${typeN}Obj"} = $clust;
            $self->{$typeN}->{ $clust->{id} } = $clust;
            for (my $ix=1; $ix<@hps; $ix++) {
               my $hp2 = $hps[$ix];
               if ($hp2->{start} - $hp1->{start} + 1 <= $dist) {
                  push( @{$clust->{children}}, $hp2 ); 
                  $hp2->{$typeN} = $clust;
               } else {
                  $clust->{end}   = $hp1->{end}; $clust->{span} = $clust->{end} - $clust->{start} + 1; 
                  $clust->{numCh} = @{ $clust->{children} };
                  $clust->{dname} ="$typeN\($chr:$pos\-$hp1->{end})\[$clust->{numCh}]";
                  push( @{$self->{chrClust}->{$chr}->{$typeN}}, $clust );
                  $pos = $hp2->{start};
                  $clust = {}; $cnum++;
                  #$clust->{id}    = "$typeN($hp2->{id})";
                  $clust->{id}    = "$typeN($chr|$cnum)";
                  $clust->{name}  = $clust->{id};
                  $clust->{start} = $hp2->{start};
                  $clust->{children} = [ $hp2 ];
                  $self->{$typeN}->{ $clust->{id} } = $clust;
               }
               $hp2->{"${typeN}Obj"} = $clust;
               $hp1 = $hp2; $hp2 = undef;
            }
            $clust->{end}   = $hp1->{end}; $clust->{span} = $clust->{end} - $clust->{start} + 1;
            $clust->{numCh} = @{ $clust->{children} };
            $clust->{dname} ="$typeN\($chr:$pos\-$hp1->{end})\[$clust->{numCh}]";
            push( @{$self->{chrClust}->{$chr}->{$typeN}}, $clust );
         }
      }
   }
   return $self;
}

#==============================================================================
# Helper methods
#==============================================================================

sub getObjects {
   my ($self, $type) = @_;
   my $ref = $self->{$type || 'hpid'};
   return ref($ref) eq 'HASH' ? values(%$ref) : ();
}
sub getChroms {
   my ($self) = @_;
   my @chroms = ();
   if (ref($self->{byChrom}) eq 'HASH') {
      @chroms = sort { chromCmp($a, $b) } keys( %{$self->{byChrom}} );
   }
   return @chroms;
}
sub getChromHps {
   my ($self, $chr, $type) = @_;
   $type = 'ch' unless $type; $chr = '' unless $chr;
   my @hps = ();
   if (ref($self->{byChrom}->{$chr}) eq 'HASH' && ref($self->{byChrom}->{$chr}->{$type}) eq 'ARRAY') {
      @hps = @{ $self->{byChrom}->{$chr}->{$type} };
   }
   return @hps;
}
sub getChromClusters {
   my ($self, $chr, $type) = @_;
   $type = '' unless $type; $chr = '' unless $chr;
   my $typeN = "cluster$type";
   my @clusts = ();
   if (ref($self->{chrClust}->{$chr}) eq 'HASH' && ref($self->{chrClust}->{$chr}->{$typeN}) eq 'ARRAY') {
      @clusts = @{ $self->{chrClust}->{$chr}->{$typeN} };
   }
   return @clusts;
}

#==============================================================================
# Description support methods
#==============================================================================

our @HAIRPIN_INFO_FIELDS = qw( chrom strand start end length hpid name dname 
                               group grpct family famct cluster clct cluster+- cl+-ct
                               matseq5p matseq3p mat5pid mat3pid hpfa );
sub writeHairpinInfo {
   my ($self, $outFile) = @_;
   my $hpFa = $self->{hairpinFaRNA}->{hairpinFa}; die("Hairpin fasta info not found") unless ref($hpFa) eq 'HASH';
   $outFile = "./$self->{organism}_$self->{version}_cluster$self->{clusterDist}.hpInfo" unless $outFile;
   my $FH   = openOutputSafely($outFile);
   foreach (@HAIRPIN_INFO_FIELDS) {
      print $FH $_;
      print $FH "\t" unless $_ eq $HAIRPIN_INFO_FIELDS[-1];
   }
   print $FH "\n";
   my $tot  = 0;
   foreach my $chr ($self->getChroms()) {
      foreach my $strand (qw( + - )) {
         foreach my $hp ($self->getChromHps($chr, $strand)) { $tot++;
            my $fa  = $hpFa->{$hp->{name}} || '';
            print $FH "$chr\t$strand\t$hp->{start}\t$hp->{end}\t$hp->{length}\t$hp->{id}\t$hp->{name}\t$hp->{dname}\t";
            print $FH $hp->{groupObj}      ? $hp->{groupObj}->{dname}      : '', "\t";
            print $FH $hp->{groupObj}      ? $hp->{groupObj}->{numCh}      : 1,  "\t";
            print $FH $hp->{familyObj}     ? $hp->{familyObj}->{dname}     : '', "\t";
            print $FH $hp->{familyObj}     ? $hp->{familyObj}->{numCh}     : 1,  "\t";
            print $FH $hp->{clusterObj}    ? $hp->{clusterObj}->{dname}    : '', "\t";
            print $FH $hp->{clusterObj}    ? $hp->{clusterObj}->{numCh}    : '', "\t";
            if ($strand eq '+') {
               print $FH $hp->{'cluster+Obj'} ? $hp->{'cluster+Obj'}->{dname} : '', "\t";
               print $FH $hp->{'cluster+Obj'} ? $hp->{'cluster+Obj'}->{numCh} : '', "\t";
            } else {
               print $FH $hp->{'cluster-Obj'} ? $hp->{'cluster-Obj'}->{dname} : '', "\t";
               print $FH $hp->{'cluster-Obj'} ? $hp->{'cluster-Obj'}->{numCh} : '', "\t";
            }
            print $FH $hp->{'5p'} && $hp->{'5p'}->{matseqObj} ? $hp->{'5p'}->{matseqObj}->{dname} : '', "\t";
            print $FH $hp->{'3p'} && $hp->{'3p'}->{matseqObj} ? $hp->{'3p'}->{matseqObj}->{dname} : '', "\t";
            print $FH $hp->{'5p'} ? $hp->{'5p'}->{id} : '', "\t";
            print $FH $hp->{'3p'} ? $hp->{'3p'}->{id} : '', "\t";
            print $FH "$fa\n";
         }
      }
   }
   close($FH);
   return wantarray ? ($tot, $outFile) : $tot;
}

our @MATURE_INFO_FIELDS = qw( chrom strand start end length matlocid dname matseqid name matseq msct hpid hairpin matfa );
sub writeMatureInfo {
   my ($self, $outFile) = @_;
   my $matFa = $self->{matureFaRNA}->{matureFa}; die("Mature fasta info not found") unless ref($matFa) eq 'HASH';
   $outFile = "./$self->{organism}_$self->{version}_cluster$self->{clusterDist}.matInfo" unless $outFile;
   my $FH   = openOutputSafely($outFile);
   foreach (@MATURE_INFO_FIELDS) {
      print $FH $_;
      print $FH "\t" unless $_ eq $MATURE_INFO_FIELDS[-1];
   }
   print $FH "\n";
   my $tot  = 0;
   foreach my $chr ($self->getChroms()) {
      foreach my $strand (qw( + - )) {
         foreach my $hp ($self->getChromHps($chr, $strand)) { 
            foreach my $mat (@{ $hp->{children} }) { $tot++;
               my $ms = $mat->{matseqObj};
               die("No mature sequence info found for mature locus $mat->{dname}") unless ref($ms);
               my $fa  = $matFa->{$ms->{name}} || '';
               print $FH "$chr\t$strand\t$mat->{start}\t$mat->{end}\t$mat->{length}\t";
               print $FH "$mat->{id}\t$mat->{dname}\t";
               print $FH "$ms->{id}\t$ms->{name}\t$ms->{dname}\t$ms->{numCh}\t";
               print $FH "$hp->{id}\t$hp->{dname}\t$fa\n";
            }
         }
      }
   }
   close($FH);
   return wantarray ? ($tot, $outFile) : $tot;
}

sub toString {
   my ($self, $verbose) = @_;
   my $ind = "   ";
   my $getCt = sub { my ($ty) = @_; my $ct = $self->getObjects($ty); return $ct || 0; };
   my $str;
   $str = $str . "[miRBase $self->{version} info for $self->{organism}\n";
   $str = $str . $ind . $getCt->('hpid')     . " hairpin loci\n";
   $str = $str . $ind . $getCt->('hairpin')  . " hairpin sequences\n";
   $str = $str . $ind . $getCt->('mature')   . " mature loci\n";
   $str = $str . $ind . $getCt->('matseq')   . " mature sequences\n";
   $str = $str . $ind . $getCt->('group')    . " miRNA groups\n";
   $str = $str . $ind . $getCt->('family')   . " miRNA families\n";
   $str = $str . $ind . $getCt->('cluster')  . " miRNA clusters\n";
   $str = $str . $ind . $getCt->('cluster+') . " miRNA + strand clusters\n";
   $str = $str . $ind . $getCt->('cluster-') . " miRNA - strand clusters\n";
   $str = $str . $ind . $getCt->('byChrom')  . " chromosomes\n" if $verbose;
   if ($verbose) {
      $str = $str . $self->fmtHistInfo('matseq',   $verbose, 'children', 'dname', 4);
      $str = $str . $self->fmtHistInfo('hairpin',  $verbose, 'children', 'name',  5);
      $str = $str . $self->fmtHistInfo('group',    $verbose, 'children', 'name',  5);
      $str = $str . $self->fmtHistInfo('family',   $verbose, 'children', 'name',  5);
      $str = $str . $self->fmtHistInfo('cluster',  $verbose, 'children', 'dname', 2);
      $str = $str . $self->fmtHistInfo('cluster+', $verbose, 'children', 'dname', 2);
      $str = $str . $self->fmtHistInfo('cluster-', $verbose, 'children', 'dname', 2);
   }
   $str = $str . "]";
   return $str;
}
sub fmtHistInfo {
   my ($self, $type, $verbose, $listAttr, $itemAttr, $max) = @_;
   $type     = 'hairpin'  unless $type;
   $listAttr = 'children' unless $listAttr;
   $itemAttr = 'name'     unless $itemAttr;
   $max      = 5          unless defined($max);
   my $href = $self->{$type};
   my $str = '';
   if (values(%$href)) {
      $str = "histogram of $type $listAttr\n";
      $str = $str . "num\tcount";
      if ($verbose > 1) { 
         $str = $str . "\tspecies";
      }
      $str = "$str\n";
      # create a hash keyed by number of list items
      my $htmp = {};
      foreach (values(%$href)) {
         my @objs = @{ $_->{$listAttr} };
         my $num = @objs;
         push( @{ $htmp->{$num} }, $_ );
      }
      foreach my $num ( sort { $a <=> $b } keys(%$htmp) ) {
         my @objs = @{ $htmp->{$num} };
         my $ct = @objs;
         $str = $str . "$num\t$ct";
         if ($verbose > 1) {
            my ($n, $s, $ex, $name) = (0, '', '');
            foreach my $mir (@objs) {
               $n++; last if $n > $max;
               $name = $mir->{$itemAttr};
               if ($n == 1) { $s = "$s\t$name"; next;
               } else { $s = "$s,$name"; } 
            }
            $ex = '...' if $n > $max;
            $str = $str . $s . " $ex\n";
         } else { $str = $str . "\n"; }
      }
   }
   return $str;
}

#==============================================================================
# Fasta manipulation
#==============================================================================

sub getRefFasta {
   my ($self, $type, $rna) = @_;
   $type = 'hairpin' unless $type;
   my $typKey = "${type}Fa";
   my $org    = $self->{organism} || $DEFAULT_ORGANISM;
   my $IN     = openInputSafely( $self->{$typKey} );
   my $href   = {};
   my $arName = [];
   my $arLine = [];
   my ($num, $name, $line, $seq) = (0, '', '', '');
   while (<$IN>) {
      $_ =~s/\n$//; $_ =~s/\r$//;
      if ($_ =~/^>($org\S+)\s/) {  # start entry for our organism
         if ($name) { # finish last one
            $href->{$name} = $seq; 
            push(@$arName, $name);
            push(@$arLine, $line);
         }
         $name = $1; $line = $_; $seq = ''; $num++; 
         die("duplicate $type fa for '$name' found") if $href->{$name};
         next;
      } elsif ($_ =~/^>/) { # start entry for other organism
         if ($name) { # finish last one
            $href->{$name} = $seq; 
            push(@$arName, $name);
            push(@$arLine, $line);
         }
         $name=''; $line = ''; $seq = '';
         next;
      }
      if ($name) { 
         $_ =~s/U/T/gi unless $rna; # convert to cDNA
         $seq .= $_;
      }
   }
   if ($name) { # finish last one
      $href->{$name} = $seq; 
      push(@$arName, $name);
      push(@$arLine, $line);
   }
   close $IN; 
   my $hret = {};
   $hret->{$typKey} = $href;
   $hret->{"${type}Names"} = $arName;
   $hret->{"${type}Lines"} = $arLine;
   return wantarray ? ($hret, $num) : $hret;
}
sub makeRefFa {
   my ($self, $outFile) = @_;
   my $org = $self->{organism} || '';
   $org = '' if $org eq 'all';
   if (!$outFile) {
      if ($org) {
         $outFile = "./hairpin_cDNA_$org.fa";
      } else {
         $outFile = "./hairpin_cDNA.fa";
      }
   }
   my ($hret, $num) = $self->getRefFasta('hairpin',0);
   my $lref = $hret->{hairpinLines};
   my $nref = $hret->{hairpinNames};
   my $ix   = 0;
   my $OUT  = openOutputSafely( $outFile );
   foreach my $name ( @$nref ) {
      print $OUT "$lref->[$ix]\n"; $ix++;
      my $fa  = $hret->{hairpinFa}->{$name};
      my $len = length($fa);
      my $off = 1;
      while ($off <= $len) {
         my $str = substr($fa, $off-1, 60);
         print $OUT "$str\n";
         $off += 60;
      }
   }
   close $OUT;
   return wantarray ? ($num, $outFile) : $num;
}
sub makeRefFa_zPrev {
   my ($self, $outFile) = @_;
   my $org = $self->{organism} || '';
   $org = '' if $org eq 'all';
   if (!$outFile) {
      if ($org) {
         $outFile = "./hairpin_cDNA_$org.fa";
      } else {
         $outFile = "./hairpin_cDNA.fa";
      }
   }
   my $num = 0;
   my $ok  = $org ? 0 : 1;
   my $IN  = openInputSafely( $self->{hairpinFa} );
   my $OUT = openOutputSafely( $outFile );
   while (<$IN>) {
      if ($org) {
         if ($_ =~/^>$org/) {  # start entry for our organism
            $ok = 1; $num++;
         } elsif ($_ =~/^>/) { # start entry for other organism
            $ok=0;
         }
      } else {
         $num++ if $_ =~/^>/;
      }
      if ($ok) { 
         # convert to cDNA
         if ($_ =~/^>/) {
            print $OUT $_;
         } else { 
            $_ =~s/U/T/gi; 
            print $OUT $_;
         }
      }
   }
   close $IN; close $OUT;
   return wantarray ? ($num, $outFile) : $num;
}

1;

####################################################################

