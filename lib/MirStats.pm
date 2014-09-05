
use strict;
use File::Basename;
use MirInfo;

#####################################################################################
# MirStats object represents alignment statistics for a mirbase-aligned BAM file.
#####################################################################################

package MirStats;

#==============================================================================
# Globals, class methods
#==============================================================================

our $DEFAULT_BAM_FLAGS  = '-F 0x4';
our $MIN_MATURE_OVERLAP = 13;
our $START_END_MARGIN   =  5;    

our @MATURE_TYPES     = qw(mature matseq);
our @HP_TYPES         = qw(hairpin group family cluster cluster+ cluster-);
our @TOTAL_FIELDS     = qw(nAlign nGoodMat totBase);

our @COMMON_COUNT_FIELDS = qw(count dup oppStrand mm0 mm1 mm2 mm3p indel mq0 mq1-19 mq20-29 mq30p);
our @HP_COUNT_FIELDS     = ( @COMMON_COUNT_FIELDS, qw(5pOnly 5pPlus 3pOnly 3pPlus 5and3p totBase 5pBase 3pBase) );
our @ALL_HP_FIELDS       = ( qw(name rank), @HP_COUNT_FIELDS );
our @MATURE_COUNT_FIELDS = ( @COMMON_COUNT_FIELDS, qw(totBase) );
our @ALL_MATURE_FIELDS   = ( qw(name rank), @MATURE_COUNT_FIELDS );

our @COVERAGE_FIELDS     = qw(hairpin rank reads bases strand 5pPos1 5pPos2 3pPos1 3pPos2 length);

# From SAM spec:
# The MD field aims to achieve SNP/indel calling without looking at the reference. 
# For example, a string `10A5^AC6' means from the leftmost reference base in the alignment, 
# there are 10 matches followed by an A on the reference which is different from the aligned base;
# the next 5 reference bases are matches followed by a 2bp deletion from the reference; 
# the deleted sequence is AC; the last 6 bases are matches. 
# The MD field ought to match the CIGAR string.
# Examples:
#   MD:Z:101         - len 101, no mm or del
#   MD:Z:66T23       - len  90, mm  at 67 (ref T)
#   MD:Z:25^T13      - len  39, del at 26 (ref T)
#   MD:Z:0A100       - len 101, mm  at  1 (ref A)
#   MD:Z:0A5G4T3^C10 - len  26, mm at 1,7,12, del at 16
sub parseMD {
   my ($md) = @_;
   $md =~s/MD:Z://;
   # regex: [0-9]+(([A-Z]|\^[A-Z]+)[0-9]+)*
   my ($mmPos, $mmRef, $delPos, $delRef, $len) = (undef, undef, undef, undef, undef);
   if ($md =~/^([0-9]+)$/) { # only digits; no mismatches
      $len = $1;
   } else { # mismatches and/or deletions
      $len = 0;
      foreach my $part (split(/\^/, $md)) { # break into segments at deletion points
         if ($part =~/^([A-Z]+)/) { # deletion
            push( @$delPos, $len+1 ); push( @$delRef, $1 );
            $len += length($1); $part =~s/$1//; 
         }
         # at this point the part has mismatches only
         while ($part =~/([0-9]+)([A-Z])/g) {
            $len = $len + $1 + 1;
            push( @$mmPos, $len); push( @$mmRef, $2 );
         }
         $len += $1 if $part =~/([0-9]+)$/;
      }
   }
   return ($len, $mmPos, $delPos, $mmRef, $delRef);
}

sub parseCigar {
   my ($cigar) = @_;
   # regex: \*|([0-9]+[MIDNSHPX=])
   my $len = 0;  # length of alignment to reference
   my ($delPos, $insPos) = (undef, undef);
   while ($cigar =~/(\d+)([MDINX=])/g) { 
      push( @$delPos, $len + 1 ) if $2 eq 'D';
      push( @$insPos, $len + 1 ) if $2 eq 'I';
      $len += $1 unless $2 eq 'I';  # insertions are in query seq but not reference
   }  
   return wantarray ? ($len, $insPos, $delPos) : $len;
}

#==============================================================================
# Constructors
#==============================================================================

# expected keys: mirInfo, name, bam, bamOpts, bamLoc, minOlap, margin
sub new {
   my ($class, %args) = @_;
   my $self = {}; bless $self, $class;
   foreach my $attr ( keys(%args) ) { $self->{$attr} = $args{$attr}; }
   die("bam file '$self->{bam}' not found") unless -e $self->{bam};
   if (!$self->{name}) {
      $self->{name} = File::Basename::basename($self->{bam});
      $self->{name} =~s/[.]gz$//; $self->{name} =~s/[.][sb]am$//; 
      $self->{name} =~s/[.]dup//; $self->{name} =~s/[.]sorted//; $self->{name} =~s/[.]sort//; 
   }
   $self->{bamOpts} = $MirStats::DEFAULT_BAM_FLAGS  unless defined($self->{bamOpts});
   $self->{minOlap} = $MirStats::MIN_MATURE_OVERLAP unless defined($self->{minOlap});
   $self->{margin}  = $MirStats::START_END_MARGIN   unless defined($self->{margin});
   $self->updateTotals('hairpin');
   return $self;
}
sub newFromBam {
   my ($class, %args) = @_;
   my $self = MirStats::new($class, %args);
   die("No miRBase info found") unless $self->{mirInfo};
   $self->loadFromBam();
   $self->addMatseqCounts();
   $self->addGroupCounts();
}
sub newFromBamFull {
   my ($class, %args) = @_;
   my $self = $class->newFromBam(%args);
   $self->addFamilyCounts();
   $self->addClusterCounts();
   return $self;
}
sub newCombined {
   my ($class, %args) = @_;
   # expected keys: objs, name, mirInfo
   my $self = {}; bless $self, $class;
   foreach my $attr ( keys(%args) ) { $self->{$attr} = $args{$attr}; }
   die("Required keyword 'name' not found") unless $self->{name}; 
   $self->combineStats();
   return $self;
}

#==============================================================================
# Statistics gathering -- the real work!
#==============================================================================

# MirStats object
#       name:  descriptive name (default from bam file)
#        bam:  bam file name
#    bamOpts:  other bam options (default -F 0x4)
#     bamLoc:  bam location spec (e.g. contig name)
#    minOlap:  minimum mature overlap with alignment (default 13)
#     margin:  start/end margin for alignment (default 5)
#    mirInfo:  MirInfo object used to populate group and family stats.
#      stats:  HASH of overall statistics (TOTAL_FIELDS)
#    hairpin:  HASH of hairpin objects, each with name, count, etc.
#      group:  HASH of hairpin group objects, each w/HP_COUNT_FIELDS
#     family:  HASH of hairpin family objects, each w/HP_COUNT_FIELDS
#     mature:  HASH of mature locus objects, each w/MATURE_COUNT_FIELDS
#     matseq:  HASH of mature sequence objects, each w/MATURE_COUNT_FIELDS
sub loadFromBam {
   my ($self)  = @_;
   my $nRec    = 0;
   my $minOlap = $self->{minOlap};
   my $margin  = $self->{margin};
   my $hInfo   = $self->{mirInfo};
   die("No miRBase info found") unless $hInfo;
   #print "loadFromBam minOlap $minOlap, margin $margin\n";
   foreach (@MirStats::TOTAL_FIELDS) { $self->{stats}->{$_} = 0; }
   my $IN      = MirInfo::openInputSafely($self->{bam}, $self->{bamOpts}, $self->{bamLoc}, "$self->{bamOpts}");
   while(<$IN>) { $nRec++;
      # ID Flags contig Start MapQual Cigar MateRef MatePos InsertSz Seq Qual [ValueType Value]+
      if ( $_ =~ /^[^\t]+\t(\d+)\t(\S+)\t(\d+)\t(\d+)\t([^\t]+)\t[^\t]+\t[^\t]+\t[^\t]+\t[^\t]+\t[^\t]+\t(.*)$/ ) { 
         my ($flgs, $name, $start, $mapq, $cigar, $attrs) = ($1, $2, $3, $4, $5, $6);
         next if $flgs & 0x4;
         my $strand = '+'; $strand = '-' if $flgs & 0x10;
         $self->{stats}->{nAlign}++;
         $self->{hairpin}->{$name}->{id}   = $name;
         $self->{hairpin}->{$name}->{name} = $name;
         $self->{hairpin}->{$name}->{count}++; 
         $self->{hairpin}->{$name}->{mq0}++       if $mapq == 0; 
         $self->{hairpin}->{$name}->{'mq1-19'}++  if $mapq >=  1 && $mapq <= 19;
         $self->{hairpin}->{$name}->{'mq20-29'}++ if $mapq >= 20 && $mapq <= 29;
         $self->{hairpin}->{$name}->{mq30p}++     if $mapq >= 30; 
         $self->{hairpin}->{$name}->{dup}++       if $flgs & 0x400;
         $self->{hairpin}->{$name}->{oppStrand}++ if $strand eq '-';
         
         # mismatch and indel processing for hairpin
         my ($len, $insPos, $delPos) = parseCigar($cigar);
         die("Cannot parse CIGAR string '$cigar' for BAM entry $nRec") unless $len;
         my $end = $start + $len - 1;
         my $numIns = ref($insPos) ? @$insPos : 0;
         my $numDel = ref($delPos) ? @$delPos : 0;
         my @delpos = @$delPos if $delPos;
         my @inspos = @$insPos if $insPos;
         # for mismatches, try MD attribute (the best source) first
         my $numMm = undef; my @mmpos; 
         if ($attrs =~/MD:Z:([A-Z0-9^]+)/) {  # full regex: [0-9]+(([A-Z]|\^[A-Z]+)[0-9]+)*
            my $md = $1;   
            my ($sz, $mmPos) = parseMD($md);
            $numMm  = ref($mmPos)  ? @$mmPos  : 0;
            @mmpos  = @$mmPos if $numMm;
            unless ($self->{lenient}) {
               die("Reference alignment length $sz from attribute 'MD:Z:$md' does not match CIGAR string '$cigar' for BAM entry $nRec") unless $sz == $len;
            }
         } else {
            $numMm  = $1 if $attrs =~/XM:i:(\d+)/;  # bwa and bowtie
            if (!defined($numMm)) {
               my $nm = $1 if $attrs =~/NM:i:(\d+)/;
               $numMm = $nm - ($numIns + $numDel) if defined($nm);
            }
         }
         $self->{hairpin}->{$name}->{indel} += ($numIns + $numDel); 
         if (defined($numMm)) {
            $self->{hairpin}->{$name}->{mm0}++  if $numMm == 0; 
            $self->{hairpin}->{$name}->{mm1}++  if $numMm == 1;
            $self->{hairpin}->{$name}->{mm2}++  if $numMm == 2;
            $self->{hairpin}->{$name}->{mm3p}++ if $numMm >= 3;
         }
         # record per-base coverage of hairpin
         my $aref = \@{ $self->{hairpin}->{$name}->{coverage} };
         for (my $ix=0; $ix<$len; $ix++) { $aref->[$start + $ix]++; }
         $self->{hairpin}->{$name}->{coverage} = $aref;
         $self->{hairpin}->{$name}->{totBase} += $len;
         $self->{stats}->{totBase} += $len;

         my $gffHp = $hInfo->{hairpin}->{$name};
         if ( $gffHp ) { # some hairpin.fa names are not in the gff (e.g. hsa-mir-1273e in v20)
            $self->{hairpin}->{$name}->{hairpin} = $gffHp;
            # Mature mir locus processing
            # find alignment overlap and overhang to mature loci
            my ($mirid, $olap, $olap5, $olap3, $p5or3, $ohangL, $ohangR, $ohang5_L, $ohang5_R, $ohang3_L, $ohang3_R, $has5, $has3) =
               ('',     0,     0,      0,      '',     0,       0,       0,         0,         0,         0,         0,     0);
            foreach my $gffMat ( @{ $gffHp->{children} } ) {
               $mirid  = $gffMat->{id};
               $p5or3  = $gffMat->{p5or3};
               my $p1  = $start >= $gffMat->{startPos} ? $start : $gffMat->{startPos};
               my $p2  = $end   <= $gffMat->{endPos}   ? $end   : $gffMat->{endPos};
               $olap   = $p2 - $p1 + 1;
               $ohangL = $gffMat->{startPos} - $start;
               $ohangR = $end - $gffMat->{endPos};
               # Note: 5p/3p info won't be correct for hairpins that have multiple 5p and/or 3p mature loci.
               #       This is rare, but happens (e.g. mmu-mir-3102 in mouse)
               #       We will use the 1st 5p and last 3p encountered
               ($olap5, $ohang5_L, $ohang5_R, $has5) = ($olap, $ohangL, $ohangR, 1) if $p5or3 eq '5p' && !$has5;
               ($olap3, $ohang3_L, $ohang3_R, $has3) = ($olap, $ohangL, $ohangR, 1) if $p5or3 eq '3p';
               #print "$name\t$mirid\t$gffMat->{p5or3}\t$start\t$end\t$olap\t$ohangL\t$ohangR\n";
               # record information about alignments to each mature loci
               if ($olap > $minOlap && $ohangL <= $margin && $ohangR <= $margin) {
                  $self->{stats}->{nGoodMat}++;
                  $self->{mature}->{$mirid}->{mature} = $gffMat;
                  $self->{mature}->{$mirid}->{id}     = $mirid;
                  $self->{mature}->{$mirid}->{name}   = $gffMat->{name};
                  $self->{mature}->{$mirid}->{alias}  = $gffMat->{alias};
                  $self->{mature}->{$mirid}->{dname}  = $gffMat->{dname};
                  $self->{mature}->{$mirid}->{count}++; 
                  $self->{mature}->{$mirid}->{mq0}++       if $mapq == 0; 
                  $self->{mature}->{$mirid}->{'mq1-19'}++  if $mapq >=  1 && $mapq <= 19;
                  $self->{mature}->{$mirid}->{'mq20-29'}++ if $mapq >= 20 && $mapq <= 29;
                  $self->{mature}->{$mirid}->{mq30p}++     if $mapq >= 30; 
                  $self->{mature}->{$mirid}->{dup}++       if $flgs & 0x400;
                  $self->{mature}->{$mirid}->{oppStrand}++ if $strand eq '-';
                  $self->{mature}->{$mirid}->{totBase} += $olap;

                  # mismatch processing for mature locus
                  if (@mmpos > 0) {
                     my @hpMmPos; # find mm position(s) relative to hairpin
                     foreach (@mmpos) { my $p=$_+$start-1; push(@hpMmPos,  $p) if $p >= $gffMat->{startPos} && $p <= $gffMat->{endPos}; }
                     #print "mm in $mirid\t$start\t$gffMat->{startPos}\t$end\t$gffMat->{endPos}\t(@mmpos)\t(@hpMmPos)\n" if @mmpos;
                     my $nMatMm = @hpMmPos;
                     $self->{mature}->{$mirid}->{mm0}++  if $nMatMm == 0; 
                     $self->{mature}->{$mirid}->{mm1}++  if $nMatMm == 1;
                     $self->{mature}->{$mirid}->{mm2}++  if $nMatMm == 2;
                     $self->{mature}->{$mirid}->{mm3p}++ if $nMatMm >= 3;
                     # record per-position mismatch count (not used right now)
                     if ($nMatMm) {
                        $aref = \@{ $self->{mature}->{$mirid}->{mmhist} };
                        foreach (@hpMmPos) { $aref->[$_ - $gffMat->{startPos} + 1]++; } # adjust pos in hp to pos in mature
                        $self->{mature}->{$mirid}->{mmhist} = $aref;
                     }
                  } else {
                     $self->{mature}->{$mirid}->{mm0}++;
                  }
                  # indel processing for mature locus
                  if (@inspos > 0 || @inspos > 0) {
                     my @hpInsPos; my @hpDelPos; 
                     foreach (@inspos) { my $p=$_+$start-1; push(@hpInsPos, $p) if $p >= $gffMat->{startPos} && $p <= $gffMat->{endPos}; }
                     foreach (@delpos) { my $p=$_+$start-1; push(@hpDelPos, $p) if $p >= $gffMat->{startPos} && $p <= $gffMat->{endPos}; }
                     my $ni = @hpInsPos || 0;
                     my $nd = @hpDelPos || 0;
                     $self->{mature}->{$mirid}->{indel} += ($ni + $nd); 
                     # record per-position indel counts (not used right now)
                     if ($ni) {
                        $aref = \@{ $self->{mature}->{$mirid}->{inshist} };
                        foreach (@hpInsPos) { $aref->[$_ - $gffMat->{startPos} + 1]++; } 
                        $self->{mature}->{$mirid}->{inshist} = $aref;
                     }
                     if ($nd) {
                        $aref = \@{ $self->{mature}->{$mirid}->{delhist} };
                        foreach (@hpDelPos) { $aref->[$_ - $gffMat->{startPos} + 1]++; } 
                        $self->{mature}->{$mirid}->{delhist} = $aref;
                     }
                  }
               }
            }
            # keep track of total alignments (with any overlap) for each mature sequence
            #   5pOnly / 3pOnly = read, start to end, falls within appropriate distance of mature locus
            #   5pPlus / 3pPlus = read overlaps the target mature enough, but not the other mature seq enough
            #   p5and3 = read overlaps two distinct features enough (e.g. hairpin precursor)
            my ($mat5, $mat3) = (0, 0);
            #print "$name\t$has5\t$has3\t$start\t$end\t$olap5\t$ohang5_L\t$ohang5_R\t$olap3\t$ohang3_L\t$ohang3_R\n";
            if ($has5) {
               $self->{hairpin}->{$name}->{"5pBase"} += $olap5 if $olap5 > 0;
               if ($olap5 >= $minOlap && $ohang5_L <= $margin && $ohang5_R <= $margin) {
                  $self->{hairpin}->{$name}->{"5pOnly"}++ ;
               } elsif ($olap5 >= $minOlap && $olap3 < $minOlap) {
                  $self->{hairpin}->{$name}->{"5pPlus"}++ ;
               } elsif ($olap5 >= $minOlap) {
                  $mat5 = 1;
               }
            }
            if ($has3) {
               $self->{hairpin}->{$name}->{"3pBase"} += $olap3 if $olap3 > 0;
               if ($olap3 >= $minOlap && $ohang3_L <= $margin and $ohang3_R <= $margin) {
                  $self->{hairpin}->{$name}->{"3pOnly"}++ ;
               } elsif ($olap3 >= $minOlap && $olap5 < $minOlap) {
                  $self->{hairpin}->{$name}->{"3pPlus"}++ ;
               } elsif ($olap3 >= $minOlap){
                  $mat3 = 1;
               }
            }
            if ($mat5 && $mat3) { # both ends overlapped
               $self->{hairpin}->{$name}->{p5and3}++;
            }
         } else { # no GFF entry, just mark display name
            $self->{hairpin}->{$name}->{dname} = "$name(unk)";
            print STDERR "** WARNING ** Can't find GFF info for hairpin '$name'\n" if $self->{verbose};
         }
      } elsif ($_ =~/^@/ ) { next; # header record of sam file
      } else { die("Failed to parse entry $nRec of '$self->{bam}':\n$_"); }
   }
   close($IN);
   $self->updateTotals('hairpin');
   $self->updateTotals('mature');
   return $self;
}
sub addMatseqCounts {
   my ($self) = @_;
   my $hInfo = $self->{mirInfo}; 
   if (ref($hInfo) eq 'MirInfo') {
      foreach my $obj ( $self->getObjects('mature') ) {
         my $msName     = $obj->{alias}; 
         my $gffMseq    = $hInfo->{matseq}->{$msName};
         die("Can't find Gff matseq info for mature locus '$msName' ($obj->{dname})") unless $gffMseq;
         $self->{matseq}->{$msName}->{id}     = $msName;
         $self->{matseq}->{$msName}->{name}   = $gffMseq->{name};
         $self->{matseq}->{$msName}->{dname}  = $gffMseq->{dname};
         $self->{matseq}->{$msName}->{matseq} = $gffMseq;
         foreach (@MATURE_COUNT_FIELDS) {
            $self->{matseq}->{$msName}->{$_} += $obj->{$_};
         }
      }
      $self->updateTotals('matseq');
   }
   return $self;
}
sub addGroupCounts {
   my ($self) = @_;
   my $hInfo = $self->{mirInfo}; 
   if (ref($hInfo) eq 'MirInfo') {
      foreach my $obj ( $self->getObjects('hairpin') ) {
         my $hpName    = $obj->{name};
         my $gffHp     = $hInfo->{hairpin}->{$hpName}; 
         if (!$gffHp) {
            print STDERR "** WARNING ** Can't find Gff hairpin info for '$hpName'\n" if $self->{verbose};
         }
         my $grpName   = $hpName;
         my $dname; 
         my $gffGrpObj = $gffHp->{groupObj}; 
         if ($gffGrpObj) {
            $grpName   = $gffGrpObj->{name}; 
            $dname     = $gffGrpObj->{dname};
         } else {
            print STDERR "** WARNING ** Can't find GFF group info for hairpin '$hpName'\n" if $self->{verbose};
            $dname     = "$grpName" . "[unk]";
         }
         $self->{group}->{$grpName}->{id}     = $grpName;
         $self->{group}->{$grpName}->{name}   = $grpName;
         $self->{group}->{$grpName}->{dname}  = $dname;
         $self->{group}->{$grpName}->{group}  = $gffHp;
         foreach (@HP_COUNT_FIELDS) {
            $self->{group}->{$grpName}->{$_} += $obj->{$_};
         }
      }
      $self->updateTotals('group');
   }
   return $self;
}
sub addFamilyCounts {
   my ($self) = @_;
   my $hInfo = $self->{mirInfo};
   if (ref($hInfo) eq 'MirInfo') {
      foreach my $obj ( $self->getObjects('hairpin') ) {
         my $hpName    = $obj->{name};
         my $gffHp     = $hInfo->{hairpin}->{$hpName};
         my ($famName, $dname);
         my $gffFamObj = $gffHp->{familyObj};
         if ($gffFamObj) {
            $famName   = $gffFamObj->{name};
            $dname     = $gffFamObj->{dname};
         } else {
            print STDERR "** WARNING ** Can't find GFF family info for hairpin '$hpName'\n" if $self->{verbose};
            $famName   = $hpName; 
            $dname     = "$famName" . "[unk]";
         }
         $self->{family}->{$famName}->{id}     = $famName;
         $self->{family}->{$famName}->{name}   = $famName;
         $self->{family}->{$famName}->{dname}  = $dname;
         $self->{family}->{$famName}->{family} = $gffFamObj;
         foreach (@HP_COUNT_FIELDS) {
            $self->{family}->{$famName}->{$_} += $obj->{$_};
         }
      }
      $self->updateTotals('family');
   }
   return $self;
}
sub addClusterCounts {
   my ($self) = @_;
   my $hInfo = $self->{mirInfo};
   if (ref($hInfo) eq 'MirInfo') {
      foreach my $ctyp (('', '+', '-')) {
         my $typeN = "cluster$ctyp"; 
         foreach my $obj ( $self->getObjects('hairpin') ) {  
            my $hpName   = $obj->{name};  #print "$hpName $typeN\n";
            my $gffHp    = $hInfo->{hairpin}->{$hpName};
            if (!$gffHp) {
               print STDERR "** WARNING ** Can't find Gff hairpin info for '$hpName'\n" if $self->{verbose};
               next;
            }
            my ($clName, $dname);
            my $gffObj = $gffHp->{"${typeN}Obj"};
            if ($gffObj) {
               $clName   = $gffObj->{name};
               $dname    = $gffObj->{dname};
               $self->{$typeN}->{$clName}->{name}   = $clName;
               $self->{$typeN}->{$clName}->{dname}  = $dname;
               $self->{$typeN}->{$clName}->{$typeN} = $gffObj;
               foreach (@HP_COUNT_FIELDS) {
                  $self->{$typeN}->{$clName}->{$_} += $obj->{$_};
               }
            }
         }
         $self->updateTotals($typeN);
      }
   }
   return $self;
}

#==============================================================================
# Misc helpers
#==============================================================================

sub getObjects {
   my ($self, $type) = @_;
   my $ref = $self->{$type || 'hairpin'};
   return ref($ref) eq 'HASH' ? values(%$ref) : ();
}
sub updateTotals {
   my ($self, $type) = @_;
   $type = 'hairpin' if !$type;
   my $rank = 0;
   my @objs = $self->getObjects($type);
   if ($type eq 'mature' || $type eq 'matseq') {
      foreach (@MATURE_COUNT_FIELDS) { $self->{stats}->{$type}->{$_} = 0; }
      foreach my $obj (@objs) { # ensure 0s if undef fields
         foreach (@MATURE_COUNT_FIELDS) { $obj->{$_} = 0 unless $obj->{$_} }
      }
      @objs = sort { $b->{count} <=> $a->{count} } @objs if @objs;
      foreach my $obj (@objs) { 
         $rank++; $obj->{rank} = $rank;
         foreach (@MATURE_COUNT_FIELDS) { 
            $self->{stats}->{$type}->{$_} += $obj->{$_};
         }
      }
   } else {
      foreach (@HP_COUNT_FIELDS) { $self->{stats}->{$type}->{$_} = 0; }
      foreach my $obj (@objs) { # ensure 0s if undef fields
         foreach (@HP_COUNT_FIELDS) { $obj->{$_} = 0 unless $obj->{$_} }
      }
      @objs = sort { $b->{count} <=> $a->{count} } @objs if @objs;
      foreach my $obj (@objs) {
         $rank++; $obj->{rank} = $rank;
         foreach (@HP_COUNT_FIELDS) { 
            $self->{stats}->{$type}->{$_} += $obj->{$_};
         }
      }
   }
   return $rank;
}

sub combineStats {
   my ($self) = @_;
   my $refStats = $self->{objects};
   die("Required keyword 'objects' not found") unless $refStats; 
   die("objects value is '$refStats', not an array reference") unless ref($refStats) eq 'ARRAY';
   
   # combine total fields
   foreach (@MirStats::TOTAL_FIELDS) { $self->{stats}->{$_} = 0; }
   foreach my $href (@$refStats) {
      foreach (@MirStats::TOTAL_FIELDS) {
         $self->{stats}->{$_} += ($href->{stats}->{$_} || 0);
      }
   }
   # combine count fields for each type
   foreach my $type ( @MirStats::HP_TYPES ) {
      foreach (@MirStats::HP_COUNT_FIELDS)    { $self->{stats}->{$type}->{$_} = 0; }
      foreach my $href (@$refStats) {
         foreach my $obj ($href->getObjects($type)) {
            foreach (@MirStats::HP_COUNT_FIELDS) { 
               $self->{stats}->{$type}->{$_} += ($obj->{$_} || 0);
            }
         }
         foreach my $obj ($href->getObjects($type)) {
            my $name   = $obj->{name};
            my $totObj = $self->{$type}->{$name};
            if (!$totObj) {
               $totObj = {}; 
               $totObj->{id}    = $name;
               $totObj->{name}  = $name;
               $totObj->{dname} = $obj->{dname};
               $totObj->{$type} = $obj->{$type};  # MirInfo object
               $self->{$type}->{$name} = $totObj;
            }
            foreach (@MirStats::HP_COUNT_FIELDS) { 
               $totObj->{$_} += ($obj->{$_} || 0);
            }
         }
         $self->updateTotals($type);
      }
   }
   # combine mature fields
   foreach my $type ( @MirStats::MATURE_TYPES ) {
      foreach (@MirStats::MATURE_COUNT_FIELDS)    { $self->{stats}->{$type}->{$_} = 0; }
      foreach my $href (@$refStats) {
         foreach my $obj ($href->getObjects($type)) {
            foreach (@MirStats::MATURE_COUNT_FIELDS) { 
               $self->{stats}->{$type}->{$_} += ($obj->{$_} || 0);
            }
         }
         foreach my $obj ($href->getObjects($type)) {
            my $id     = $obj->{id};
            my $totObj = $self->{$type}->{$id};
            if (!$totObj) {
               $totObj = {}; 
               $totObj->{id}    = $id;
               $totObj->{name}  = $obj->{name};
               $totObj->{dname} = $obj->{dname};
               $totObj->{$type} = $obj->{$type};  # MirInfo object
               $self->{$type}->{$id} = $totObj;
            }
            foreach (@MirStats::MATURE_COUNT_FIELDS) { 
               $totObj->{$_} += ($obj->{$_} || 0);
            }
         }
         $self->updateTotals($type);
      }
   }
   # combine hairpin coverage data
   foreach my $href (@$refStats) {
      foreach my $hp ($href->getObjects('hairpin')) {
         my ($name, $aref) = ($hp->{name}, $hp->{coverage});
         if (ref($aref) eq 'ARRAY') { # has coverage data
            my $refCov = $self->{hairpin}->{$name}->{coverage} || [];
            for (my $ix=1; $ix<=@$aref; $ix++) { 
               $refCov->[$ix] = ($aref->[$ix]  ? ($refCov->[$ix] || 0) + $aref->[$ix] : undef);
            }
            $self->{hairpin}->{$name}->{coverage} = $refCov;
         }
      }
   }
}

#==============================================================================
# Output methods
#==============================================================================

sub writeHpStats { writeStats(@_); }
sub writeStats {
   my ($self, $type, $outF, $hdr) = @_;
   $type     = 'hairpin' if !$type;
   $outF     = "./$self->{name}.$type.hist" if !$outF;
   $hdr      = 1 if !defined($hdr);
   my $stats = $self->{stats}->{$type};
   my @objs  = $self->getObjects($type);
   my $nObj  = @objs;
   my $ct    = 0;
   if (@objs) {
      my $tot   = $stats->{count}; 
      die("No count total for stats $type, but $nObj found") unless $tot;
      @objs     = sort { $a->{rank} <=> $b->{rank} } @objs if @objs;
      my $OUT   = MirInfo::openOutputSafely($outF);
      if ($hdr) {
         print $OUT "name\trank";
         foreach (@MirStats::HP_COUNT_FIELDS) { print $OUT "\t$_"; }
         print $OUT "\n";
      }
      foreach my $obj (@objs) { $ct++;
         my $name = $obj->{dname} || $obj->{name};
         print $OUT "$name\t$obj->{rank}";
         foreach (@MirStats::HP_COUNT_FIELDS) { print $OUT "\t$obj->{$_}"; }
         print $OUT "\n";
      }
      close($OUT);
   }
   return wantarray ? ($ct, $outF) : $ct;
}

sub writeMatseq {
   my ($self, $type, $outF, $hdr) = @_;
   return $self->writeMature('matseq', $outF, $hdr);
}
sub writeMature {
   my ($self, $type, $outF, $hdr) = @_;
   $type     = 'mature' if !$type;
   $outF     = "./$self->{name}.$type.hist" if !$outF;
   $hdr      = 1 if !defined($hdr);
   my $stats = $self->{stats}->{$type};
   my @objs  = $self->getObjects($type);
   my $nObj  = @objs;
   my $ct    = 0;
   if (@objs) {
      my $tot   = $stats->{count}; 
      die("No count total for stats $type, but $nObj found") unless $tot;
      @objs     = sort { $a->{rank} <=> $b->{rank} } @objs if @objs;
      my $OUT   = MirInfo::openOutputSafely($outF);
      if ($hdr) {
         print $OUT "name\trank";
         foreach (@MirStats::MATURE_COUNT_FIELDS) { print $OUT "\t$_"; }
         print $OUT "\n";
      }
      foreach my $obj (@objs) { $ct++;
         my $name = $obj->{dname} || $obj->{name};
         print $OUT "$name\t$obj->{rank}";
         foreach (@MirStats::MATURE_COUNT_FIELDS) { print $OUT "\t$obj->{$_}"; }
         print $OUT "\n";
      }
      close($OUT);
   }
   return wantarray ? ($ct, $outF) : $ct;
}

sub writeCoverage {
   my ($self, $outF, $hdr) = @_;
   $outF     = "./$self->{name}.coverage" if !$outF;
   $hdr      = 1 if !defined($hdr);
   my $stats = $self->{stats}->{hairpin};
   my @hps   = $self->getObjects('hairpin');
   my ($tot, $numOk, $maxLen, $hInfo) = (0, 0, 0, $self->{mirInfo});
   if (@hps && $hInfo) {
      my $tot = $stats->{count}; 
      die("No count total for hairpin, but " . scalar(@hps) . " found") unless $tot;
      @hps = sort { $a->{rank} <=> $b->{rank} } @hps;
      foreach my $hp (@hps) { # find maximum coverage length
         my $aref = $hp->{coverage};
         if (ref($aref) eq 'ARRAY') { # has coverage info
            $maxLen = @$aref if @$aref > $maxLen;
         }
      }
      if ($maxLen > 0) {
         my $OUT    = MirInfo::openOutputSafely($outF);
         if ($hdr) { # @COVERAGE_FIELDS
            print $OUT "hairpin\trank\treads\tbases\tstrand\t5pPos1\t5pPos2\t3pPos1\t3pPos2\tlength";
            for (my $ix=1; $ix<=$maxLen; $ix++) { print $OUT "\t$ix"; }
            print $OUT "\n";
         }
         foreach my $hp (@hps) { $tot++;
            my ($name, $aref) = ( $hp->{name}, $hp->{coverage} ); 
            my $inf = $hInfo->{hairpin}->{$name};  #print STDERR "no inf: $name\n" unless $inf;
            if (ref($aref) eq 'ARRAY') { $numOk++; # has coverage info
               my ($p5, $p3, $len, $strand, $p5s, $p5e, $p3s, $p3e) = ('', '', '', '', '', '', '', '');
               if ($inf) {
                  ($p5, $p3, $len, $strand) = ( $inf->{'5p'}, $inf->{'3p'}, ($inf->{end} - $inf->{start} + 1), $inf->{strand} );
               }
               if (ref($p5)) { 
                  $p5s = $p5->{startPos}; 
                  $p5e = $p5->{endPos};
               }
               if (ref($p3)) { 
                  $p3s = $p3->{startPos}; 
                  $p3e = $p3->{endPos};
               }
               print $OUT "$name\t$hp->{rank}\t$hp->{count}\t$hp->{totBase}\t$strand\t$p5s\t$p5e\t$p3s\t$p3e\t$len";
               for (my $ix=1; $ix<=$maxLen; $ix++) { print $OUT "\t", ($aref->[$ix] || ''); }
               print $OUT "\n";
            }
         }
         close($OUT);
      }
   }
   return wantarray ? ($numOk, $outF) : $numOk;
}

sub writeFilteredAlns {
   my ($self, $outType, $outF1, $outF2)  = @_;
   my $minOlap = $self->{minOlap};
   my $margin  = $self->{margin};
   my $hInfo   = $self->{mirInfo};
   $outType    = 'sam' unless $outType;
   $outF1      = "./$self->{name}.goodFit.$outType" unless $outF1;
   $outF2      = "./$self->{name}.other.$outType"   unless $outF2;
   die("No miRBase info found") unless $hInfo;
   #print "loadFromBam minOlap $minOlap, margin $margin\n";
   foreach (@MirStats::TOTAL_FIELDS) { $self->{stats}->{$_} = 0; }

   # write header
   my $OUT1 = MirInfo::openOutputSafely( $outF1 );
   my $OUT2 = MirInfo::openOutputSafely( $outF2 );
   my $IN   = MirInfo::openInputSafely($self->{bam}, "-H", $self->{bamLoc}, "$self->{bamOpts}");
   while(<$IN>) { print $OUT1 $_; print $OUT2 $_; } close($IN);
   
   # process alignments
   my $rec;
   my $nRec = 0;
   $IN      = MirInfo::openInputSafely($self->{bam}, $self->{bamOpts}, $self->{bamLoc}, "$self->{bamOpts}");
   while ( $rec = <$IN> ) { 
      # ID Flags contig Start MapQual Cigar MateRef MatePos InsertSz Seq Qual [ValueType Value]+
      if ( $rec =~ /^[^\t]+\t(\d+)\t(\S+)\t(\d+)\t(\d+)\t([^\t]+)\t[^\t]+\t[^\t]+\t[^\t]+\t[^\t]+\t[^\t]+\t(.*)$/ ) { 
         my ($flgs, $name, $start, $mapq, $cigar, $attrs) = ($1, $2, $3, $4, $5, $6);
         $self->{stats}->{nAlign}++; $nRec++;
         my $len   = parseCigar($cigar);
         die("Cannot parse CIGAR string '$cigar' for BAM entry $nRec") unless $len;
         my $end   = $start + $len - 1;
         my $gffHp = $hInfo->{hairpin}->{$name};
         if ( $gffHp ) { # some hairpin.fa names are not in the gff (e.g. hsa-mir-1273e in v20)
            $self->{hairpin}->{$name}->{hairpin} = $gffHp;
            # Mature mir locus processing
            # find alignment overlap and overhang to mature loci
            my ($mirid, $olap, $ohangL, $ohangR, $wrote) = ('', 0, 0, 0, 0);
            foreach my $gffMat ( @{ $gffHp->{children} } ) {
               $mirid  = $gffMat->{id};
               my $p1  = $start >= $gffMat->{startPos} ? $start : $gffMat->{startPos};
               my $p2  = $end   <= $gffMat->{endPos}   ? $end   : $gffMat->{endPos};
               $olap   = $p2 - $p1 + 1;
               $ohangL = $gffMat->{startPos} - $start;
               $ohangR = $end - $gffMat->{endPos};
               #print "$name\t$mirid\t$gffMat->{p5or3}\t$start\t$end\t$olap\t$ohangL\t$ohangR\n";
               # write this alignment (once) if it matches the "good fit" criteria
               if ($olap > $minOlap && $ohangL <= $margin && $ohangR <= $margin) {
                  print $OUT1 $rec; 
                  $self->{stats}->{nGoodMat}++;
                  $wrote = 1; last;
               }
            }
            print $OUT2 $rec if !$wrote;
         } else { # no GFF entry
            print STDERR "** WARNING ** Can't find GFF info for hairpin '$name'\n" if $self->{verbose};
         }
      } else { die("Failed to parse entry $nRec:\n$rec"); }
   }
   close($IN); close($OUT1); close($OUT2);
   return wantarray ? ($nRec, $self->{stats}->{nGoodMat},           $outF1, 
                              ($nRec - $self->{stats}->{nGoodMat}), $outF2) : $nRec;
}


1;

####################################################################

