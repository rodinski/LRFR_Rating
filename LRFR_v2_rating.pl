use warnings;
use strict;
use feature 'say';
use Data::Dumper;
sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

if (!$ARGV[0]) { say " Usage  program.pl  <glob.rpt>"; exit }
my $glob_mask = $ARGV[0];
my @files = glob $glob_mask;

#say join "\n", @files;


our %truck;
our $fh;
our $fn;

foreach $fn ( @files ) {
#    say " ===============  $fn    ===============";
#    <>;
    open( $fh, '<', $fn) or die "Could not open $fn $!";
    while (my $line = <$fh> ) {   #perl should close these as the next on is defined. 
        chomp $line;
        if ( $line =~ /R A T I N G   F A C T O R S / ) { &rf ; }
        #if ( $line =~ / MULTIPLIERS --/              ) { &get_LL_phi }
    }
    close ($fh);
}
#say Dumper \%truck;
foreach my $t(  "AASHTO 1", "AASHTO 2", "AASHTO 3", "NRL", 
                "EV2", "EV3", "OL-1", "OL-2", 
                "SU4", "SU5", "SU6", "SU7",
                "Inventory (HL-93)", "Operating (HL-93)"  ) {
    my $gamma = 1.45;  #typical for AASHTO's and NRL
    if ( $t =~ /^EV/ )     { $gamma = 1.30 }
    if ( $t =~ /^OL/ )     { $gamma = 1.20 }
    if ( $t =~ /^Invent/ ) { $gamma = 1.75 }
    if ( $t =~ /^Operat/ ) { $gamma = 1.35 }
    
    if (exists $truck{$t}{minRate} ) { 
            printf "%s\t%.2f\t%.2f\t%s - Span %d @ %.2f ft. - %s\n", 
                      $t, 
                      $truck{$t}{minRate}, 
                      $gamma, 
                      $truck{$t}{typeTitle}, 
                      $truck{$t}{minSpan}, 
                      $truck{$t}{minDist},
                      $truck{$t}{minType}
                      ;

            if ($t eq "OL-2" ) { say ""; }
        }
}
say "\n\nFiles considered:";
print join "\n", @files, "\n\n";



# ===========================================================

sub  rf {
    my $line;
    foreach ( 1 .. 5 )  {  $line = <$fh>;  }
    while (my $line = <$fh> ) {
        chomp $line;
        if ( $line =~ /F A C T O R S  .Continued.  / ) { foreach( 1 .. 7 ) { $line = <$fh> } }
        my @fix = unpack('a7 a16 a7 a6 a5 a10 a6 a5 a10 a6 a5 a9', $line) ;
        if ($fix[1] =~ /^ *$/ || $fix[1] =~ /Design Truck:/ ) {next }
        $fix[1] = trim $fix[1];

        my $summary_name = trim $fix[1];
        #  longitudinal and crossbeam runs use different names for the same loading
        if ( $fix[1] =~ /TYPE_3$/  ) { $summary_name = 'AASHTO 1'; }
        if ( $fix[1] =~ /TYPE_3S2$/) { $summary_name = 'AASHTO 2'; }
        if ( $fix[1] =~ /TYPE_3-3$/) { $summary_name = 'AASHTO 3'; }
        if ( $fix[1] =~ 'OL 1' || $fix[1] =~ 'OVERLOAD_1')     { $summary_name = 'OL-1'; } 
        if ( $fix[1] =~ 'OL 2' || $fix[1] =~ 'OVERLOAD_2')     { $summary_name = 'OL-2'; }
        if ( $fix[1] =~ 'EV2' )     { $summary_name = 'EV2'; }   #crossbeam runs have extra text
        if ( $fix[1] =~ 'EV3' )     { $summary_name = 'EV3'; }   #crossbeam runs have extra text
        if ( $fix[1] =~ 'HL' && $fix[2] =~ 'INV')     { $summary_name = 'Inventory (HL-93)'; }
        if ( $fix[1] =~ 'HL' && $fix[2] =~ 'OPER')     { $summary_name = 'Operating (HL-93)'; }
        if ( $fix[1] =~ /SU4/) { $summary_name = 'SU4'; }
        if ( $fix[1] =~ /SU5/) { $summary_name = 'SU5'; }
        if ( $fix[1] =~ /SU6/) { $summary_name = 'SU6'; }
        if ( $fix[1] =~ /SU7/) { $summary_name = 'SU7'; }
#        printf "s_name  %20s <-- %-20s\n",  $summary_name, trim $fix[1];
#        printf  trim $line;
#        printf "  %s\n", $summary_name;
        my $tref = \% {$truck{$summary_name} }; 
        if( !exists $tref->{'minRate'} ) {$tref->{'minRate'} =  &trim($fix[3]) }
        $tref->{$fn}{'Mom'}     = &trim($fix[3]);
        $tref->{$fn}{'Mom_Span'}= &trim($fix[4]);
        $tref->{$fn}{'Mom_Dist'}= &trim($fix[5]);


        $tref->{$fn}{'Ser'}     = &trim($fix[6]);
        $tref->{$fn}{'Ser_Span'}= &trim($fix[7]);
        $tref->{$fn}{'Ser_Dist'}= &trim($fix[8]);


        $tref->{$fn}{'Shr'}     = &trim($fix[9]);
        $tref->{$fn}{'Shr_Span'}= &trim($fix[10]);
        $tref->{$fn}{'Shr_Dist'}= &trim($fix[11]);

        foreach my $i ( 3,  9) {    #loop for both Mom and Shr 
            no warnings;
            if  (  $fix[$i] == "-NC-" )  {next }
            use warnings;
            my $tmprate = &trim($fix[$i]) ;
            if ($tmprate <= $tref->{'minRate'}) {    #set everything needed for a minRate
                $tref->{'minRate'} =  &trim($fix[$i]) ;
                $tref->{'minSpan'} =  &trim($fix[$i+1])  ;
                $tref->{'minDist'} =  &trim($fix[$i+2])  ;
                if ( $i == 3 ) {$tref->{'minType'} = "Moment" }
                if ( $i == 6 ) {$tref->{'minType'} = "Service" }
                if ( $i == 9 ) {$tref->{'minType'} = "Shear" }
                $tref->{'minFile'} =  $fn;
                my $typeTitle = " ??? ";
                if ( $fn =~ /_Ext/i  || $fn =~ /^Ent/i  ) {$tref->{'typeTitle'}= "Exterior" }
                if ( $fn =~ /_Int/i  || $fn =~ /^Int/i  ) {$tref->{'typeTitle'}= "Interior" }
                if ( $fn =~ /cross/i || $fn =~ /xbeam/i ) {$tref->{'typeTitle'}= "Crossbeam" }
            }
        }
        if  ( $fix[1] =~ /HL-?93/ && $fix[2] =~ /OPER/ ) { return; }  #stop this section
    }
}
# ===========================================================
sub  get_LL_phi {
    my $line;
    foreach ( 1 .. 5 )  {  $line = <$fh>;  }
    while (my $line = <$fh> ) {
        chomp $line;
        say $line;
#        my @fix = unpack('a7 a16 a7 a6 a5 a10 a6 a5 a10 a6 a5 a9', $line) ;
        if ($line =~ /^$/)  { return; }
    }
}
# ===========================================================

__DATA__















                   ############################################
                   #                                          #
                   #     B R I D G E     R A T I N G          #
                   #               Dec 2018                   #
                   #                                          #
                   #  Bridge No. : 82-20N Interior Girder     #
                   #  Bridge Name:                            #
                   #     I-82 @ Borland Road Exit 11          #
                   #                                          #
                   #                                          #
                   #                                          #
                   ############################################






























 
 
                 ============================================
                 B R I D G E    R A T I N G     S U M M A R Y
                   ***     Per  LRFR Specifications     ***
                 ============================================
 
 
       Bridge Number..: 82-20N Interior Girder
       Bridge Name....: I-82 @ Borland Road Exit 11
       Location.......:
       Date Built.....: 1969
       Rated By.......: Burns and McDonnel
       ADTV...........:
       BRIDG Revision..: 10.9 Jun 21 2018
 
       GENERAL NOTES:
       ==============
       3 Span PCB, three spans continuous for live load
       Design Live Load HS20
       1.5  in. modified concrete overlay
 
       SPAN/MEMBER INFORMATION (Continued):
       ====================================
 
                         ----------LRFR Resistance Factors ----------------
                         CONVENTIONAL   --PRESTRESSED---   --POST-TENSION--
       Mbr  Span Length  REINFORCED     Pos   Neg          Pos   Neg
                         MOM   SHR      MOM   MOM   SHR    MOM   MOM   SHR
       ===  ==== ======  ====  ====     ====  ====  ====   ====  ====  ====
         1     1  46.50  0.90  0.90     1.00  0.90  0.90   0.95  0.90  0.90
         2     2  50.00  0.90  0.90     1.00  0.90  0.90   0.95  0.90  0.90
         3     3  41.50  0.90  0.90     1.00  0.90  0.90   0.95  0.90  0.90
                 ======
                 138.00
 
       **** R A T I N G   F A C T O R S  ****
       ======================================
 
       Load                   ----- Strength ----  ----- Service -----
       Combination     Type   Mom   Span Distance  Mom   Span Distance  Shr   Span Distance
       =============== ====== ===== ==== ========  ===== ==== ========  ===== ==== ========
       NRL             Legal   2.26    3    23.00   1.65    1    20.50   1.35    3    37.50
       LEGAL_LANE      Legal   3.39    1    46.00   3.45    1    23.00   2.88    1    39.00
       LEGAL_LANE_2    Legal   3.38    1    46.00   3.45    1    23.00   2.81    1    39.00
       TYPE_3          Legal   3.44    3    23.00   2.52    1    20.50   1.44    3    38.50
       TYPE_3S2        Legal   3.13    1    46.00   2.75    1    20.50   1.85    3    38.50
       TYPE_3-3        Legal   3.11    1    46.00   3.08    1    23.00   2.42    3    38.50
       OVERLOAD_1      Permit  4.27    3    23.00   2.68    1    20.50   2.08    3    38.50
       OVERLOAD_2      Permit  2.50    1    46.00   2.51    1    20.50   1.66    3    38.50
       EV2             EV      3.25    3    25.00   2.17    1    20.50   1.19    3    38.50
       EV3             EV      2.15    3    23.00   1.42    1    20.50   0.89    1     4.00
 
       Design Truck:
 
       HL-93           INV     1.43    1    46.00   1.30    1    20.50   0.39    1    40.00
       HL-93           OPER    1.85    1    46.00  15.93    1    18.00   0.51    1    40.00

TEMPLATE REV:10.9
BDF FILE:    82-20N_Interior_girder_post_comments.bdf
TIME    :    Tue Dec  4 11:31:40 2018


* =============================================================================================================================
# [BEGIN DATA ENTRY]           <Beginning of standard "BRIDG" data entry blocks>
= ==================================================================================================================================

* =============================================================================================================================
# [GENERAL COMMENTS]     0000  <BDF File Comments>
* ==================================================================================================================================
*     "BRIDG" DATA BLOCK NAMES, REFERENCE NUMBER, AND DESCRIPTION.
*     FOR EASE IN EDITING/SEARCHING, EACH DATA BLOCK NAME IS ENCLOSED IN SQUARE BRACKETS ([]).
*
*     NAME                 NUM   DESCRIPTION
*     ==================== ====  ==================================================================================================
*     GENERAL COMMENTS     0000  General Comments
*     BRIDGE DESCRIPTION   0001  Bridge Description
*     ANALYSIS CTRLS       0003  Analysis Controls and Parameters
*     IMP & RES FACTORS    0004  Impact and Resistance Factors
*     NBI RES FACTORS      0005  NBI Resistance Factors
*     FRAME DESCRIPTION    1001  Frame Description
*     STAGED CONSTRUCTION  1001A Staged Construction Analysis
*     COLUMN PROPERTIES    1002  Column Data
*     BRACE PROPERTIES     1003  Brace Data
*     LIVE LOAD DIST FACT  1004  Live Load Distribution Factor (LRFD)
*     EXPLICIT LLDF        1005  Explicit Live Load Distribution Factor (LRFD)
*     PROFILE GRADE        1006  Profile Grade Elevations
*     BARRIER & SW GEOM    1008  Barrier and Sidewalk Geometry
*     BOX GIRDER LIBRARY   1010  Box Girder Cross-Section Library
*     BOX GIRDER MEMBER    1011  Box Girder Member Composition
*     CIP T-BEAM MEMBER    1012  Cast-In-Place T-Beam Member Definition
*     SLAB MEMBER          1013  Voided Slab Member Composition
*     PC BOX LIBRARY       1014A Precast Box Girder Library
*     PC GIRDER LIBRARY    1014B Precast Girder Library
*     MISC GIRDER LIBRARY  1014C Miscellaneous Girder Library
*     GIRDER SPACING       1015A Multiple Girder Spacing
*     GIRDER MEMBER COMP   1015B Girder/Slab Member Description
*     RAISED CROSS BEAM    1016  Raised Cross-Beam Description
*     MEMBER TRANSITION    1017  Automatic Member transition
*     SHEAR STEEL          1021  Shear Steel Data
*     TOP STEEL(A)         1022  Top Longitudinal Steel - Negative Moment Reinforcement Data
*     BOTTOM STEEL(A)      1023  Bottom Longitudinal Steel - Positive Moment Reinforcement Data
*     TOP STEEL(B)         1024  Top Longitudinal Steel - Negative Moment Reinforcement Data
*     BOTTOM STEEL(B)      1025  Bottom Longitudinal Steel - Positive Moment Reinforcement Data
*     CABLE PATH DATA      1030  Prestress - Cable Path Data
*     CABLE PATH GEOMETRY  1031  Prestress - Cable Geometry
*     DEAD LOADS           1045  Define Dead Loads
*     MEMBER DEAD LOADS    1046  Member Dead Load Entry
*     MEMBER DL DIST       1047  Member Dead Load Distribution
*     MEMBER LIVE LOADS    1048  Member Live Load Entry
*     TRUCK DEFINITION     1049  Live Load - Truck Data
*     LOAD COMBINATIONS    1050  Live Load Combinations
*
*     TRANSVERSE ANALYSIS  1100  Transverse Beam General Header and Comments
*     TR-BEAM/SLAB/XBEAM   1101  Slab / Lane / Xbeam  Descriptions
*     TR-LOAD TRANSFER LOC 1102  Transverse Beam Load Locations
*     TR-REACTIONS         1105  Transverse Beam Reaction Loads
*     TR-LOAD COMBINATIONS 1110  Cross Beam Live Load Combination
*
*     AR:COMP.TRAN.SECT    5100  Composite Transformed Section Properties
*     AR:GIRDER SECT PROP  5101  Non-Composite Girder Section Properties
*     AR:CABLE DATA        5200  Prestress Cable Info at Member Tenth Points
*     AR:STRAIN COMPAT.    5201  Strain Compatibility Info at Member Tenth Points
*     AR:ULTIMATE CAPACITY 5202  Span Ultimate Capacities
*     AR:DEAD LOADS (FACT) 5300  Working Dead Load, Superimposed Dead Load, and Secondary Shears and Moments
*     AR:LIVE LOADS (FACT) 5302  Factored Live Load Combination Shear and Moment Envelopes
*     AR:DL WORKING STRESS 5400  Dead Load and Superimposed Dead Load Working Stresses
*     AR:PS WORKING STRESS 5401  Prestress and Secondary Working Stresses
*     AR:LL WORKING STRESS 5402  Live Load Working Stresses for Load Combinations
*     AR:WRK STRESS STL -A 5403  Working Stress in Conventional Tension Reinforcement - Part A
*     AR:WRK STRESS STL -B 5404  Working Stress in Conventional Tension Reinforcement - Part B
*     AR:DL FCT WRK STRESS 5500  Factored Dead, Superimposed Dead and Prestress Horizontal Shear Stresses
*     AR:LL FCT HRZ STRESS 5501  Factored Live Load Horizontal Shear Stresses
*     AR:UNFACTORED REACT  5600  Unfactored Reactions
*     AR:NODE FORCE/DISP   5601  Node reaction forces and displacements
*     AR:MEMBER DL DISP    5602  Span static load vertical elastic displacements
*     AR:MEMBER LL DISP    5603  Span live load vertical elastic displacements
*     AR:LOAD RATINGS      5700  Load Rating Factors
*     AR:LOAD RATINGS-FHWA 5700A Load Rating Factors per AASHTO-1994 Criteria
*     AR:LOAD RATINGS-LRFR 5700B Load Rating Factors per AASHTO-LRFR Criteria
*     AR:LLDF AT 10TH PT   5800  Live Load Distribution Factors at 10th Points
*
====================================================================================================================================

* =============================================================================================================================
# [BRIDGE DESCRIPTION]   0001  <General Bridge Description Data>
* ==================================================================================================================================
*  Use the "DESC" entries to include bridge descriptive data with the bridge computer data base.
*  None of the "DESC" information is used by the rating program, but will be included in the program report.
*
*
*  VALID KEY WORDS:  BNUM     --> Bridge Number
*                    DATE     --> Year bridge was built and other pertinent date information.
*                    ENGR     --> Design Engineer
*                    RATER    --> Enter name of company, date, and person rating bridge.
*                    NAME     --> Bridge Name
*                    LOC      --> Bridge location, include route/hwy number, milepost, and descriptive location.
*                    ADTV     --> Average Daily Traffic Reports, and Count Date if supplied.
*                    TITL1    --> First  line of Title that appears on front page of RPT file in title box.
*                    TITL2    --> Second line of Title that appears on front page of RPT file in title box.
*                    FOOT1    --> Footing that appears on bottom of report. Line 1. Typically company name.
*                    FOOT2    --> Footing that appears on bottom of report. Line 2. Typically company type.
*                    DESC     --> Any other descriptive information that should be included with the computer database info.
*                                 Standard uses for DESC are:
*                                   1) Description of bridge structural system. Example: Concrete Box Girder.
*                                   2) Type of reinforcing. Example: Conventional Reinforcing.
*                                   3) Latest inspection report date. Example: Latest inspection report - 10/31/90.
*                                   4) Statement specifying whether or not bridge has a wearing surface.
*
*
*        A maximum of 10 "DESC" entries may be entered. If there is a need to use more than one
*        "DESC", use another "DESC" entry and indent the remaining text if desired.
*        All "DESC" entries are printed on the summary page of the report in order entered.
*
*        WSDOT requires the following Four "DESC" lines:
*        1) DESCRIPTION OF BRIDGE TYPE, FOR EXAMPLE:
*             Concrete Box Girder, Conventional Reinf., High Abutments, Tapered Center Column.
*
*        2) DESIGN LOADING, FOR EXAMPLE:
*             Design Loads: HS20 or TWO 24 KIP AXLES at 4 Ft Ctrs
*
*        3) LATEST INSPECTION REPORT, FOR EXAMPLE:
*             Latest Inspection Date - 10/31/1990
*
*        4) WEARING SURFACE DESCRIPTION OR NOTE THAT THERE IS NONE.
*
*
*
KEY
WORD       TEXT
=====  ============================================================================================================================
BNUM   82-20N Interior Girder
DATE   1969
ENGR   
RATER  Burns and McDonnel
NAME   I-82 @ Borland Road Exit 11
LOC    
ADTV   
CDATE  
TITL1  
TITL2  
FOOT1  
FOOT2  
DESC   3 Span PCB, three spans continuous for live load
DESC   Design Live Load HS20
DESC   1.5  in. modified concrete overlay

* =============================================================================================================================
# [ANALYSIS CTRLS]       0003  <Analysis Controls and Parameters>
* ==================================================================================================================================
*  NOMENCLATURE: Each Keyword has an accompanying value, a Yes or No,  or another keyword.
*                The accompanying type is specified by the following:
*                 #         = a number
*                 (Yes/No)  = The words Yes or No
*                 <keyword> = Another keyword
*
*  COMMENTS: If Transverse Analysis:
*             Data block 1049 is ignored.
*             If a ".REA" is not available, data block 1105 must be used.
*
*  TRUCK SPEED CONTROLS:
*
*  During live load calculations, the distance a truck or point load is moved
*  is controlled by two values: TruckSpeed and MotionMode.
*
*  For Longitudinal Analysis, if MotionMode is set to 'F' for fraction, then the
*  truck is moved a distance equal to TruckSpeed times the length of the current
*  span.  The current span is the span that the truck's front wheel is on.  The
*  truck is always started at the beginning of each span.
*
*  For transverse analysis, if MotionMode is set to 'F' then each truck is moved
*  a distance equal to TruckSpeed times Lane Width.
*
*  If MotionMode is set to 'D' for distance, then all live loads are moved a
*  distance equal to Truck Speed for each iteration.
*
*  The following are suggested values, but bridges with both short and long
*  spans may need adjustment to these parameters.
*
*   1) Longitudinal Analysis:
*      MotionMode = 'F', TruckSpeed = 0.05 (1/20 span length)
*
*   2) Transverse Analysis: MotionMode = 'F', TruckSpeed = 0.25 (1/4 lane width)
*
*
*  Note: For Longitudinal Analysis, the TruckSpeed is limited to a minimum
*        of IDist and a maximum of 10 feet.
*
*
*                             KeyWord      Comment
*                             ==========   =======================================================================================
*  Keywords for:NoShrRFCLS    None         This option not active
*               RdMomRFCLS    FaceOfSup    Face of support
*                             Dg/2         1/2 Girder Depth from face of support
*                             D/2          1/2 Total Depth from face of support
*                             Dg           Girder Depth from face of support
*                             D            Total Depth from face of support
*
*
           Number,
           Yes or No
Key Word   or KeyWrd   Type       COMMENT
========== ==========  ========   =================================================
*-----   Analysis / Graphics Controls -----
ModelType  Lngitudnal  (Keyword)  Either: Lngitudnal (Longitudinal) or Transverse. Lngitudnal is the default.
IDist           0.500  (#)(ft)    Analysis Integration Distance
MinANodes          20  (#)        Minimum number of analysis nodes per member.
MaxDNodes      10.000  (#)(ft)    Maximum distance between analysis nodes.
TruckSpeed      0.050  (% or ft)  See Truck Speed notes in header
MotionMode          F  (F or D)   See Truck Speed notes in header
LnLdSpeed           2  (#)        Lane Load Rider speed as multiple of IDist
TickTime            5  (Seconds)  Screen update interval for "crunching icon" while BDRS is working. 999=Off
MotionIter         10  (#)        Number of analysis iterations per screen animation updates. 999=No Animation.
WhLdSpread      2.000  (#)(ft)    Distance to spread wheel load over
RptMbrTran          N  (Yes/No)   Report member sections generated by MemberTransition in report file.

*------- Valid ONLY for FHWA analysis method ------
FHWAAutoCv          Y  (Yes/No)   Automatically convert loading
InvLLF          2.170  (#)        Inventory Live Load factor. (FHWA only)
OperLLF         1.300  (#)        Operating Live Load factor. (FHWA only)
MomArmCnvg      0.042  (inches)   Convergence distance when computing compression block moment arm.
SetMRatio       0.000  (#)        Force modular ratio to value. If zero then BRIDG will compute modular ratio.
OvLdIMP         1.100  (#)        Impact factor for overload trucks (FHWA only)
DLFactor        1.300  (#)        Dead ultimate load factor.
PSFactor        1.000  (#)        PS ultimate load factor.

*------- Valid ONLY for LRFD analysis method ------
LRFRAutoCv          Y  (Yes/No)   Automatically convert loading
DCFactor        1.250  (#)        Dead load component factor
DWFactor        1.500  (#)        Dead load wearing surface factor
Inv2LLF         1.750  (#)        Inventory Live Load factor. (LRFR only)
Oper2LLF        1.350  (#)        Operating Live Load factor. (LRFR only)
LegalLLF        1.450  (#)        Legal Live Load factor.
PermitLLF       1.200  (#)        Permit Live Load factor.
EVehicleLLF     1.300  (#)        Emergency Vehicle Live Load factor.
ServiceLLF      1.000  (#)        Service Live Load factor.
HL93IMP         1.330  (#)        Impact for HL93 (Inv and operating)
LegalIMP        1.100  (#)        BDM Impact for legal, permit and emergency vehicles
SysFactor       1.000  (#)        System factor (for redundancy. 1.00=redundant)
BridgeWdth      0.000  (#)        Full width of bridge. Minimum width is one lane width.
LaneWidth      10.000  (ft)       Width of each lane.
IntrBeam            N  (Yes/No)   Is this interior beam analysis (else exterior)

*------  Analysis Switches  --------------
CalcInf             N  (Yes/No)   Calculate influence lines. (Results in diagnostic file .INF)
CalcBC              N  (Yes/No)   Calculate FEM Nodal Boundary Condition Resultant Forces.
CalcColBr           N  (Yes/No)   Calculate Column/Brace forces (Results in diagnostic file .CBF)

*------  Factors and logic controls  -----
ColConcWt     155.000  (#)(pcf)   Column concrete weight.
BrcConcWt     155.000  (#)(pcf)   Brace  concrete weight.
GrdConcWt     155.000  (#)(pcf)   Girder concrete weight.
SlabConcWt    155.000  (#)(pcf)   Slab concrete weight.
LongStlFy      40.000  (#)(ksi)   Longitudinal steel yield strength.
ShrStlFy       40.000  (#)(ksi)   Shear steel yield strength.
SrvLRNM             Y  (Yes/No)   Service load rating for negative moment.
CreepFact       2.000  (#)        Creep factor for long term displacements.
CrackMom            Y  (Yes/No)   Use cracking moment as minimum concrete capacity.
StrCapTol       1.000  (#)(Kips)  Strain compatibility calculation iteration tolerance.
CTratio         0.900  (#)        Ratio of yield stress to ultimate stress of prestress strand. Used in CT equations.

*----- Load Reduction and Adjustment Codes -----
PsShrRFCLS          D  (Keyword)  Reduce loads for prestress shear rate from center line of support to <keyword>.
CvShrRFCLS          D  (Keyword)  Reduce loads for conventional shear rate from center line of support to <keyword>.
PsMomRFCLS       NONE  (Keyword)  Reduce loads for prestress moment rate from center line of support to <keyword>.
CvMomRFCLS  FACEOFSUP  (Keyword)  Reduce loads for conventional moment rate from center line of support to <keyword>.
NegMomInc           N  (Yes/No)   Negative moment increase 1/2d from face of support.
RateSupt            N  (Yes/No)   Rate from center line of support to face of support.

*----- LFR (FHWA) Allowable Stresses -----
AllowTen        6.000  (mult)     Allow PS concrete tension stress multiplier * SQRT(f'c). If 0.0 then default to 6.0
AllowTenOL      6.900  (mult)     Allow PS concrete tension stress multiplier * SQRT(f'c) for Overload. If 0.0 then default to 6.9
AllowCmp        0.600  (mult)     Allow PS concrete compression stress multiplier * (f'c). If 0.0 then default to 0.6
AllowCmpOL      0.690  (mult)     Allow PS concrete compression stress multiplier * (f'c) for Overload. If 0.0 then default to 0.69
AllowCmp2       0.400  (mult)     Allow PS concrete compression stress multiplier * (f'c). If 0.0 then default to 0.4
AllowCp2OL      0.460  (mult)     Allow PS concrete compression stress multiplier * (f'c) for Overload. If 0.0 then default to 0.46
AllowPSInv      0.800  (mult)     Allow steel tension stress multiplier * (fy) for Inventory service check. If 0.0 then default to 0.8
AllowPSOp       0.900  (mult)     Allow steel tension stress multiplier * (fy) for Operating service check. If 0.0 then default to 0.9

*----- LRFR Allowable Stresses -----
AllowPSOL       0.900  (mult)     Allow ... this factor only applies to the Permit load case.

* =============================================================================================================================
# [IMP & RES FACTORS]    0004  <Impact and Resistance Factors>
* ==================================================================================================================================
* Reference  AASHTO and WSDOT BDM for correct factors.
* The "SPAN COND. CODE" and "SPAN CONDITION FIELD SURVEY COMMENTS" fields are for documentation only and
*    not used by the program.
*
*
    REDUNDANT                         SPAN
MBR   CODE     RESISTANCE FACT.       COND
#     N/R      MOMENT     SHEAR       CODE.    SPAN CONDITION FIELD SURVEY COMMENTS
===    =        =.==       =.==        =      =====================================================================================
  1    R        0.95       0.90        6
  2    R        0.95       0.90        6
  3    R        0.95       0.90        6

* =============================================================================================================================
# [NBI RES FACTORS]      0005  <Resistance Factors>
* ==================================================================================================================================
* Reference AASHTO and WSDOT BDM for correct factors based on rating method used. Default values shown assumes fair condition of
* member; Adjust resistance factors as needed based on condition per the latest inspection report
*
* (LFR) Default Values: REINFORCED CONCRETE (No PS or PT):    MOM=0.90 SHR=0.85
*                       PRESTRESSED CONCRETE ............: PosMOM=1.00 NegMOM=0.90 SHR=0.90
*                       POST-TENSIONED ..................: PosMOM=0.95 NegMOM=0.90 SHR=0.90
* For LRFR, see Section 5.5.4.2 of the LRFD Specification
*
*

      CONVENTIONAL   --PRESTRESSED---   --POST-TENSION--
MBR   REINFORCED     Pos   Neg          Pos   Neg
#     MOM   SHR      MOM   MOM   SHR    MOM   MOM   SHR
===   =.==  =.==     =.==  =.==  =.==   =.==  =.==  =.==
  1   0.90  0.90     1.00  0.90  0.90   0.95  0.90  0.90
  2   0.90  0.90     1.00  0.90  0.90   0.95  0.90  0.90
  3   0.90  0.90     1.00  0.90  0.90   0.95  0.90  0.90

* =============================================================================================================================
# [FRAME DESCRIPTION]    1001  <Finite Element Model Description>
* ==================================================================================================================================
* MEMBER END NOMENCLATURE:  L = Left end for Horizontal members or
*                               first defined member end for Columns and Braces.
*                           R = Right end for Horizontal members or
*                               Second defined member end for Columns and Braces.
*
* NODE NUMBER:  Node numbers for the Left and Right member ends.
*
* SUPPORT CODE:  Member End Boundary Condition:
*                Pin = P,  Roller = R,  Fix = F   These are Nodal Fixity Codes.
*                Hinge = H  Release moment continuity between member end and adjoining member(S)
*
* DIRECTION:  Horizontal = H,  Vertical = V,  Brace = B.
*
* COLUMN BASE OFFSET:  Distance a sloped column is offset from top to base.
*                      If column base offset is positive this indicates a positive
*                      slope from the base up to the bridge.
*
* SUPPORT WIDTH:  Entry valid for horizontal members.
*                 if left blank, then loads at the centerline of the support are used.
*
* LLDF       Live Load Distribution Factor set ID (see 1004 and 1005). Only used for LRFD analysis.
*
*
* COMMENTS:  Horizontal Members must be listed prior to listing Columns.
*            Horizontal Members must begin with Member 1 and be numbered contiguously.
*            Columns must begin with the Number 1 and be numbered contiguously.
*            Braces must be listed last and use nodes already defined by the HORZ. or VERT. Members.
*
*
     - MEMBER END --
MBR  - CONDITIONS --         COLUMN
OR    NODE    SUPPORT        BASE     - SUPPORT WIDTH -
COL   NUMBER   CODE          OFFSET    NODE L   NODE R   LENGTH    LLDF
 #    L   R    L  R     DIR   (ft)      (ft)     (ft)     (ft)     ID#
===  === ===   =  =      =   ===.==    ===.==   ===.==   ===.==    ===
  1    1   2   R  P      H               0.00     0.50    46.50      1
  2    2   3   P  P      H               0.50     0.50    50.00      2
  3    3   4   P  R      H               0.50     0.00    41.50      3

* =============================================================================================================================
# [STAGED CONSTRUCTION]  1001A <Staged Construction Control Parameters>
* ==================================================================================================================================
* PRESTRESS BEAM ID: During STAGE 1 Analysis, each Prestress Beam is analyzed Separately from all other Stage 1 Prestress Beams.
*
*                    A STAGE 1 Prestress Beam is defined as a Member with boundary conditions as Pinned at the left end and Roller
*                    at the right end. Assign a unique beam identification number for each Stage 1 Prestress Beam. starting with
*                    number 1.
*
*                    If a Beam is comprised of more than one Member, then all Members of that Beam will have the same ID Number.
*                    Members not included in a STAGE 1 Prestress Analysis should have this column left blank.
*
* FALSEWORK FLAG:  If a Member end is supported by falsework during this STAGE of analysis, then enter a 'Y' in this column.
*                  The Reactions computed for this support will be applied as loads in STAGE 3.
*
* REACTION LOAD STAGE: The reactions caused by Dead Loads from STAGE 1 can be reapplied to the analysis in either STAGES 2 or 3.
*                      Specify in this column which STAGE to apply Reaction Forces. A blank entry will default to STAGE 2.
*
*
* STIFFNESS PROPERTY CODE: During each STAGE, the Stiffness Properties for each Member needs to be specified.
*                          If this column is left blank, then that Member is not included in that STAGE of the analysis.
*
*                          The Two Stiffness CODES used are:
*                            G - Girder Stiffness only.
*                            C - Composite Girder and Slab Stiffness.
*
* SELF WEIGHT PROPERTY CODE: During any of the Three STAGES, you can select the amount of MEMBER SELF WEIGHT
*                            that is to be included in the computations. Be careful not to "Double" a Members
*                            Self Weight by specifying it more than once.
*
*                            The Three Self Weight CODES are:
*                              S - Slab Weight only.
*                              G - Girder Weight only.
*                              C - Composite Girder and Slab Weight.
*
*
              STAGE 1: SIMPLE SPAN             STAGE 2: FEM MODEL            STAGE 3: FEM MODEL
              =============================    ===========================   =================
              SIMP   STIFF  SELF     REACT.    FALSEWORK    STIFF  SELF      STIFF  SELF
       DL     SPAN   PROP.  WEIGHT   LOAD      FLAG         PROP.  WEIGHT    PROP.  WEIGHT
MBR    STAGE  BEAM   CODE   CODE     STAGE     LEFT  RIGHT  CODE   CODE      CODE   CODE
 #     #      ID #   (G/C)  (G/S/C)  (2or3)    (Y/N) (Y/N)  (G/C)  (G/S/C)   (G/C)  (G/C/S)
===    =      ===    =      =        =           =     =    =      =         =      =
  1    1        1    G      C        3                                       C
  2    1        2    G      C        3                                       C
  3    1        3    G      C        3                                       C

* =============================================================================================================================
# [LIVE LOAD DIST FACT]     1004  <Live Load Distribution Factors>
* ==================================================================================================================================
* Assign load distribution factors to members and provide information needed to compute them.
*
* Live Load Distribution Factors (LLDF) are computed as part of the LRFR extension to Bridg10.
* Many parameters needed for the evaluation of the LLDF according to AASHTO 2010 LRFD Manual 4.6.2.2
* are taken from cross section parameters given in cards 1001-1016.  However, several new geometric
* parameters are needed to compute LLDF after AASHTO 2010 LRFD and shall be entered in this set of cards.
*
* AASHTO 2010 LRFD specifies (tables 4.6.2.2.1-1, 4.6.2.2.2b-1, 4.6.2.2.2d-1, 4.6.2.2.2e-1, 4.6.2.2.3a-1,
* 4.6.2.2.3b-1, 4.6.2.2.3c-1) a range of applicability for which LLDFs can be computed.
* Configurations that do not fall within this range require a more refined analysis (not covered by BRIDG10) and
* LLDFs for such cases need to be provided through card "1005".
*
* In addition to computing LLDFs, the user can override some or all LLDFs for any given member
* using card "1005" even for bridges that fall within the range of applicability.
*
* Variables:
*
*    MBR:            Member ID for which this set of information applies
*    ID:             Identification of LLDFs from card 1005;
*                    used provide values from a refined analysis OR to override computed values.
*    SECT TYPE:      Cross Section Type according to AASHTO 2010 LRFD Manual - Table 4.6.2.2.1-1
*    NDL:            Number of Design Lanes
*    EFF LENGTH:     Effective span length (in feet) according  AASHTO 2010 LRFD Manual - Table C4.6.2.2.1-1
*                    If nothing given, the span length from model will be used.
*    SINGLE UNIT:    (Y/N) does cross section act as a single unit?              : DEFAULT = Yes
*    THETA SKEW:     Theta Skew = skew angle in degrees between adjacent girders : DEFAULT = 0.0
*    NUMBER BEAMS:   If not entered then will use "Bridge Width / Beam Width"


                                                  DIST
            EFF           THETA  SINGLE           CENTR                   INTL   EXT   LEFT    RGHT
LLDF  SECT  LENGTH         SKEW   UNIT    NUMBER  LINE    NUM    NUM      SPC    SPC   OVRHG   OVRHG
ID#   TYPE  (FT)    NDL   (deg)   (Y/N)   BEAMS   (FT)    CELLS  BRACES   (FT)   (FT)   (FT)   (FT)
===    =    ===.==  ===   ===.==   =       ===    ===.==   ==     ==       ==.==  ==.==  ==.==  ==.==

* =============================================================================================================================
# [EXPLICIT LLDF]     1005  <Explicit Live Load Distribution Factors>
* ==================================================================================================================================
* COMMENTS:  For LRFD analysis the program will compute these factors unless entered here.
*            Factors entered here will override any computed factors.
*            You do not need to enter all values, any values not entered will be computed by the program
*            if sufficient information is given in CARD 1004.
*
*            Note: If only some values are entered, these are assumed to be for an interior girder
*                  when computing missing values using the AASHTO tables and information from CARD 1004.
*
*            For LFR (FHWA or STD methods) a single moment factor, DF, is used (previously specified in CARD 1050).
*            For LFR method a single DF is entered for both moment and shear.
*
*  ID#    Unique ID for a set of interior and exterior factors.
*  SD     Shear distribution factor (Legal, Design and Emergency Vehicles)
*  MD     Moment distribution factor (Legal, Design and Emergency Vehicles)
*  SP     Shear permit distribution factor
*  MP     Moment permit distribution factor
*  DF     Moment and Shear distribution factor for LFR (FHWA) method
*

ID#     SD   MD   SP   MP    LFR DF
===    =.== =.== =.== =.==    =.==
  1    0.90 0.83 0.61 0.51    0.82
  2    0.90 0.81 0.61 0.50    0.82
  3    0.90 0.85 0.61 0.53    0.82

* =============================================================================================================================
# [PC GIRDER LIBRARY]    1014B <Precast Girder Library>
* ==================================================================================================================================
* NOTE: THE VALUES IN THIS LIBRARY MUST BE CHECKED FOR ACCURACY.  THEY ARE PROVIDED HERE AS A
*       CONVENIENCE FOR THE USER.
*
*
  GIRDER     a      b      c      d      e      f      g      h      j      w      x      y      z
   NAME     (in)   (in)   (in)   (in)   (in)   (in)   (in)   (in)   (in)   (in)   (in)   (in)   (in)
==========  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==  ==.==
S60_3.5H    14.00   3.50   1.50         30.00   2.00   5.00  42.00  19.00   5.00   4.50          7.00
S60_3.5HEB  14.00   3.50   1.50         30.00   0.71   5.00  42.00  19.00  14.00                 2.50

* =============================================================================================================================
# [PC GIRDER MEMBER]     1015B <Precast Girder/Slab Member Definition>
* ==================================================================================================================================
* REFERENCE END FLAG:  L = Dimensioned from Left End of Member,
*                      S = Symmetric about Mid-Member. (Not symmetric about Span)
*
* GIRDER NAME:  Must match a Girder Library name from 1014A, 1014B or 1014C data block.
*
* ANALYSIS:  F = Full Cross Section Analysis,  L = One Line of Girder Analysis.
*
* EFFECTIVE SLAB WIDTH:  Is used for a Line of Girder Analysis only.
*
*
                                                 TOP                          EFFECTIVE  TRIBUTARY
           REF              GIRDER         SLAB  SLAB   DIST.       ANALYSIS  SLAB       SLAB
MBR  DIST  END    GIRDER     F'c    SPAC    F'c  THICK   A     S/W  TYPE      WIDTH      WIDTH
 #   (ft)  FLAG    NAME     (ksi)   ID#    (ksi)  (in)  (in)   ID#  (F/L)      (ft)       (ft)
=== ===.==  =   ==========  ==.=    ===    ==.=  ==.==  ==.==  ===    =       ===.==     ===.==
  1   0.00  L   S60_3.5HEB   6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  1   6.50  L   S60_3.5H     6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  1  43.33  L   S60_3.5HEB   6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  2   0.00  L   S60_3.5HEB   6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  2   8.00  L   S60_3.5H     6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  2  46.50  L   S60_3.5HEB   6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  3   0.00  L   S60_3.5HEB   6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  3   8.00  L   S60_3.5H     6.0      0     4.0   7.00   7.00    0    L         9.00       9.00
  3  39.45  L   S60_3.5HEB   6.0      0     4.0   7.00   7.00    0    L         9.00       9.00

* =============================================================================================================================
# [MEMBER TRANSITION]    1017  <Automatic Member transition>
* ==================================================================================================================================

     START   END    No.
MBR  DIST    DIST   OF
 #   (ft)    (ft)   Seg.  COEF.Z
=== ===.==  ===.==  ====  ===.==
  1   2.00    6.50     0    0.00
  1  38.83   43.33     0    0.00
  2   3.50    8.00     0    0.00
  2  42.00   46.50     0    0.00
  3   3.50    8.00     0    0.00
  3  34.95   39.45     0    0.00

* =============================================================================================================================
# [SHEAR STEEL]          1021  <Shear Steel Data Entry>
* ==================================================================================================================================
* S  = Shear Reinforcement Spacing.
* SX = crack spacing parameter used to compute effective crack spacing parameter sxe
*      (AASHTO LRFD, Section 5.8.3.4.2, Figure 5.8.3.4.2-3)
*      -> enter 0.00 or no value for SX if insufficient longitudinal shear reinforcement
*
           REF          STEEL
MBR  DIST  END    S     AREA     SX
 #   (ft)  FLAG  (in)   (in)^2  (in)
=== ===.==  =    ==.==  ===.==  ==.==
  1   0.00  L     8.50    1.24   9.33
  1   3.50  L    18.00    0.40   0.00
  1  41.33  L     8.50    1.24   9.33
  2   0.00  L     8.50    1.24   9.33
  2   5.00  L    18.00    0.40   0.00
  2  45.00  L     8.50    1.24   9.33
  3   0.00  L     8.50    1.24   9.33
  3   5.00  L    18.00    0.40   0.00
  3  38.95  L     8.50    1.24   9.33

* =============================================================================================================================
# [TOP STEEL(A)]         1022  <Top Steel (Neg.Mom.) Direct Area Entry>
* ==================================================================================================================================
* Development length should be considered for user input - not accounted for by the program (!)
* DEPTH FROM TOP OF STRCT SLAB is to CG of reinforcement (mild steel)
*
                         DEPTH FROM
           REF   STEEL   TOP OF
MBR  DIST  END   AREA    STRCT SLAB
 #   (ft)  FLAG  (in)^2    (in)
=== ===.==  =    ====.==   ==.==
  1   0.00  L       5.89    3.50
  1  24.58  L       6.47    3.50
  1  33.83  L       7.67    3.50
  1  39.83  L       8.55    3.50
  1  42.33  L       9.43    3.50
  2   0.00  L       9.43    3.50
  2   5.00  L       8.55    3.50
  2   7.00  L       7.67    3.50
  2  13.50  L       6.47    3.50
  2  36.50  L       7.67    3.50
  2  43.00  L       8.55    3.50
  2  45.00  L       9.43    3.50
  3   0.00  L       9.43    3.50
  3   4.00  L       8.55    3.50
  3   6.50  L       7.67    3.50
  3  12.50  L       6.47    3.50
  3  21.75  L       5.89    3.50

* =============================================================================================================================
# [CABLE PATH DATA]      1030  <Cable Path General Description and Forces>
* ==================================================================================================================================
*
* JACK END:        Both = B,  Left = L,  Right = R.
* CABLE DIAM:      For calculating cable development only.
* DEFAULT VALUES:  F's = 270 ksi,  E = 28000 ksi,  Jacking Force = (Stage1 = 0.7*AREA*F's) (Stage > 1 = 0.75*AREA*F's), k = 0.280
* DEFAULT VALUES:  Stage Code = must be filled in,  Jack End = B,  E Mult = 1.0.
* STAGE CODE:      1 = Shop Prestressed/post-tensioned,  post-tensioned codes are by construction Stage 2,3 OR 4.
* k-value:         as defined by AASHTO LRFD in Table C5.7.3.1.1-1.  Used in the computation of f_ps.
* fpo/fpu:         Used in MFCF-theory to assess the strengthening effect of axial compression; typically 0.70-0.75.
*                  Computed by Bridg as (Jacking force)/((TOTAL AREA)*(F's) and presented in report for validation only.
*
* NOTE:  STAGE 1 Prestress data is input on a Per-Girder basis. For
*        all other STAGES, Prestress/Post-tension data is input on a
*        full bridge width basis.
*
*
     | -------------- CABLE INFO ------------- | -STAGED CONST- | ---------------- LOSS INFO ---------------- | ---- LRFR ---- |
     |                                         |                |                                             |                |
     |  TOTAL                 CABLE  JACKING   |                | LUMP-SUM  WOBBLE  CURVE  -ANCHOR SET-       |                |
PATH |  AREA    DIAM    F's     E     FORCE    |  STAGE         |  LOSSES   COEFF   COEFF   LEFT  RIGHT  JACK |   k-     fpo / |
 #   | (in)^2   (in)   (ksi)  (ksi)   (kips)   |  CODE          |  (ksi)      K      u      (in)  (in)   END  |   value    fpu |
===  | ====.==  =.===   ===   =====  ======.=  |    =           |    ==     =.====  =.===  =.===  =.===   =   |   =.===  =.=== |
  1       1.53  0.500   270   28500     289.0       1                41     0.0000  0.000  0.000  0.000   B       0.380  0.700
  2       0.77  0.500   270   28500     145.0       1                41     0.0000  0.000  0.000  0.000   B       0.380  0.700
  3       1.53  0.500   270   28500     289.0       1                44     0.0000  0.000  0.000  0.000   B       0.380  0.700
  4       1.07  0.500   270   28500     202.0       1                44     0.0000  0.000  0.000  0.000   B       0.380  0.700
  5       1.22  0.500   270   28500     232.0       1                37     0.0000  0.000  0.000  0.000   B       0.380  0.700
  6       0.61  0.500   270   28500     116.0       1                37     0.0000  0.000  0.000  0.000   B       0.380  0.700

* =============================================================================================================================
# [CABLE PATH GEOMETRY]  1031  <Cable Path Segment Geometry Description>
* ==================================================================================================================================
* 'Y' DISTANCES:  If Stiffness property code in the 1001A data block = "G"
*                 then distance is down from the top of "GIRDER".
*
*                 If Stiffness property code in the 1001A data block = "C"
*                 then distance is down from the top of "SLAB".
*
*  UNITS:  F = Units are in feet.  P = Units are in percentage of Member or Span.
*  NOTE:   Either the Member number or Span number must be filled in, but not "BOTH".
*
*
                  |FILL IN ONE|
      PATH        |-- ONLY! --|
PATH  TYPE  UNITS | MBR  SPAN |   Xa     Xia    Xc     Xib    Xb     Ya     Yc     Yb
#     #      F/P  | #    #    | (ft/%) (ft/%) (ft/%) (ft/%) (ft/%)  (ft)   (ft)   (ft)
===   ==      =   | ===  ===  | ===.== ===.== ===.== ===.== ===.== ===.== ===.== ===.==
  1    1      P       1           0.00   0.00   0.00   0.00   0.00          3.32
  2    2      P       1           0.00  33.33   0.00  33.33   0.00   0.31   2.51   0.31
  3    1      P       2           0.00   0.00   0.00   0.00   0.00          3.32
  4    2      P       2           0.00  33.33   0.00  33.33   0.00   0.35   2.67   0.31
  5    1      P       3           0.00   0.00   0.00   0.00   0.00          3.35
  6    2      P       3           0.00  33.33   0.00  33.33   0.00   0.24   2.58   0.24

* =============================================================================================================================
# [DEAD LOADS]           1045  <Define Dead Loads>
* ==================================================================================================================================
* Uniform loads entered in this data block will be applied over the "ENTIRE BRIDGE".
* Load Multiplication is performed due to multiple elements.
* The 1047 data block is used to distribute the applied Dead Loads to each Member.
* Additional loads on a per Member basis can be applied using the 1046 data block.
* Only one entry for each load case is allowed.
*
* DC ... dead load using DC-load factor (LRFR)
* SC ... superimposed dead load using DC-load factor (LRFR)
* SW ... superimposed dead load using DW-load factor (LRFR)
*
                 DL OR            UNIFORM
             LC  SDL              LOAD
LC NAME      #   (DC/SC/SW)       (k/ft)       NOTE (optional)
==========   =    ==              =====.===    ====================================================================================
Slab Wear    1    DC                  0.000
Grd Pad      2    DC                  0.026    Assume Grd Pad is fillet
Misc DL-A    3    DC                  0.000
Misc DL-B    4    DC                  0.000
Railing      1    SC                  0.000
Barrier      2    SC                  0.174    2 rails divided by 5 girders
SideWalk     3    SC                  0.000
Overlay      4    SW                  0.000
Utilities    5    SC                  0.000
Misc SDL     6    SC                  0.169    MCO  1.5 inch (not a FWS)

* =============================================================================================================================
# [MEMBER DEAD LOADS]    1046  <Member Dead Load Entry>
* ==================================================================================================================================
* LOAD TYPE:   DC ... dead load using DC-load factor (LRFR)
*              SC ... superimposed dead load using DC-load factor (LRFR)
*              SW ... superimposed dead load using DW-load factor (LRFR)
*
* LOAD CODES:  L  -- Linear Load: Enter: Beginning Left Load and Distance from Start of Member as Left Location.
*                                        Ending    Right Load and Distance from Start of Member as Right Location.
*
*              U  -- Uniform Load over the entire Member: Enter: Only "Total Load Left" as the uniform load to apply.
*
*              P  -- Point Load:  Enter Left Load and Distance from Start of Member as Left Location.
*
*              M  -- Member Moment: Enter Moment as Left Load and Distance from Start of Member as Left Location.
*                    Counter clockwise is positive moment.
*
* UNITS: All loads are in KIPS, or KIPS PER FOOT.
*        Distance is in units of FEET.
*
* LOAD CASE NUMBERS: For Dead Load, must be between 1 AND 4.
*                    For Superimposed Dead Load, must be between 1 AND 6.
*
* COLUMN and BRACE LOADING: All Column(V) and Brace(B) dead loads will be applied in stage 3 for dead loads, and
*                           stage 4 for superimposed dead loads.
*
*
     MBR     DC                                       -- LOCATION --
MBR  TYPE    SC      LC    LOAD  -- TOTAL LOAD ---     LEFT    RIGHT
 #   H/V/B   SW      #     CODE    LEFT      RIGHT     (ft)    (ft)          COMMENTS
===    =     ==      =      =    ====.===  ====.===   ===.==  ===.==  =============================================================
  1    H     DC      3      P       2.620              23.16                DIAPHRAGM
  2    H     DC      3      P       2.620              25.00                DIAPHRAGM
  3    H     DC      3      P       2.620              20.75                DIAPHRAGM

* =============================================================================================================================
# [TRUCK DEFINITION]     1049  <Truck Definitions>
* ==================================================================================================================================
* If there are more than five point loads,
* continue on next line with same load number.
*
* If Lane Loading values are included, and the Truck input requires more
* than one line, enter the Lane Loading data only on the first line.
*
* TRUCK TRAIN:  Y = >> Two trucks used for negative moment
*                   >> One truck used for  positive moment
*                   >> One truck used for positive and negative shear
*               N = >> One truck used for positive and negative moment and shear.
*
* RESERVED NAMES: Do NOT use these truck names or else then may be changed by the auto-LRFD load generator
*      HL-93_14_14_Truck
*      HL-93_14_22_Truck
*      HL-93_14_30_Truck
*      HL-93_TANDEM
*      HL-93_14_14_TRAIN
*      UNIFORM_LANE_LOAD
*      TYPE_3_Truck
*      TYPE_3S2_Truck
*      TYPE_3-3_Truck
*      NRL_Truck
*      LEGAL_LANE
*      LEGAL_LANE_2
*      OVERLOAD_1_Truck
*      OVERLOAD_2_Truck
*      EV2_Truck
*      EV3_Truck
*

                                                                                          --- ALTERNATE ------    --- LRFD ----
LIVE                                                                                       --- LANE LOADING ---   --- ONLY ----
LOAD /                                                                                     UNIF.   MOM.   SHEAR     LL    TRUCK
TRUCK                              P1    D1      P2    D2      P3    D3      P4    D4      LOAD    RIDER  RIDER   IMPACT  TRAIN
#     Live Load / Truck Name    (kips) (ft)   (kips) (ft)   (kips) (ft)   (kips) (ft)     (klf)   (kips) (kips)    (Y/N)  (Y/N)
==    ======================    ===.=  ==.=   ===.=  ==.=   ===.=  ==.=   ===.=  ==.=     ===.==  ==.==  ==.==       =      =
 1    HL-93_14_14_Truck           8.0  14.0    32.0  14.0    32.0                                                    Y      N
 2    HL-93_14_22_Truck           8.0  14.0    32.0  22.0    32.0                                                    Y      N
 3    HL-93_14_30_Truck           8.0  14.0    32.0  30.0    32.0                                                    Y      N
 4    HL-93_TANDEM               25.0   4.0    25.0                                                                  Y      N
 5    HL-93_14_14_TRAIN           7.2  14.0    28.8  14.0    28.8                                                    Y      Y
 6    UNIFORM_LANE_1KPF                                                                     1.00                     N      N
 7    TYPE_3_Truck               16.0  15.0    17.0   4.0    17.0                                                    Y      N
 8    TYPE_3S2_Truck             10.0  11.0    15.5   4.0    15.5  22.0    15.5   4.0                                Y      N
 8    TYPE_3S2_Truck             15.5
 9    TYPE_3-3_Truck             12.0  15.0    12.0   4.0    12.0  15.0    16.0  16.0                                Y      N
 9    TYPE_3-3_Truck             14.0   4.0    14.0
10    NRL_Truck                   6.0   6.0     8.0   4.0     8.0   4.0    17.0   4.0                                Y      N
10    NRL_Truck                  17.0   4.0     8.0   4.0     8.0   4.0     8.0
11    LEGAL_LANE                  9.0  15.0     9.0   4.0     9.0  15.0    12.0  16.0                                Y      N
11    LEGAL_LANE                 10.5   4.0    10.5
12    LEGAL_LANE_2                9.0  15.0     9.0   4.0     9.0  15.0    12.0  16.0                                Y      N
12    LEGAL_LANE_2               10.5   4.0    10.5  30.0     9.0  15.0     9.0   4.0
12    LEGAL_LANE_2                9.0  15.0    12.0  16.0    10.5   4.0    10.5
13    OVERLOAD_1_Truck           10.0  10.0    21.5   4.0    21.5  12.0    21.5   4.0                                Y      N
13    OVERLOAD_1_Truck           21.5
14    OVERLOAD_2_Truck           12.0  10.0    21.5   4.0    21.5   6.0    22.0  16.0                                Y      N
14    OVERLOAD_2_Truck           21.5   4.0    21.5   6.0    22.0  14.0    21.5   4.0
14    OVERLOAD_2_Truck           21.5   6.0    22.0
15    EV2_Truck                  24.0  15.0    33.5                                                                  Y      N
16    EV3_Truck                  24.0  15.0    31.0   4.0    31.0                                                    Y      N

* =============================================================================================================================
# [LOAD COMBINATIONS]    1050  <Longitudinal Analysis Load Combinations>
* ==================================================================================================================================
* COMMENTS:  For each Loading Combination, enter a line for each Member
*            to be loaded with the appropriate Data with up to 2 different
*            Trucks per Member and an optional LANE LOAD.
*
* LANE LOAD: Two types of lane loads are available in BRIDG
*            1) ADDED UNIFORM LANE LOAD is a span-wide load used in FHWA and STD.
*               For LRFR set its magnitude to 0.00 and use option 2.
*            2) LANE LOAD is placed based on influence lines, allowing for partial span loading - used with LRFR
*               LC   identifies the load case/truck number in CARD 1049
*               LOAD identifies the intensity in kips/foot
*               LANE MULT is the number of lanes on which this lane load appears
*
* FOR RATING TYPE: H:Inventory&Operating: Use Inv2LLF, Oper2LLF, HL93IMP
*                  L:Legal/NRL            Use LegalLLF, LegalIMP
*                  P:Permit               Use PermitLLF, LegalIMP (this type replaces the old OverLoad Flag)
*                  E:Emergency Vehicle    Use EVehicleLLF, LegalIMP, Permit lane-load distribution factor
*                  Blank                  Use input on card.
* "Rating type" and "Negative Only" input only needed on first line of combinations with multiple lines.
*
* Combinations that are coded with rating types H,L or P will have a special loading combination automatically
*    generated. These load combinations will have the names: "HL93_Combined", "Legal_Combined", and "Permit_Combined".
*    These special load combinations will be an envelope of all the load combinations with the same rating type.
*
* FOR LRFR NEGative ONLY:
*                  N: use both positive and negative moment and shear envelope (default)
*                  Y: use for negative moment envelope and interior reaction only
*
* FOR LFR (FHWA or STD): the distribution factor, DF, was moved to CARD 1005.
*                        DO NOT USE LANE MULT for DF or LFR and LRFR will result in inconsistent values
*                        when used on the same input!
*
* RESERVED NAMES: Do NOT use these combination names or else they may be changed by the auto-LRFD load generator
*      HL-93_14_14
*      HL-93_14_22
*      HL-93_14_30
*      HL-93_tandem
*      HL-93_14_14_train
*      NRL
*      LEGAL_LANE
*      LEGAL_LANE_2
*      TYPE_3
*      TYPE_3S2
*      TYPE_3-3
*      OVERLOAD_1
*      OVERLOAD_2
*      EV2
*      EV3
*      HL-93
*
                                        --- MULTIPLIERS ---------  ADDED    TRUCK LOAD - A   TRUCK LOAD - B   LANE LOAD
LOAD                                    LANE      LIVE     STD     UNIF.    --------------   --------------   ------------------------   FOR
COMB  MBR                               LOAD      LOAD     IMPACT  LOAD     TRUCK    LANE    TRUCK    LANE      LC     LOAD      LANE   RATING NEG
#      #     LOAD COMBINATION TITLE     REDUC.    FACTOR   FACTOR  (KPF)    NUMBER   MULT    NUMBER   MULT    NUMBER   (KPF)     MULT    TYPE ONLY
==   ===     =========================  ===.==    ===.==   ===.==  ===.==     ==     ==.==     ==     ==.==     ==    ==.===     ==.==     =    =
 1     1     HL-93_14_14                  1.00      1.35     1.33    0.00      1      1.00      6      0.64                                H    N
 1     2                                  1.00      1.35     1.33    0.00      1      1.00      6      0.64
 1     3                                  1.00      1.35     1.33    0.00      1      1.00      6      0.64
 2     1     HL-93_14_22                  1.00      1.35     1.33    0.00      2      1.00      6      0.64                                H    N
 2     2                                  1.00      1.35     1.33    0.00      2      1.00      6      0.64
 2     3                                  1.00      1.35     1.33    0.00      2      1.00      6      0.64
 3     1     HL-93_14_30                  1.00      1.35     1.33    0.00      3      1.00      6      0.64                                H    N
 3     2                                  1.00      1.35     1.33    0.00      3      1.00      6      0.64
 3     3                                  1.00      1.35     1.33    0.00      3      1.00      6      0.64
 4     1     HL-93_tandem                 1.00      1.35     1.33    0.00      4      1.00      6      0.64                                H    N
 4     2                                  1.00      1.35     1.33    0.00      4      1.00      6      0.64
 4     3                                  1.00      1.35     1.33    0.00      4      1.00      6      0.64
 5     1     HL-93_14_14_train            1.00      1.35     1.33    0.00      5      1.00      6      0.58                                H    Y
 5     2                                  1.00      1.35     1.33    0.00      5      1.00      6      0.58
 5     3                                  1.00      1.35     1.33    0.00      5      1.00      6      0.58
 6     1     NRL                          1.00      1.45     1.10    0.00     10      1.00                                                 L    N
 6     2                                  1.00      1.45     1.10    0.00     10      1.00
 6     3                                  1.00      1.45     1.10    0.00     10      1.00
 7     1     LEGAL_LANE                   1.00      1.45     1.10    0.00      6      0.20     11      1.00                                L    N
 7     2                                  1.00      1.45     1.10    0.00      6      0.20     11      1.00
 7     3                                  1.00      1.45     1.10    0.00      6      0.20     11      1.00
 8     1     LEGAL_LANE_2                 1.00      1.45     1.10    0.00      6      0.20     12      1.00                                L    N
 8     2                                  1.00      1.45     1.10    0.00      6      0.20     12      1.00
 8     3                                  1.00      1.45     1.10    0.00      6      0.20     12      1.00
 9     1     TYPE_3                       1.00      1.45     1.10    0.00      7      1.00                                                 L    N
 9     2                                  1.00      1.45     1.10    0.00      7      1.00
 9     3                                  1.00      1.45     1.10    0.00      7      1.00
10     1     TYPE_3S2                     1.00      1.45     1.10    0.00      8      1.00                                                 L    N
10     2                                  1.00      1.45     1.10    0.00      8      1.00
10     3                                  1.00      1.45     1.10    0.00      8      1.00
11     1     TYPE_3-3                     1.00      1.45     1.10    0.00      9      1.00                                                 L    N
11     2                                  1.00      1.45     1.10    0.00      9      1.00
11     3                                  1.00      1.45     1.10    0.00      9      1.00
12     1     OVERLOAD_1                   1.00      1.20     1.10    0.00     13      1.00                                                 P    N
12     2                                  1.00      1.20     1.10    0.00     13      1.00
12     3                                  1.00      1.20     1.10    0.00     13      1.00
13     1     OVERLOAD_2                   1.00      1.20     1.10    0.00     14      1.00                                                 P    N
13     2                                  1.00      1.20     1.10    0.00     14      1.00
13     3                                  1.00      1.20     1.10    0.00     14      1.00
14     1     EV2                          1.00      1.30     1.10    0.00     15      1.00                                                 E    N
14     2                                  1.00      1.30     1.10    0.00     15      1.00
14     3                                  1.00      1.30     1.10    0.00     15      1.00
15     1     EV3                          1.00      1.30     1.10    0.00     16      1.00                                                 E    N
15     2                                  1.00      1.30     1.10    0.00     16      1.00
15     3                                  1.00      1.30     1.10    0.00     16      1.00

* =============================================================================================================================
# [END DATA ENTRY]             <End of standard "BRIDG" data entry blocks>
= ==================================================================================================================================

* =============================================================================================================================
# [AR:COMP.TRAN.SECT]    5100  <Composite Transformed Section Properties>
* ==================================================================================================================================
*
*  Definition of terms:
*      Izz       --- Moment of Inertia.
*      S_top     --- Section Modulus to top fiber.
*      S_top grd --- Section Modulus to top fiber of girder.
*      S_bot     --- Section Modulus for bottom fiber.
*      NA        --- Neutral axis from top slab.
*      e         --- Composite Modulus of Elasticity.
*      f'c       --- Composite concrete strength.
*
                                                      S_top
MBR  DIST   DEPTH   NA     AREA      Izz     S_top     grd     S_bot     e     f'c
  #  (ft)   (ft)   (ft)   (ft**2)  (ft**4)  (ft**3)  (ft**3)  (ft**3)  (ksi)  (ksi)
===  ===.=  ==.==  ==.==  ====.==  ====.==  ====.==  ====.==  ====.==  =====  ==.==
  1    0.0   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  1    2.0   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  1    2.5   4.08   1.32     8.33    13.89   -10.53   -18.88     5.02   4933   6.00
  1    3.0   4.08   1.29     8.11    13.56   -10.48   -19.09     4.86   4933   6.00
  1    3.5   4.08   1.27     7.89    13.22   -10.44   -19.35     4.69   4933   6.00
  1    4.0   4.08   1.24     7.67    12.87   -10.40   -19.65     4.52   4933   6.00
  1    4.5   4.08   1.21     7.46    12.52   -10.36   -20.02     4.36   4933   6.00
  1    5.0   4.08   1.18     7.24    12.16   -10.32   -20.45     4.19   4933   6.00
  1    5.5   4.08   1.15     7.02    11.79   -10.29   -20.98     4.01   4933   6.00
  1    6.0   4.08   1.11     6.81    11.41   -10.27   -21.62     3.84   4933   6.00
  1    6.5   4.08   1.08     6.59    11.02   -10.25   -22.41     3.66   4933   6.00
  1   39.0   4.08   1.08     6.59    11.02   -10.25   -22.41     3.66   4933   6.00
  1   39.5   4.08   1.11     6.81    11.41   -10.27   -21.62     3.84   4933   6.00
  1   40.0   4.08   1.15     7.02    11.79   -10.29   -20.98     4.01   4933   6.00
  1   40.5   4.08   1.18     7.24    12.16   -10.32   -20.45     4.19   4933   6.00
  1   41.0   4.08   1.21     7.46    12.52   -10.36   -20.02     4.36   4933   6.00
  1   41.5   4.08   1.24     7.67    12.87   -10.40   -19.65     4.52   4933   6.00
  1   42.0   4.08   1.27     7.89    13.22   -10.44   -19.35     4.69   4933   6.00
  1   42.5   4.08   1.29     8.11    13.56   -10.48   -19.09     4.86   4933   6.00
  1   43.0   4.08   1.32     8.33    13.89   -10.53   -18.88     5.02   4933   6.00
  1   43.3   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  2    0.0   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  2    3.5   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  2    4.0   4.08   1.32     8.33    13.89   -10.53   -18.88     5.02   4933   6.00
  2    4.5   4.08   1.29     8.11    13.56   -10.48   -19.09     4.86   4933   6.00
  2    5.0   4.08   1.27     7.89    13.22   -10.44   -19.35     4.69   4933   6.00
  2    5.5   4.08   1.24     7.67    12.87   -10.40   -19.65     4.52   4933   6.00
  2    6.0   4.08   1.21     7.46    12.52   -10.36   -20.02     4.36   4933   6.00
  2    6.5   4.08   1.18     7.24    12.16   -10.32   -20.45     4.19   4933   6.00
  2    7.0   4.08   1.15     7.02    11.79   -10.29   -20.98     4.01   4933   6.00
  2    7.5   4.08   1.11     6.81    11.41   -10.27   -21.62     3.84   4933   6.00
  2    8.0   4.08   1.08     6.59    11.02   -10.25   -22.41     3.66   4933   6.00
  2   42.0   4.08   1.08     6.59    11.02   -10.25   -22.41     3.66   4933   6.00
  2   42.5   4.08   1.11     6.81    11.41   -10.27   -21.62     3.84   4933   6.00
  2   43.0   4.08   1.15     7.02    11.79   -10.29   -20.98     4.01   4933   6.00
  2   43.5   4.08   1.18     7.24    12.16   -10.32   -20.45     4.19   4933   6.00
  2   44.0   4.08   1.21     7.46    12.52   -10.36   -20.02     4.36   4933   6.00
  2   44.5   4.08   1.24     7.67    12.87   -10.40   -19.65     4.52   4933   6.00
  2   45.0   4.08   1.27     7.89    13.22   -10.44   -19.35     4.69   4933   6.00
  2   45.5   4.08   1.29     8.11    13.56   -10.48   -19.09     4.86   4933   6.00
  2   46.0   4.08   1.32     8.33    13.89   -10.53   -18.88     5.02   4933   6.00
  2   46.5   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  3    0.0   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  3    3.5   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00
  3    4.0   4.08   1.32     8.33    13.89   -10.53   -18.88     5.02   4933   6.00
  3    4.5   4.08   1.29     8.11    13.56   -10.48   -19.09     4.86   4933   6.00
  3    5.0   4.08   1.27     7.89    13.22   -10.44   -19.35     4.69   4933   6.00
  3    5.5   4.08   1.24     7.67    12.87   -10.40   -19.65     4.52   4933   6.00
  3    6.0   4.08   1.21     7.46    12.52   -10.36   -20.02     4.36   4933   6.00
  3    6.5   4.08   1.18     7.24    12.16   -10.32   -20.45     4.19   4933   6.00
  3    7.0   4.08   1.15     7.02    11.79   -10.29   -20.98     4.01   4933   6.00
  3    7.5   4.08   1.11     6.81    11.41   -10.27   -21.62     3.84   4933   6.00
  3    8.0   4.08   1.08     6.59    11.02   -10.25   -22.41     3.66   4933   6.00
  3   35.0   4.08   1.08     6.59    11.02   -10.25   -22.41     3.66   4933   6.00
  3   35.5   4.08   1.11     6.81    11.41   -10.27   -21.62     3.84   4933   6.00
  3   36.0   4.08   1.15     7.02    11.79   -10.29   -20.98     4.01   4933   6.00
  3   36.5   4.08   1.18     7.24    12.16   -10.32   -20.45     4.19   4933   6.00
  3   37.0   4.08   1.21     7.46    12.52   -10.36   -20.02     4.36   4933   6.00
  3   37.5   4.08   1.24     7.67    12.87   -10.40   -19.65     4.52   4933   6.00
  3   38.0   4.08   1.27     7.89    13.22   -10.44   -19.35     4.69   4933   6.00
  3   38.5   4.08   1.29     8.11    13.56   -10.48   -19.09     4.86   4933   6.00
  3   39.0   4.08   1.32     8.33    13.89   -10.53   -18.88     5.02   4933   6.00
  3   39.5   4.08   1.34     8.56    14.21   -10.58   -18.70     5.19   4933   6.00

* =============================================================================================================================
# [AR:GIRDER SECT PROP]  5101  <Non-Composite Girder Section Properties>
* ==================================================================================================================================
*
*  Definition of terms:
*      Izz    --- Moment of Inertia.
*      S_top  --- Section modulus for top fiber.
*      S_bot  --- Section modulus for bottom fiber.
*      NA     --- Neutral axis from top of girder.
*
MBR  DIST   DEPTH   NA     AREA      Izz     S_top    S_bot     e     f'c
 #   (ft)   (ft)   (ft)   (ft**2)  (ft**4)  (ft**3)  (ft**3)  (ksi)  (ksi)
===  ===.=  ==.==  ==.==  ====.==  ====.==  ====.==  ====.==  =====  ==.==
  1    0.0   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  1    2.0   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  1    2.5   3.50   1.82     4.05     4.45    -2.44     2.65   4933   6.00
  1    3.0   3.50   1.83     3.83     4.32    -2.36     2.59   4933   6.00
  1    3.5   3.50   1.84     3.61     4.18    -2.27     2.52   4933   6.00
  1    4.0   3.50   1.85     3.39     4.05    -2.19     2.46   4933   6.00
  1    4.5   3.50   1.87     3.17     3.92    -2.10     2.40   4933   6.00
  1    5.0   3.50   1.88     2.95     3.78    -2.01     2.34   4933   6.00
  1    5.5   3.50   1.90     2.74     3.65    -1.92     2.28   4933   6.00
  1    6.0   3.50   1.92     2.52     3.51    -1.83     2.23   4933   6.00
  1    6.5   3.50   1.95     2.31     3.38    -1.73     2.18   4933   6.00
  1   39.0   3.50   1.95     2.31     3.38    -1.73     2.18   4933   6.00
  1   39.5   3.50   1.92     2.52     3.51    -1.83     2.23   4933   6.00
  1   40.0   3.50   1.90     2.74     3.65    -1.92     2.28   4933   6.00
  1   40.5   3.50   1.88     2.95     3.78    -2.01     2.34   4933   6.00
  1   41.0   3.50   1.87     3.17     3.92    -2.10     2.40   4933   6.00
  1   41.5   3.50   1.85     3.39     4.05    -2.19     2.46   4933   6.00
  1   42.0   3.50   1.84     3.61     4.18    -2.27     2.52   4933   6.00
  1   42.5   3.50   1.83     3.83     4.32    -2.36     2.59   4933   6.00
  1   43.0   3.50   1.82     4.05     4.45    -2.44     2.65   4933   6.00
  1   43.3   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  2    0.0   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  2    3.5   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  2    4.0   3.50   1.82     4.05     4.45    -2.44     2.65   4933   6.00
  2    4.5   3.50   1.83     3.83     4.32    -2.36     2.59   4933   6.00
  2    5.0   3.50   1.84     3.61     4.18    -2.27     2.52   4933   6.00
  2    5.5   3.50   1.85     3.39     4.05    -2.19     2.46   4933   6.00
  2    6.0   3.50   1.87     3.17     3.92    -2.10     2.40   4933   6.00
  2    6.5   3.50   1.88     2.95     3.78    -2.01     2.34   4933   6.00
  2    7.0   3.50   1.90     2.74     3.65    -1.92     2.28   4933   6.00
  2    7.5   3.50   1.92     2.52     3.51    -1.83     2.23   4933   6.00
  2    8.0   3.50   1.95     2.31     3.38    -1.73     2.18   4933   6.00
  2   42.0   3.50   1.95     2.31     3.38    -1.73     2.18   4933   6.00
  2   42.5   3.50   1.92     2.52     3.51    -1.83     2.23   4933   6.00
  2   43.0   3.50   1.90     2.74     3.65    -1.92     2.28   4933   6.00
  2   43.5   3.50   1.88     2.95     3.78    -2.01     2.34   4933   6.00
  2   44.0   3.50   1.87     3.17     3.92    -2.10     2.40   4933   6.00
  2   44.5   3.50   1.85     3.39     4.05    -2.19     2.46   4933   6.00
  2   45.0   3.50   1.84     3.61     4.18    -2.27     2.52   4933   6.00
  2   45.5   3.50   1.83     3.83     4.32    -2.36     2.59   4933   6.00
  2   46.0   3.50   1.82     4.05     4.45    -2.44     2.65   4933   6.00
  2   46.5   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  3    0.0   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  3    3.5   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00
  3    4.0   3.50   1.82     4.05     4.45    -2.44     2.65   4933   6.00
  3    4.5   3.50   1.83     3.83     4.32    -2.36     2.59   4933   6.00
  3    5.0   3.50   1.84     3.61     4.18    -2.27     2.52   4933   6.00
  3    5.5   3.50   1.85     3.39     4.05    -2.19     2.46   4933   6.00
  3    6.0   3.50   1.87     3.17     3.92    -2.10     2.40   4933   6.00
  3    6.5   3.50   1.88     2.95     3.78    -2.01     2.34   4933   6.00
  3    7.0   3.50   1.90     2.74     3.65    -1.92     2.28   4933   6.00
  3    7.5   3.50   1.92     2.52     3.51    -1.83     2.23   4933   6.00
  3    8.0   3.50   1.95     2.31     3.38    -1.73     2.18   4933   6.00
  3   35.0   3.50   1.95     2.31     3.38    -1.73     2.18   4933   6.00
  3   35.5   3.50   1.92     2.52     3.51    -1.83     2.23   4933   6.00
  3   36.0   3.50   1.90     2.74     3.65    -1.92     2.28   4933   6.00
  3   36.5   3.50   1.88     2.95     3.78    -2.01     2.34   4933   6.00
  3   37.0   3.50   1.87     3.17     3.92    -2.10     2.40   4933   6.00
  3   37.5   3.50   1.85     3.39     4.05    -2.19     2.46   4933   6.00
  3   38.0   3.50   1.84     3.61     4.18    -2.27     2.52   4933   6.00
  3   38.5   3.50   1.83     3.83     4.32    -2.36     2.59   4933   6.00
  3   39.0   3.50   1.82     4.05     4.45    -2.44     2.65   4933   6.00
  3   39.5   3.50   1.82     4.27     4.59    -2.52     2.72   4933   6.00

* =============================================================================================================================
# [AR:CABLE DATA]        5200  <Prestress Cable Info at Member Tenth Points>
* ==================================================================================================================================
*
                               LEFT    RIGHT                               CABLE
                              ANCHOR   ANCHOR             LUMP    FINAL    HEIGHT
                     JACKING   SET      SET     FRICTION  SUM     EFFECT   FROM      PRIMARY
MBR     DIST  CABLE  FORCE    LOSSES   LOSSES   LOSSES   LOSSES   FORCE    TOP SLAB  MOMENT
 #  TP  (ft)  PATH   (kips)   (kips)   (kips)   (kips)   (kips)   (kips)    (ft)     (k-ft)
=== ==  ===.=  ==    =====.=  =====.=  =====.=  =====.=  =====.=  =====.=  ===.==    ========.=
  1  0    0.0   1      289.0      0.0      0.0      0.0     62.7      0.0    3.90          -0.0
  1  1    4.7   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -329.0
  1  2    9.3   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -310.5
  1  3   14.0   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -310.5
  1  4   18.6   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -310.5
  1  5   23.3   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -310.5
  1  6   27.9   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -310.5
  1  7   32.6   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -310.5
  1  8   37.2   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -310.5
  1  9   41.9   1      289.0      0.0      0.0      0.0     62.7    226.3    3.90        -334.5
  1 10   46.5   1      289.0      0.0      0.0      0.0     62.7      0.0    3.90          -0.0
 
  1  0    0.0   2      145.0      0.0      0.0      0.0     31.6      0.0    0.89           0.0
  1  1    4.7   2      145.0      0.0      0.0      0.0     31.6    113.4    1.53         103.0
  1  2    9.3   2      145.0      0.0      0.0      0.0     31.6    113.4    2.24          32.5
  1  3   14.0   2      145.0      0.0      0.0      0.0     31.6    113.4    2.88         -39.3
  1  4   18.6   2      145.0      0.0      0.0      0.0     31.6    113.4    3.09         -63.8
  1  5   23.3   2      145.0      0.0      0.0      0.0     31.6    113.4    3.09         -63.8
  1  6   27.9   2      145.0      0.0      0.0      0.0     31.6    113.4    3.09         -63.8
  1  7   32.6   2      145.0      0.0      0.0      0.0     31.6    113.4    2.88         -39.3
  1  8   37.2   2      145.0      0.0      0.0      0.0     31.6    113.4    2.24          32.5
  1  9   41.9   2      145.0      0.0      0.0      0.0     31.6    113.4    1.53         100.3
  1 10   46.5   2      145.0      0.0      0.0      0.0     31.6      0.0    0.89           0.0
 
  2  0    0.0   3      289.0      0.0      0.0      0.0     67.3      0.0    3.90          -0.0
  2  1    5.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -327.7
  2  2   10.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -304.2
  2  3   15.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -304.2
  2  4   20.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -304.2
  2  5   25.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -304.2
  2  6   30.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -304.2
  2  7   35.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -304.2
  2  8   40.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -304.2
  2  9   45.0   3      289.0      0.0      0.0      0.0     67.3    221.7    3.90        -327.7
  2 10   50.0   3      289.0      0.0      0.0      0.0     67.3      0.0    3.90          -0.0
 
  2  0    0.0   4      202.0      0.0      0.0      0.0     47.1      0.0    0.93           0.0
  2  1    5.0   4      202.0      0.0      0.0      0.0     47.1    154.9    1.63         122.1
  2  2   10.0   4      202.0      0.0      0.0      0.0     47.1    154.9    2.33          31.6
  2  3   15.0   4      202.0      0.0      0.0      0.0     47.1    154.9    3.02         -75.3
  2  4   20.0   4      202.0      0.0      0.0      0.0     47.1    154.9    3.25        -111.9
  2  5   25.0   4      202.0      0.0      0.0      0.0     47.1    154.9    3.25        -111.9
  2  6   30.0   4      202.0      0.0      0.0      0.0     47.1    154.9    3.25        -111.9
  2  7   35.0   4      202.0      0.0      0.0      0.0     47.1    154.9    3.02         -74.6
  2  8   40.0   4      202.0      0.0      0.0      0.0     47.1    154.9    2.31          34.0
  2  9   45.0   4      202.0      0.0      0.0      0.0     47.1    154.9    1.60         126.3
  2 10   50.0   4      202.0      0.0      0.0      0.0     47.1      0.0    0.89           0.0
 
  3  0    0.0   5      232.0      0.0      0.0      0.0     45.1      0.0    3.93          -0.0
  3  1    4.2   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -285.2
  3  2    8.3   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -262.0
  3  3   12.5   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -262.0
  3  4   16.6   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -262.0
  3  5   20.8   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -262.0
  3  6   24.9   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -262.0
  3  7   29.1   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -262.0
  3  8   33.2   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -262.0
  3  9   37.4   5      232.0      0.0      0.0      0.0     45.1    186.9    3.93        -279.8
  3 10   41.5   5      232.0      0.0      0.0      0.0     45.1      0.0    3.93          -0.0
 
  3  0    0.0   6      116.0      0.0      0.0      0.0     22.6      0.0    0.82           0.0
  3  1    4.2   6      116.0      0.0      0.0      0.0     22.6     93.4    1.50          83.5
  3  2    8.3   6      116.0      0.0      0.0      0.0     22.6     93.4    2.26          24.9
  3  3   12.5   6      116.0      0.0      0.0      0.0     22.6     93.4    2.94         -37.5
  3  4   16.6   6      116.0      0.0      0.0      0.0     22.6     93.4    3.16         -59.1
  3  5   20.8   6      116.0      0.0      0.0      0.0     22.6     93.4    3.16         -59.1
  3  6   24.9   6      116.0      0.0      0.0      0.0     22.6     93.4    3.16         -59.1
  3  7   29.1   6      116.0      0.0      0.0      0.0     22.6     93.4    2.94         -37.5
  3  8   33.2   6      116.0      0.0      0.0      0.0     22.6     93.4    2.26          24.9
  3  9   37.4   6      116.0      0.0      0.0      0.0     22.6     93.4    1.50          86.2
  3 10   41.5   6      116.0      0.0      0.0      0.0     22.6      0.0    0.82           0.0
 

* =============================================================================================================================
# [AR:STRAIN COMPAT.]    5201  <Strain Compatibility Info at Member Tenth Points>
* ==================================================================================================================================
*
*
                                                  ----------- STRESSES AND STRAINS AT FAILURE ----------
                     INITIAL  INITIAL   INITIAL   -POSITIVE MOMENT ANALYSIS-  -NEGATIVE MOMENT ANALYSIS-
                     CABLE    CABLE     CONCRETE   CABLE    CABLE    NEUTRAL   CABLE    CABLE    NEUTRAL
MBR     DIST  CABLE  STRESS   STRAIN    STRAIN     STRESS   STRAIN   AXIS      STRESS   STRAIN   AXIS
 #  TP  (ft)  PATH   (ksi)    (in/in)   (in/in)    (ksi)    (ksi)    (ft)      (ksi)    (ksi)    (ft)
=== ==  ===.=  ==    ===.=    =.======  =.======   ===.=   =.======  ===.==    ===.=   =.======  ===.==
  1  0    0.0   1      0.0    0.000000  0.000000   270.0   4.70E+01    0.00      0.0  -0.001009    3.81    189.00
  1  1    4.7   1    147.9    0.005189 -0.000272   267.2   0.113801    0.11     13.2   0.003660    3.63    189.00
  1  2    9.3   1    147.9    0.005189 -0.000316   265.7   0.074568    0.16      0.0   0.003619    3.60    189.00
  1  3   14.0   1    147.9    0.005189 -0.000316   265.7   0.074348    0.16      0.1   0.003645    3.61    189.00
  1  4   18.6   1    147.9    0.005189 -0.000316   265.7   0.074348    0.16      2.4   0.003655    3.61    189.00
  1  5   23.3   1    147.9    0.005189 -0.000316   265.7   0.074348    0.16      2.4   0.003655    3.61    189.00
  1  6   27.9   1    147.9    0.005189 -0.000316   265.7   0.074348    0.16      0.0   0.003606    3.59    189.00
  1  7   32.6   1    147.9    0.005189 -0.000316   265.7   0.074348    0.16      0.0   0.003588    3.58    189.00
  1  8   37.2   1    147.9    0.005189 -0.000316   265.7   0.074568    0.16      0.0   0.003465    3.52    189.00
  1  9   41.9   1    147.9    0.005189 -0.000255   267.2   0.113783    0.11      0.0   0.003425    3.53    189.00
  1 10   46.5   1      0.0    0.000000  0.000000   270.0   4.70E+01    0.00      0.0  -0.001752    3.65    189.00
 
  1  0    0.0   2      0.0    0.000000  0.000000   270.0   1.08E+01    0.00    261.3   0.032293    3.81    189.00
  1  1    4.7   2    147.3    0.005169 -0.000084   263.0   0.045955    0.11    251.9   0.019238    3.63    189.00
  1  2    9.3   2    147.3    0.005169 -0.000072   262.6   0.043630    0.16    243.0   0.013644    3.60    189.00
  1  3   14.0   2    147.3    0.005169 -0.000074   264.2   0.055263    0.16    229.6   0.009863    3.61    189.00
  1  4   18.6   2    147.3    0.005169 -0.000084   264.6   0.059187    0.16    221.3   0.008578    3.61    189.00
  1  5   23.3   2    147.3    0.005169 -0.000084   264.6   0.059187    0.16    221.3   0.008578    3.61    189.00
  1  6   27.9   2    147.3    0.005169 -0.000084   264.6   0.059187    0.16    219.2   0.008308    3.59    189.00
  1  7   32.6   2    147.3    0.005169 -0.000074   264.2   0.055263    0.16    227.5   0.009482    3.58    189.00
  1  8   37.2   2    147.3    0.005169 -0.000072   262.6   0.043630    0.16    238.7   0.012067    3.52    189.00
  1  9   41.9   2    147.3    0.005169 -0.000074   263.0   0.045945    0.11    247.9   0.016151    3.53    189.00
  1 10   46.5   2      0.0    0.000000  0.000000   270.0   1.08E+01    0.00    256.1   0.019119    3.65    189.00
 
  2  0    0.0   3      0.0    0.000000  0.000000   270.0   4.70E+01    0.00      0.0  -0.001752    3.65    189.00
  2  1    5.0   3    144.9    0.005084 -0.000250   266.6   0.091659    0.13      0.0   0.003162    3.43    189.00
  2  2   10.0   3    144.9    0.005084 -0.000309   265.2   0.066406    0.18      0.0   0.003221    3.43    189.00
  2  3   15.0   3    144.9    0.005084 -0.000309   265.2   0.066232    0.18      0.0   0.003353    3.52    189.00
  2  4   20.0   3    144.9    0.005084 -0.000309   265.2   0.066059    0.18      0.0   0.003400    3.55    189.00
  2  5   25.0   3    144.9    0.005084 -0.000309   265.2   0.066059    0.18      0.0   0.003400    3.55    189.00
  2  6   30.0   3    144.9    0.005084 -0.000309   265.2   0.066059    0.18      0.0   0.003400    3.55    189.00
  2  7   35.0   3    144.9    0.005084 -0.000309   265.2   0.066232    0.18      0.0   0.003353    3.52    189.00
  2  8   40.0   3    144.9    0.005084 -0.000309   265.2   0.066406    0.18      0.0   0.003221    3.43    189.00
  2  9   45.0   3    144.9    0.005084 -0.000250   266.6   0.091659    0.13      0.0   0.003164    3.43    189.00
  2 10   50.0   3      0.0    0.000000  0.000000   270.0   4.70E+01    0.00      0.0  -0.001752    3.65    189.00
 
  2  0    0.0   4      0.0    0.000000  0.000000   270.0   1.12E+01    0.00    255.9   0.018842    3.65    189.00
  2  1    5.0   4    144.8    0.005080 -0.000093   261.7   0.039461    0.13    242.7   0.013464    3.43    189.00
  2  2   10.0   4    144.8    0.005080 -0.000096   261.9   0.040313    0.18    231.9   0.010265    3.43    189.00
  2  3   15.0   4    144.8    0.005080 -0.000109   263.8   0.051606    0.18    215.7   0.007855    3.52    189.00
  2  4   20.0   4    144.8    0.005080 -0.000128   264.2   0.055272    0.18    195.3   0.006851    3.55    189.00
  2  5   25.0   4    144.8    0.005080 -0.000128   264.2   0.055272    0.18    195.3   0.006851    3.55    189.00
  2  6   30.0   4    144.8    0.005080 -0.000128   264.2   0.055272    0.18    195.3   0.006851    3.55    189.00
  2  7   35.0   4    144.8    0.005080 -0.000109   263.8   0.051541    0.18    215.9   0.007876    3.52    189.00
  2  8   40.0   4    144.8    0.005080 -0.000097   261.9   0.040051    0.18    232.3   0.010339    3.43    189.00
  2  9   45.0   4    144.8    0.005080 -0.000095   261.6   0.038822    0.13    243.1   0.013630    3.43    189.00
  2 10   50.0   4      0.0    0.000000  0.000000   270.0   1.08E+01    0.00    256.1   0.019119    3.65    189.00
 
  3  0    0.0   5      0.0    0.000000  0.000000   270.0   4.73E+01    0.00      0.0  -0.001960    3.65    189.00
  3  1    4.2   5    153.2    0.005374 -0.000203   268.0   0.158322    0.08      0.0   0.003465    3.58    189.00
  3  2    8.3   5    153.2    0.005374 -0.000267   266.6   0.093343    0.13      0.0   0.003506    3.56    189.00
  3  3   12.5   5    153.2    0.005374 -0.000267   266.6   0.093343    0.13      0.0   0.003627    3.63    189.00
  3  4   16.6   5    153.2    0.005374 -0.000267   266.6   0.093343    0.13      0.0   0.003640    3.63    189.00
  3  5   20.8   5    153.2    0.005374 -0.000267   266.6   0.093343    0.13      0.0   0.003640    3.63    189.00
  3  6   24.9   5    153.2    0.005374 -0.000267   266.6   0.093343    0.13      0.0   0.003696    3.66    189.00
  3  7   29.1   5    153.2    0.005374 -0.000267   266.6   0.093343    0.13      0.0   0.003681    3.65    189.00
  3  8   33.2   5    153.2    0.005374 -0.000267   266.6   0.093343    0.13      0.0   0.003658    3.64    189.00
  3  9   37.4   5    153.2    0.005374 -0.000223   268.0   0.158342    0.08      4.1   0.003755    3.69    189.00
  3 10   41.5   5      0.0    0.000000  0.000000   270.0   4.73E+01    0.00      0.0  -0.001340    3.81    189.00
 
  3  0    0.0   6      0.0    0.000000  0.000000   270.0   9.907648    0.00    256.4   0.019604    3.65    189.00
  3  1    4.2   6    153.2    0.005374 -0.000056   264.8   0.061825    0.08    249.9   0.017733    3.58    189.00
  3  2    8.3   6    153.2    0.005374 -0.000059   264.1   0.054579    0.13    240.7   0.012937    3.56    189.00
  3  3   12.5   6    153.2    0.005374 -0.000063   265.5   0.070187    0.13    229.1   0.009962    3.63    189.00
  3  4   16.6   6    153.2    0.005374 -0.000073   265.8   0.075393    0.13    219.7   0.008572    3.63    189.00
  3  5   20.8   6    153.2    0.005374 -0.000073   265.8   0.075393    0.13    219.7   0.008572    3.63    189.00
  3  6   24.9   6    153.2    0.005374 -0.000073   265.8   0.075393    0.13    222.4   0.008915    3.66    189.00
  3  7   29.1   6    153.2    0.005374 -0.000063   265.5   0.070187    0.13    231.2   0.010378    3.65    189.00
  3  8   33.2   6    153.2    0.005374 -0.000059   264.1   0.054579    0.13    245.1   0.014782    3.64    189.00
  3  9   37.4   6    153.2    0.005374 -0.000066   264.8   0.061836    0.08    254.6   0.022374    3.69    189.00
  3 10   41.5   6      0.0    0.000000  0.000000   270.0   9.907648    0.00    261.5   0.033067    3.81    189.00
 

* =============================================================================================================================
# [AR:ULTIMATE CAPACITY] 5202  <Span Ultimate Capacities>
* ==================================================================================================================================
*  Values are printed for 1/10 points ( TP = 0 thru 10 )
*  Values are for nearest integration point to actual tenth point.
*  Shear capacities are listed by Load Combination. If more then 5 Load Combinations are active, then continued on next line.
*
                                ------------- SHEAR CAPACITY BY LOAD COMBINATION NUMBER ---------------------------
                -- MOMENT --    -- 1 (6,...) --  -- 2 (7,...) --  -- 3 (8,...) --  -- 4 (9,...) --  -- 5 (10,..) --
SPAN    DIST    POS     NEG      POS     NEG      POS     NEG      POS     NEG      POS     NEG      POS     NEG
 #  TP  (ft)   (k-ft)  (k-ft)   (kips)  (kips)   (kips)  (kips)   (kips)  (kips)   (kips)  (kips)   (kips)  (kips)
=== ==  ===.=  ======  ======   ======= =======  ======= =======  ======= =======  ======= =======  ======= =======
  1  0    0.0     434     782       353    -353      353    -353      353    -353      353    -353      353    -353
                                    353    -353      353    -353      353    -353      353    -353      353    -353
                                    353    -353      353    -353      353    -353      353    -353      353    -353
                                    353    -353
  1  1    4.7    1208    1061       211    -182      211    -182      211    -182      211    -182      211    -182
                                    147    -182      205    -181      205    -181      202    -180      203    -181
                                    204    -181      204    -181      203    -181      188    -180      109    -179
                                    101    -178
  1  2    9.3    1984    1058       158    -129      158    -129      158    -129      158    -129      158    -129
                                    145    -126      150    -126      150    -127      147    -124      148    -124
                                    149    -125      149    -126      148    -126      146    -123      142    -120
                                    135    -117
  1  3   14.0    2116     942       166    -137      166    -137      166    -137      166    -137      166    -137
                                    152    -132      158    -132      158    -132      154    -129      155    -129
                                    157    -130      156    -131      156    -131      153    -128      148    -124
                                    124    -119
  1  4   18.6    2175     892       154    -154      154    -154      154    -154      154    -154      154    -154
                                    142    -145      146    -148      146    -149      142    -145      143    -145
                                    145    -146      145    -148      144    -147      141    -144      137    -139
                                    111    -134
  1  5   23.3    2175     892       154    -154      154    -154      154    -154      154    -154      154    -154
                                    144    -141      148    -146      148    -147      144    -143      144    -143
                                    147    -144      146    -145      145    -146      143    -142      138    -137
                                    131    -123
  1  6   27.9    2175     963       154    -154      154    -154      154    -154      154    -154      154    -154
                                    149    -140      151    -146      150    -147      147    -142      149    -144
                                    150    -144      150    -145      152    -147      146    -141      142    -137
                                    137    -128
  1  7   32.5    2131    1000       139    -167      139    -167      139    -167      139    -167      139    -167
                                    137    -155      137    -160      137    -161      134    -157      137    -160
                                    137    -158      136    -159      138    -161      133    -156      130    -152
                                    125    -148
  1  8   37.2    1998    1258       131    -160      131    -160      131    -160      131    -160      131    -160
                                    131    -150      131    -154      131    -155      129    -151      131    -154
                                    131    -153      131    -153      131    -155      128    -151      127    -147
                                    123    -145
  1  9   41.8    1352    1415       543    -572      543    -572      543    -572      543    -572      543    -572
                                    543    -544      543    -562      543    -562      543    -559      543    -559
                                    543    -560      543    -560      543    -462      543    -558      543    -454
                                    538    -283
  1 10   46.5     434    1258       565    -572      565    -572      565    -572      565    -572      565    -572
                                    565    -492      565    -522      565    -520      565    -512      565    -512
                                    565    -516      565    -515      565    -488      565    -509      565    -485
                                    300    -451
 
  2  0   46.5     434    1232       561    -561      561    -561      561    -561      561    -561      561    -561
                                    488    -573      516    -567      509    -567      506    -568      507    -568
                                    511    -567      509    -568      479    -569      503    -569      481    -573
                                    446    -353
  2  1   51.5    1428    1518       248    -209      248    -209      248    -209      248    -209      248    -209
                                    236    -209      241    -209      241    -209      239    -209      240    -209
                                    240    -209      240    -209      194    -209      239    -209      195    -209
                                    118    -208
  2  2   56.5    2182    1320       164    -126      164    -126      164    -126      164    -126      164    -126
                                    154    -126      161    -126      160    -126      155    -123      159    -126
                                    161    -126      157    -125      160    -126      154    -122      151    -121
                                    148    -116
  2  3   61.5    2383    1011       175    -137      175    -137      175    -137      175    -137      175    -137
                                    163    -133      171    -135      170    -135      164    -130      167    -134
                                    169    -135      167    -133      170    -136      164    -129      159    -126
                                    155    -121
  2  4   66.5    2450     955       157    -157      157    -157      157    -157      157    -157      157    -157
                                    145    -152      152    -153      152    -156      146    -150      148    -150
                                    150    -151      149    -153      150    -151      145    -149      141    -145
                                    137    -140
  2  5   71.5    2450     955       157    -157      157    -157      157    -157      157    -157      157    -157
                                    148    -148      151    -151      153    -151      147    -147      148    -148
                                    150    -150      150    -150      150    -150      146    -146      142    -142
                                    137    -137
  2  6   76.5    2450     955       157    -157      157    -157      157    -157      157    -157      157    -157
                                    152    -145      153    -151      155    -152      150    -146      150    -148
                                    151    -150      153    -149      152    -150      149    -145      145    -141
                                    141    -137
  2  7   81.5    2382    1012       136    -175      136    -175      136    -175      136    -175      136    -175
                                    133    -163      134    -170      134    -170      129    -165      133    -167
                                    133    -169      132    -167      134    -168      128    -164      126    -159
                                    121    -156
  2  8   86.5    2178    1324       125    -164      125    -164      125    -164      125    -164      125    -164
                                    125    -154      125    -161      125    -160      122    -155      125    -159
                                    125    -160      124    -157      125    -159      122    -155      120    -151
                                    115    -148
  2  9   91.5    1423    1524       209    -248      209    -248      209    -248      209    -248      209    -248
                                    208    -237      208    -242      208    -242      208    -240      208    -240
                                    208    -241      208    -240      208    -196      208    -239      208    -196
                                    207    -118
  2 10   96.5     434    1232       562    -562      562    -562      562    -562      562    -562      562    -562
                                    353    -488      569    -517      569    -514      571    -506      571    -507
                                    570    -511      571    -509      573    -485      572    -503      353    -481
                                    353    -449
 
  3  0   96.5     434    1232       568    -568      568    -568      568    -568      568    -568      568    -568
                                    492    -353      524    -569      523    -569      511    -569      513    -568
                                    518    -568      515    -568      486    -568      508    -569      485    -353
                                    450    -353
  3  1  100.7     878    1322       612    -584      612    -584      612    -584      612    -584      612    -584
                                    352    -584      602    -584      602    -584      473    -584      517    -584
                                    561    -584      517    -584      507    -584      441    -584      293    -584
                                    449    -580
  3  2  104.8    1603    1220       155    -127      155    -127      155    -127      155    -127      155    -127
                                    147    -127      151    -127      151    -127      148    -126      151    -127
                                    149    -127      149    -127      151    -127      147    -125      144    -124
                                    142    -120
  3  3  109.0    1714    1124       163    -135      163    -135      163    -135      163    -135      163    -135
                                    152    -135      157    -135      158    -134      154    -132      157    -135
                                    156    -135      156    -134      159    -135      154    -131      150    -129
                                    147    -124
  3  4  113.1    1765     934       152    -152      152    -152      152    -152      152    -152      152    -152
                                    138    -149      147    -150      146    -149      142    -147      144    -146
                                    146    -150      144    -149      146    -151      141    -146      137    -143
                                    111    -137
  3  5  117.3    1765     934       152    -152      152    -152      152    -152      152    -152      152    -152
                                    138    -145      146    -146      146    -147      142    -144      143    -144
                                    145    -145      144    -146      145    -145      141    -143      137    -139
                                    101    -112
  3  6  121.4    1765     863       152    -152      152    -152      152    -152      152    -152      152    -152
                                    143    -141      147    -145      148    -145      144    -142      145    -143
                                    146    -144      146    -144      146    -144      143    -141      139    -137
                                    120     -94
  3  7  125.6    1728     894       136    -164      136    -164      136    -164      136    -164      136    -164
                                    131    -150      131    -157      132    -157      128    -154      129    -155
                                    129    -156      131    -156      131    -156      128    -153      124    -149
                                    120    -110
  3  8  129.7    1617     992       127    -155      127    -155      127    -155      127    -155      127    -155
                                    125    -143      125    -149      125    -149      123    -146      123    -147
                                    124    -148      124    -148      125    -147      122    -145      119    -141
                                    117    -110
  3  9  133.9     996    1006       182    -210      182    -210      182    -210      182    -210      182    -210
                                    181    -118      181    -205      182    -204      180    -157      180    -186
                                    181    -204      181    -203      181    -181      179    -140      179    -101
                                    178    -101
  3 10  138.0     434     782       560    -560      560    -560      560    -560      560    -560      560    -560
                                    563    -478      565    -510      569    -508      566    -491      565    -496
                                    565    -502      564    -498      564    -493      570    -486      569    -459
                                    583    -319
 

* =============================================================================================================================
# [AR:DEAD LOADS (WORK)] 5300  <Working Dead Load, Superimposed Dead Load, Secondary Shears and Moments>
* ==================================================================================================================================
*  Values are printed for 1/10 points ( TP = 0 thru 10 )
*  Moments are interpolated between two nearest integration points (IP).
*  Shear   values are for nearest integration point (IP).
*  Superimposed Dead Load (SDL):
*    SDL-DC: portion of SDL using DC-factor (LRFR)
*    SDL-DW: portion of SDL using DW-factor (LRFR)
*
               ---- DEAD LOAD ---  ------- SUPERIMPOSED DEAD LOAD -------  --- SECONDARY ----
SPAN    DIST    MOMENT    SHEAR    MOMENT-DC SHEAR-DC  MOMENT-DW SHEAR-DW     MOMENT    SHEAR
 #  TP  (ft)    (k-ft)    (kips)    (k-ft)    (kips)    (k-ft)    (kips)    (k-ft)    (kips)
=== ==  ===.=  ======.=  =====.==  ======.=  =====.==  ======.=  =====.==  ======.=  =====.==
  1  0    0.0       0.0     30.53       0.0      6.12       0.0      0.00
  1  1    4.7     125.4     23.98      24.6      4.58       0.0      0.00
  1  2    9.3     222.1     18.39      41.9      3.04       0.0      0.00
  1  3   14.0     292.8     13.01      51.8      1.49       0.0      0.00
  1  4   18.6     338.1      7.02      54.4     -0.22       0.0      0.00
  1  5   23.3     357.4      1.63      49.7     -1.76       0.0      0.00
  1  6   27.9     338.0     -6.38      37.2     -3.31       0.0      0.00
  1  7   32.5     293.0    -12.37      17.4     -5.02       0.0      0.00
  1  8   37.2     222.4    -17.75      -9.7     -6.57       0.0      0.00
  1  9   41.8     125.8    -23.31     -44.2     -8.11       0.0      0.00
  1 10   46.5      -0.0    -30.65     -86.0     -9.88       0.0      0.00
 
  2  0   46.5       0.0     33.05     -86.0      8.84       0.0      0.00
  2  1   51.5     146.5     25.59     -46.1      7.13       0.0      0.00
  2  2   56.5     258.1     19.25     -14.8      5.41       0.0      0.00
  2  3   61.5     339.4     13.27       8.0      3.70       0.0      0.00
  2  4   66.5     390.8      7.28      22.2      1.98       0.0      0.00
  2  5   71.5     412.2      1.29      27.8      0.27       0.0      0.00
  2  6   76.5     390.6     -7.31      24.9     -1.45       0.0      0.00
  2  7   81.5     339.1    -13.30      13.4     -3.16       0.0      0.00
  2  8   86.5     257.6    -19.29      -6.8     -4.88       0.0      0.00
  2  9   91.5     145.9    -25.53     -35.4     -6.59       0.0      0.00
  2 10   96.5       0.0    -32.93     -72.7     -8.31       0.0      0.00
 
  3  0   96.5       0.0     27.90     -72.7      8.87       0.0      0.00
  3  1  100.7     102.7     21.90     -38.9      7.50       0.0      0.00
  3  2  104.8     180.6     16.50     -11.0      6.12       0.0      0.00
  3  3  109.0     237.6     11.71      11.1      4.75       0.0      0.00
  3  4  113.1     273.6      6.33      27.2      3.21       0.0      0.00
  3  5  117.3     288.8      1.54      37.5      1.84       0.0      0.00
  3  6  121.4     273.0     -5.87      41.8      0.47       0.0      0.00
  3  7  125.6     236.4    -11.26      40.2     -1.08       0.0      0.00
  3  8  129.7     178.8    -16.05      32.6     -2.45       0.0      0.00
  3  9  133.9     100.9    -20.97      19.3     -3.82       0.0      0.00
  3 10  138.0       0.0    -27.44      -0.0     -5.38       0.0      0.00
 

* =============================================================================================================================
# [AR:LIVE LOADS (WORK)] 5302  <Working Live Load Combination Shear and Moment Envelopes>
* ==================================================================================================================================
*  Values are printed for 1/10 points ( TP = 0 thru 10 )
*  Moments are interpolated between two nearest integration points (IP).
*  Shear   values are for nearest integration point (IP).
*  Live Load only; no Dead, Superimposed Dead or Prestress effects included.
*  CN --> Combination Number
                                       --- SHEARS AND ASSOCIATED MOMENTS ---
                   ----- MOMENT -----   POSITIVE  ASSOC     NEGATIVE  ASSOC
SPAN    DIST       POSITIVE  NEGATIVE   SHEAR     MOMENT    SHEAR     MOMENT
 #  TP  (ft)   CN   (k-ft)    (k-ft)    (kips)    (k-ft)    (kips)    (k-ft)
=== ==  ===.=  ==  ======.=  ======.=  =====.==  ======.=  =====.==  ======.=
***** Combination: NRL (6) -- unfactored ***************************************
  1  0    0.0   6       0.0       0.0     50.75       0.0     -6.23       0.0
  1  1    4.7   6     183.5     -26.8     42.36     179.2     -2.29      30.5
  1  2    9.3   6     326.2     -53.7     33.88     301.6     -3.29      86.7
  1  3   14.0   6     423.2     -80.5     25.68     342.0     -6.82     152.7
  1  4   18.6   6     467.7    -107.3     17.78     301.1    -13.41     245.1
  1  5   23.3   6     456.8    -133.3     11.66     243.3    -21.10     336.3
  1  6   27.9   6     398.3    -159.0      6.50     155.1    -29.78     318.9
  1  7   32.5   6     293.9    -185.5      1.80      51.5    -39.13     241.5
  1  8   37.2   6     154.6    -212.1      0.00       0.0    -46.93     112.3
  1  9   41.8   6       5.9    -238.6      0.00       0.0    -54.39     -72.8
  1 10   46.5   6      69.0    -309.4      1.51      69.0    -62.03    -271.8
 
  2  0   46.5   6      67.3    -309.4     57.75    -234.4     -6.93      67.3
  2  1   51.5   6      18.2    -269.5     50.26     -19.7     -6.93      36.0
  2  2   56.5   6     178.0    -229.6     41.66     136.2      0.00       0.0
  2  3   61.5   6     300.2    -189.6     32.76     240.7     -3.15      70.4
  2  4   66.5   6     374.7    -149.7     23.93     288.8     -9.31     166.2
  2  5   71.5   6     394.7    -111.1     15.89     225.5    -16.56     227.3
  2  6   76.5   6     369.5    -123.6      8.92     163.4    -24.89     285.7
  2  7   81.5   6     290.6    -155.7      3.13      71.2    -33.77     231.7
  2  8   86.5   6     166.4    -187.8      0.00       0.0    -42.63     122.1
  2  9   91.5   6       9.2    -219.9      8.69      49.4    -51.10     -52.2
  2 10   96.5   6      88.8    -291.9      8.69      88.8    -59.35    -249.3
 
  3  0   96.5   6      93.2    -291.9     58.02    -239.6     -2.34      93.2
  3  1  100.7   6       4.4    -262.7     52.22     -45.5      0.00       0.0
  3  2  104.8   6     139.0    -233.5     45.06     104.7      0.00       0.0
  3  3  109.0   6     265.4    -204.3     37.25     246.3     -0.48      17.3
  3  4  113.1   6     356.6    -175.1     28.33     356.6     -4.71     113.3
  3  5  117.3   6     404.2    -147.7     20.41     402.3     -9.63     195.2
  3  6  121.4   6     413.2    -119.6     12.34     257.4    -15.36     305.8
  3  7  125.6   6     374.1     -89.7      6.32     123.5    -23.52     374.1
  3  8  129.7   6     284.7     -59.8      3.23      71.9    -31.63     284.7
  3  9  133.9   6     158.5     -29.9      1.20      28.0    -39.55     158.5
  3 10  138.0   6       0.0       0.0      7.53       0.0    -48.51       0.0
 
***** Combination: LEGAL_LANE (7) -- unfactored ********************************
  1  0    0.0   7       0.0       0.0     30.68       0.0     -2.95       0.0
  1  1    4.7   7     106.2     -13.0     24.79     104.6     -2.42      41.3
  1  2    9.3   7     167.9     -26.0     19.44     162.5     -4.69     104.8
  1  3   14.0   7     200.5     -39.0     14.67     181.8     -7.43     145.4
  1  4   18.6   7     212.3     -52.0     10.09     187.0    -10.54     165.8
  1  5   23.3   7     220.6     -64.6      6.63     138.4    -14.21     178.1
  1  6   27.9   7     197.9     -77.0      3.82      91.8    -18.34     165.8
  1  7   32.5   7     151.6     -89.9      1.36      39.7    -22.76     125.6
  1  8   37.2   7      86.1    -103.3      0.22       7.3    -27.03      60.8
  1  9   41.8   7       7.0    -140.7      0.14       5.4    -32.26     -33.7
  1 10   46.5   7      33.0    -251.6      0.68      33.0    -38.23    -160.2
 
  2  0   46.5   7      32.2    -251.6     35.60    -139.5     -3.30      32.2
  2  1   51.5   7      16.6    -137.8     30.06     -13.9     -3.33      18.2
  2  2   56.5   7      94.0    -112.5     24.60     -10.4     -0.65       4.1
  2  3   61.5   7     147.7     -94.8     20.07      51.4     -2.25      39.0
  2  4   66.5   7     170.1     -77.6     16.15      99.4     -6.91     150.6
  2  5   71.5   7     166.9     -61.1     11.76     134.8    -11.59     140.8
  2  6   76.5   7     166.3     -64.8      6.93     145.7    -15.80     108.5
  2  7   81.5   7     142.7     -76.9      3.04      52.5    -19.85      59.7
  2  8   86.5   7      87.9     -90.1      0.83       5.7    -24.49      -3.2
  2  9   91.5   7      10.2    -125.3      4.29      25.1    -30.31     -17.4
  2 10   96.5   7      43.5    -239.0      4.26      43.5    -36.39    -141.8
 
  3  0   96.5   7      45.6    -239.0     34.25    -127.4     -1.13      45.6
  3  1  100.7   7      14.3    -146.2     29.87     -28.2     -0.21       7.4
  3  2  104.8   7      84.2    -112.8     25.73      56.0     -0.27       8.7
  3  3  109.0   7     139.7     -98.6     22.03     111.6     -0.73      23.3
  3  4  113.1   7     177.8     -84.5     18.37      72.1     -2.93      74.4
  3  5  117.3   7     194.2     -71.3     15.08     113.5     -6.24     180.1
  3  6  121.4   7     183.2     -57.7     11.37     137.8    -10.12     171.4
  3  7  125.6   7     167.1     -43.3      7.59     129.5    -13.48     158.9
  3  8  129.7   7     140.8     -28.8      4.90      91.9    -17.24     136.4
  3  9  133.9   7      89.4     -14.4      2.25      35.6    -22.13      88.2
  3 10  138.0   7       0.0       0.0      3.62       0.0    -28.23       0.0
 
***** Combination: LEGAL_LANE_2 (8) -- unfactored ******************************
  1  0    0.0   8       0.0       0.0     30.68       0.0     -3.00       0.0
  1  1    4.7   8     107.0     -13.0     24.94     105.3     -3.36      36.7
  1  2    9.3   8     171.4     -26.0     19.84     166.1     -6.43      89.4
  1  3   14.0   8     206.1     -39.0     15.20     188.8     -9.53     118.1
  1  4   18.6   8     214.4     -52.0     10.70     181.4    -12.71     128.5
  1  5   23.3   8     220.6     -64.6      7.28     152.4    -16.27     134.3
  1  6   27.9   8     197.9     -77.0      4.44     107.5    -20.12     120.6
  1  7   32.5   8     151.6     -89.9      1.87      54.9    -24.15      84.0
  1  8   37.2   8      86.1    -105.9      0.22       9.0    -28.03      27.0
  1  9   41.8   8       7.0    -158.2      0.14       5.4    -32.88     -56.5
  1 10   46.5   8      33.0    -251.6      0.68      33.0    -38.48    -170.9
 
  2  0   46.5   8      32.2    -251.6     36.67    -176.8     -3.30      32.2
  2  1   51.5   8      17.4    -152.0     31.70     -63.9     -3.33      18.2
  2  2   56.5   8      94.0    -112.5     26.51      12.4     -1.02     -10.8
  2  3   61.5   8     147.7     -94.8     21.47      62.1     -4.21      31.6
  2  4   66.5   8     170.1     -77.6     16.90      83.4     -7.74      66.5
  2  5   71.5   8     164.7     -61.1     12.82      82.7    -11.59     140.8
  2  6   76.5   8     166.3     -64.8      9.06      68.6    -15.92      95.7
  2  7   81.5   8     142.3     -76.9      5.69      43.7    -20.76      76.6
  2  8   86.5   8      88.1     -90.1      2.83       8.6    -25.85      31.5
  2  9   91.5   8      14.7    -128.9      4.29      25.1    -31.23     -45.6
  2 10   96.5   8      43.5    -239.0      4.26      43.5    -37.02    -164.1
 
  3  0   96.5   8      45.6    -239.0     34.39    -132.9     -1.13      45.6
  3  1  100.7   8      14.3    -152.5     30.35     -38.4     -0.21       7.4
  3  2  104.8   8      84.2    -110.3     26.65      25.8     -0.27       9.8
  3  3  109.0   8     139.7     -95.9     23.42      72.0     -1.45      45.3
  3  4  113.1   8     177.8     -82.2     19.54      99.9     -3.84      91.8
  3  5  117.3   8     194.2     -69.3     15.89     106.4     -6.49     130.6
  3  6  121.4   8     183.2     -56.1     13.14     107.8    -10.12     171.4
  3  7  125.6   8     176.8     -42.1     10.25      98.2    -13.84     163.3
  3  8  129.7   8     147.7     -28.1      7.47      71.8    -18.13     143.3
  3  9  133.9   8      92.2     -14.0      4.48      27.0    -22.85      90.9
  3 10  138.0   8       0.0       0.0      3.52       0.0    -28.62       0.0
 
***** Combination: TYPE_3 (9) -- unfactored ************************************
  1  0    0.0   9       0.0       0.0     39.68       0.0     -3.97       0.0
  1  1    4.7   9     143.5     -17.1     33.86     143.5     -3.01      67.8
  1  2    9.3   9     237.7     -34.1     28.24     237.7     -6.43     168.0
  1  3   14.0   9     287.8     -51.2     22.90     286.4    -10.48     229.8
  1  4   18.6   9     307.9     -68.2     17.37     295.1    -14.96     260.9
  1  5   23.3   9     297.6     -84.7     12.84     270.3    -20.28     280.2
  1  6   27.9   9     265.0    -101.1      8.83     217.6    -25.68     260.0
  1  7   32.5   9     204.1    -117.9      4.96     147.0    -31.28     204.1
  1  8   37.2   9     119.6    -134.8      2.09      67.2    -35.89     119.6
  1  9   41.8   9      20.2    -151.6      0.00       0.0    -40.01      14.9
  1 10   46.5   9      43.9    -195.8      0.95      43.9    -43.94    -101.3
 
  2  0   46.5   9      42.8    -195.8     42.26     -92.0     -4.36      42.8
  2  1   51.5   9      34.8    -170.5     38.05      34.8     -4.36      22.9
  2  2   56.5   9     134.1    -145.3     32.89     134.1     -2.95      77.7
  2  3   61.5   9     204.6    -120.0     27.41     204.6     -7.02     156.0
  2  4   66.5   9     248.7     -94.7     21.82     241.1    -11.75     214.1
  2  5   71.5   9     258.4     -70.3     16.39     242.4    -16.96     243.3
  2  6   76.5   9     245.5     -78.6     11.29     211.0    -22.45     238.6
  2  7   81.5   9     198.5     -99.1      6.72     152.5    -28.03     198.5
  2  8   86.5   9     125.3    -119.5      2.86      76.6    -33.46     125.3
  2  9   91.5   9      25.2    -139.9      5.51      31.2    -38.51      25.2
  2 10   96.5   9      56.2    -185.4      5.51      56.2    -42.99     -93.1
 
  3  0   96.5   9      59.0    -185.4     42.46     -95.4     -1.44      59.0
  3  1  100.7   9      19.0    -166.9     39.25      19.0      0.00       0.7
  3  2  104.8   9     113.7    -148.3     35.10     113.7     -1.48      52.3
  3  3  109.0   9     188.0    -129.8     30.50     188.0     -4.29     126.9
  3  4  113.1   9     239.1    -111.2     24.88     234.1     -8.06     191.6
  3  5  117.3   9     264.5     -93.8     19.53     246.1    -11.97     239.7
  3  6  121.4   9     274.7     -76.0     14.91     236.0    -16.34     263.0
  3  7  125.6   9     256.0     -57.0     10.59     208.2    -21.72     256.0
  3  8  129.7   9     212.2     -38.0      6.61     149.6    -26.89     212.2
  3  9  133.9   9     128.3     -19.0      2.55      59.5    -32.33     128.3
  3 10  138.0   9       0.0       0.0      4.84       0.0    -38.71       0.0
 
***** Combination: TYPE_3S2 (10) -- unfactored *********************************
  1  0    0.0  10       0.0       0.0     38.62       0.0     -3.78       0.0
  1  1    4.7  10     133.5     -16.5     31.60     133.5     -2.78      61.8
  1  2    9.3  10     214.0     -33.0     25.50     214.0     -5.87     153.2
  1  3   14.0  10     262.6     -49.4     20.73     259.8     -9.56     209.5
  1  4   18.6  10     279.6     -65.9     15.98     271.6    -13.68     244.3
  1  5   23.3  10     271.2     -81.9     11.61     259.9    -19.18     258.5
  1  6   27.9  10     239.1     -97.7      5.77     145.8    -24.69     202.2
  1  7   32.5  10     187.2    -114.0      1.75      50.8    -30.07     119.5
  1  8   37.2  10     102.4    -130.3      0.00       0.0    -34.26      41.2
  1  9   41.8  10       0.1    -153.5      0.00       0.0    -39.67     -26.4
  1 10   46.5  10      38.6    -271.9      0.81      38.6    -46.53    -162.0
 
  2  0   46.5  10      37.6    -271.9     43.42    -138.5     -3.88      37.6
  2  1   51.5  10      11.0    -159.4     37.32      -6.7     -3.88      20.1
  2  2   56.5  10     116.0    -135.8     32.72      31.4      0.00       0.0
  2  3   61.5  10     192.6    -112.1     27.39     126.8     -2.44      57.6
  2  4   66.5  10     229.6     -88.5     21.34     196.8     -8.45     227.9
  2  5   71.5  10     231.9     -65.7     14.76     231.4    -15.32     231.9
  2  6   76.5  10     226.6     -69.1      7.89     224.9    -21.75     195.9
  2  7   81.5  10     186.7     -87.0      2.87      68.0    -27.59     127.2
  2  8   86.5  10     107.5    -105.0      0.00       0.0    -32.67      35.6
  2  9   91.5  10       0.0    -139.9      5.12      29.2    -37.85     -16.0
  2 10   96.5  10      52.5    -265.1      5.12      52.5    -44.68    -148.2
 
  3  0   96.5  10      55.1    -265.1     42.39    -154.4     -1.37      55.1
  3  1  100.7  10       6.5    -164.0     37.74     -93.6      0.00       0.0
  3  2  104.8  10      99.9    -143.8     34.44       3.1      0.00       0.0
  3  3  109.0  10     164.4    -125.8     30.46      92.6     -0.74      26.3
  3  4  113.1  10     212.4    -107.8     25.22     166.0     -6.56     199.1
  3  5  117.3  10     245.3     -90.9     19.87     214.6    -11.41     228.1
  3  6  121.4  10     252.2     -73.6     14.33     207.9    -15.23     244.8
  3  7  125.6  10     234.6     -55.2      9.66     189.8    -19.90     234.6
  3  8  129.7  10     192.0     -36.8      6.03     136.4    -24.34     192.0
  3  9  133.9  10     115.5     -18.4      2.33      54.2    -29.10     115.5
  3 10  138.0  10       0.0       0.0      4.65       0.0    -35.93       0.0
 
***** Combination: TYPE_3-3 (11) -- unfactored *********************************
  1  0    0.0  11       0.0       0.0     35.94       0.0     -3.33       0.0
  1  1    4.7  11     122.8     -14.4     29.09     122.8     -2.49      55.8
  1  2    9.3  11     191.0     -28.8     22.85     191.0     -5.30     138.4
  1  3   14.0  11     225.1     -43.3     17.24     213.5     -8.63     189.2
  1  4   18.6  11     236.2     -57.7     11.82     221.5    -12.27     213.8
  1  5   23.3  11     247.4     -71.7      7.70     160.5    -16.58     229.4
  1  6   27.9  11     222.4     -85.5      4.32     103.5    -21.37     215.9
  1  7   32.5  11     170.5     -99.7      1.35      39.1    -26.37     170.0
  1  8   37.2  11      97.0    -114.0      0.00       0.0    -31.15      97.0
  1  9   41.8  11       0.6    -150.9      0.00       0.0    -37.15      -9.3
  1 10   46.5  11      37.3    -274.1      0.79      37.3    -43.94    -151.5
 
  2  0   46.5  11      36.4    -274.1     40.59    -125.3     -3.69      36.4
  2  1   51.5  11      15.2    -147.5     34.36      15.2     -3.69      19.4
  2  2   56.5  11     110.5    -125.7     28.14       0.7      0.00       0.0
  2  3   61.5  11     169.3    -103.8     23.04      70.7     -1.86      44.7
  2  4   66.5  11     191.4     -81.9     18.61     127.9     -7.69     191.4
  2  5   71.5  11     184.7     -60.8     13.42     172.4    -13.39     177.5
  2  6   76.5  11     186.8     -66.8      7.51     186.8    -18.31     136.3
  2  7   81.5  11     163.7     -84.1      2.70      63.6    -22.90      77.6
  2  8   86.5  11     103.1    -101.5      0.00       1.8    -28.14       5.7
  2  9   91.5  11       5.5    -136.0      4.77      27.0    -34.84       5.5
  2 10   96.5  11      48.6    -262.3      4.77      48.6    -41.77    -134.1
 
  3  0   96.5  11      51.0    -262.3     39.21    -112.0     -1.25      51.0
  3  1  100.7  11       7.8    -158.9     34.30      -2.1      0.00       0.0
  3  2  104.8  11      93.4    -124.9     29.66      93.4      0.00       0.0
  3  3  109.0  11     156.1    -109.3     25.53     156.1     -0.46      16.4
  3  4  113.1  11     199.5     -93.7     21.47      96.6     -3.12      80.7
  3  5  117.3  11     217.9     -79.0     17.71     148.8     -7.20     217.9
  3  6  121.4  11     203.7     -63.9     13.29     181.0    -11.95     203.7
  3  7  125.6  11     186.5     -48.0      8.72     171.4    -15.82     186.5
  3  8  129.7  11     159.6     -32.0      5.44     123.2    -20.17     159.6
  3  9  133.9  11     103.3     -16.0      2.10      49.0    -25.93     103.3
  3 10  138.0  11       0.0       0.0      3.99       0.0    -33.05       0.0
 
***** Combination: OVERLOAD_1 (12) -- unfactored *******************************
  1  0    0.0  12       0.0       0.0     44.01       0.0     -4.76       0.0
  1  1    4.7  12     141.1     -18.6     36.79     141.1     -2.85      52.3
  1  2    9.3  12     229.1     -37.1     29.93     227.7     -5.52     130.6
  1  3   14.0  12     282.8     -55.7     23.52     265.6     -8.99     178.5
  1  4   18.6  12     303.5     -74.2     17.05     262.1    -13.74     216.6
  1  5   23.3  12     294.7     -92.3     11.86     225.3    -19.85     246.3
  1  6   27.9  12     261.4    -110.2      7.40     163.1    -26.32     235.2
  1  7   32.5  12     194.9    -128.6      3.25      86.5    -33.57     184.8
  1  8   37.2  12     100.2    -147.0      0.44      12.1    -40.05      97.1
  1  9   41.8  12       0.0    -165.3      0.00       0.0    -46.00     -21.9
  1 10   46.5  12      46.6    -213.6      1.16      46.6    -51.87    -162.9
 
  2  0   46.5  12      45.6    -213.6     48.84    -142.2     -5.13      45.6
  2  1   51.5  12       3.7    -186.0     42.95       3.7     -5.13      24.4
  2  2   56.5  12     117.6    -158.4     36.03     113.4     -0.50      13.0
  2  3   61.5  12     197.3    -130.9     28.96     185.1     -4.82      98.5
  2  4   66.5  12     244.6    -103.3     22.04     215.9    -10.08     167.3
  2  5   71.5  12     254.3     -77.3     15.55     207.5    -16.12     208.3
  2  6   76.5  12     241.4     -84.3      9.72     165.4    -22.74     213.8
  2  7   81.5  12     190.6    -106.1      4.73      98.6    -29.73     179.0
  2  8   86.5  12     108.0    -128.0      0.71      18.0    -36.79     103.5
  2  9   91.5  12       0.0    -149.9      6.64      34.1    -43.64      -8.5
  2 10   96.5  12      61.4    -204.0      6.64      61.4    -50.00    -149.6
 
  3  0   96.5  12      65.1    -204.0     48.92    -145.5     -1.75      65.1
  3  1  100.7  12       3.0    -183.6     44.13     -11.2      0.00       0.0
  3  2  104.8  12      95.0    -163.2     38.15      94.6      0.00       2.5
  3  3  109.0  12     178.2    -142.8     31.83     169.5     -2.14      62.8
  3  4  113.1  12     233.8    -122.4     24.95     210.4     -6.15     135.1
  3  5  117.3  12     258.6    -103.5     18.54     212.0    -10.42     193.1
  3  6  121.4  12     267.3     -84.0     13.22     189.8    -15.35     228.6
  3  7  125.6  12     250.0     -63.0      9.08     164.2    -21.57     234.0
  3  8  129.7  12     202.1     -42.0      5.66     117.9    -27.69     201.2
  3  9  133.9  12     125.2     -21.0      2.19      46.9    -34.25     125.2
  3 10  138.0  12       0.0       0.0      5.76       0.0    -42.07       0.0
 
***** Combination: OVERLOAD_2 (13) -- unfactored *******************************
  1  0    0.0  13       0.0       0.0     50.26       0.0     -4.44       0.0
  1  1    4.7  13     157.8     -17.4     41.20     157.8     -2.51      44.5
  1  2    9.3  13     258.1     -34.9     32.76     248.6     -4.81     114.5
  1  3   14.0  13     312.0     -52.3     25.03     281.6     -9.72     194.8
  1  4   18.6  13     326.0     -69.8     16.66     288.0    -15.70     242.2
  1  5   23.3  13     307.1     -86.8      8.99     292.6    -23.37     213.8
  1  6   27.9  13     283.3    -103.6      3.68      77.4    -30.82     142.5
  1  7   32.5  13     218.8    -120.9      0.44      11.0    -38.78      87.3
  1  8   37.2  13     108.3    -142.1      0.00       0.0    -48.16     -18.5
  1  9   41.8  13       0.0    -248.6      0.00       0.0    -57.14    -188.9
  1 10   46.5  13      50.3    -409.5      1.25      50.3    -65.77    -384.3
 
  2  0   46.5  13      49.3    -409.5     63.10    -378.1     -5.56      49.3
  2  1   51.5  13       8.1    -246.3     55.13    -173.5     -5.56      26.4
  2  2   56.5  13     131.3    -181.2     45.42      -3.3      0.00       0.0
  2  3   61.5  13     205.7    -149.7     35.46      49.2     -0.47      13.3
  2  4   66.5  13     230.1    -118.1     27.78     139.6     -9.50     230.1
  2  5   71.5  13     239.9     -88.3     19.02     195.9    -18.83     205.4
  2  6   76.5  13     221.1     -91.1      9.64     221.1    -27.20     154.8
  2  7   81.5  13     197.2    -114.7      2.01      44.1    -35.36     127.8
  2  8   86.5  13     122.4    -138.4      0.00       0.0    -45.53       2.8
  2  9   91.5  13       0.0    -214.9      7.59      39.0    -54.94    -160.2
  2 10   96.5  13      70.2    -397.9      7.59      70.2    -63.36    -348.4
 
  3  0   96.5  13      74.5    -397.9     61.24    -366.9     -2.06      74.5
  3  1  100.7  13       2.9    -258.7     54.28    -187.0      0.00       0.0
  3  2  104.8  13     103.1    -149.3     45.62     -39.7      0.00       0.0
  3  3  109.0  13     195.7    -130.7     38.54       8.7      0.00       0.0
  3  4  113.1  13     246.4    -112.0     31.73      94.3     -1.96      52.1
  3  5  117.3  13     270.8     -94.7     24.65     170.9     -9.32     245.8
  3  6  121.4  13     279.4     -76.8     17.60     207.2    -16.10     248.8
  3  7  125.6  13     269.2     -57.6      9.44     169.7    -22.18     240.8
  3  8  129.7  13     221.6     -38.4      4.88     101.0    -29.45     214.3
  3  9  133.9  13     136.9     -19.2      2.01      46.4    -37.39     136.9
  3 10  138.0  13       0.0       0.0      5.27       0.0    -47.04       0.0
 
***** Combination: EV2 (14) -- unfactored **************************************
  1  0    0.0  14       0.0       0.0     47.35       0.0     -4.59       0.0
  1  1    4.7  14     172.1     -19.9     40.59     172.1     -4.56     112.0
  1  2    9.3  14     286.6     -39.9     34.03     286.6     -8.14     211.3
  1  3   14.0  14     347.6     -59.8     27.77     347.6    -12.15     267.5
  1  4   18.6  14     361.2     -79.7     21.26     361.2    -18.57     325.3
  1  5   23.3  14     347.3     -99.0     15.89     334.7    -25.05     347.3
  1  6   27.9  14     318.7    -118.1     11.12     274.6    -31.18     318.7
  1  7   32.5  14     250.2    -137.8      6.50     192.6    -37.52     250.2
  1  8   37.2  14     150.6    -157.5      3.00      97.6    -42.70     150.6
  1  9   41.8  14      33.9    -177.2      0.20       6.5    -47.31      29.6
  1 10   46.5  14      51.7    -229.3      1.13      51.7    -51.67    -103.3
 
  2  0   46.5  14      50.5    -229.3     49.91     -95.1     -5.22      50.5
  2  1   51.5  14      51.4    -199.7     45.17      51.4     -5.22      27.0
  2  2   56.5  14     167.1    -170.1     39.30     167.1     -4.18     110.4
  2  3   61.5  14     250.8    -140.5     32.99     250.8     -9.08     202.4
  2  4   66.5  14     295.6    -110.9     26.50     295.6    -14.69     268.8
  2  5   71.5  14     300.4     -82.3     20.12     299.4    -20.82     300.4
  2  6   76.5  14     292.5     -92.7     14.11     264.7    -27.25     292.5
  2  7   81.5  14     243.6    -116.7      8.68     197.6    -33.71     243.6
  2  8   86.5  14     157.0    -140.8      4.02     108.2    -39.94     157.0
  2  9   91.5  14      40.8    -164.9      6.49      36.6    -45.67      40.8
  2 10   96.5  14      65.8    -216.8      6.49      65.8    -50.71     -95.2
 
  3  0   96.5  14      69.1    -216.8     50.18     -99.2     -1.71      69.1
  3  1  100.7  14      33.4    -195.1     46.60      33.4      0.00       2.3
  3  2  104.8  14     143.4    -173.4     41.97     143.4     -2.36      81.3
  3  3  109.0  14     232.0    -151.7     36.80     232.0     -5.78     169.7
  3  4  113.1  14     289.5    -130.1     30.44     289.5    -10.33     245.4
  3  5  117.3  14     309.1    -109.7     24.37     309.1    -14.98     299.6
  3  6  121.4  14     324.1     -88.8     17.99     283.7    -20.15     324.1
  3  7  125.6  14     312.5     -66.6     12.37     245.0    -26.52     312.5
  3  8  129.7  14     257.2     -44.4      8.50     194.4    -32.59     257.2
  3  9  133.9  14     154.5     -22.2      4.53     113.4    -38.96     154.5
  3 10  138.0  14       0.0       0.0      5.66       0.0    -46.38       0.0
 
***** Combination: EV3 (15) -- unfactored **************************************
  1  0    0.0  15       0.0       0.0     69.82       0.0     -6.86       0.0
  1  1    4.7  15     253.3     -29.7     59.75     253.3     -5.41     123.8
  1  2    9.3  15     421.0     -59.4     50.01     421.0    -11.73     306.4
  1  3   14.0  15     510.1     -89.1     40.71     509.6    -19.12     419.0
  1  4   18.6  15     545.6    -118.8     31.08     528.1    -27.23     475.1
  1  5   23.3  15     528.5    -147.5     23.15     487.5    -36.42     503.6
  1  6   27.9  15     468.4    -176.0     16.10     397.2    -45.64     464.2
  1  7   32.5  15     364.6    -205.3      9.27     274.8    -55.18     364.6
  1  8   37.2  15     217.2    -234.7      4.17     135.0    -63.00     217.2
  1  9   41.8  15      44.3    -264.0      0.00       2.8    -69.96      36.9
  1 10   46.5  15      76.8    -341.0      1.79      76.8    -76.55    -161.3
 
  2  0   46.5  15      75.0    -341.0     73.87    -148.2     -7.74      75.0
  2  1   51.5  15      70.1    -297.0     66.74      70.1     -7.74      40.1
  2  2   56.5  15     242.2    -253.0     57.94     242.2     -5.85     153.9
  2  3   61.5  15     366.0    -209.0     48.52     366.0    -13.05     289.8
  2  4   66.5  15     441.0    -165.0     38.88     431.6    -21.35     389.2
  2  5   71.5  15     460.2    -122.4     29.43     436.2    -30.44     437.6
  2  6   76.5  15     435.3    -137.7     20.53     383.6    -39.97     426.9
  2  7   81.5  15     355.2    -173.4     12.48     283.0    -49.60     355.2
  2  8   86.5  15     227.0    -209.2      5.63     150.7    -58.91     227.0
  2  9   91.5  15      54.0    -244.9      9.63      54.4    -67.50      54.0
  2 10   96.5  15      97.9    -322.7      9.63      97.9    -75.07    -148.4
 
  3  0   96.5  15     102.7    -322.7     74.21    -154.0     -2.54     102.7
  3  1  100.7  15      42.6    -290.4     68.80      42.6      0.00       2.6
  3  2  104.8  15     206.5    -258.2     61.80     206.5     -3.18     110.2
  3  3  109.0  15     336.7    -225.9     54.00     336.7     -8.18     240.6
  3  4  113.1  15     424.0    -193.6     44.43     420.0    -14.85     352.8
  3  5  117.3  15     472.0    -163.3     35.31     445.6    -21.73     434.8
  3  6  121.4  15     488.5    -132.2     27.19     430.4    -29.39     472.8
  3  7  125.6  15     457.2     -99.1     19.31     379.6    -38.79     457.2
  3  8  129.7  15     377.2     -66.1     12.05     272.7    -47.80     377.2
  3  9  133.9  15     227.1     -33.0      4.65     108.5    -57.25     227.1
  3 10  138.0  15       0.0       0.0      8.39       0.0    -68.29       0.0
 
***** Combination: HL-93 (16) -- unfactored ************************************
  1  0    0.0  16       0.0       0.0     76.87       0.0     -8.13       0.0
  1  1    4.7  16     278.2     -35.3     64.52     273.1     -7.30     127.1
  1  2    9.3  16     461.4     -70.7     52.88     444.2    -13.72     302.0
  1  3   14.0  16     558.3    -106.0     42.07     525.1    -21.71     419.6
  1  4   18.6  16     595.0    -141.3     31.54     536.2    -30.66     477.6
  1  5   23.3  16     581.2    -175.6     24.12     508.7    -38.68     477.6
  1  6   27.9  16     522.1    -209.4     17.52     435.0    -48.15     422.3
  1  7   32.5  16     399.3    -244.3     11.16     331.6    -60.08     316.9
  1  8   37.2  16     250.6    -281.0      6.39     211.7    -70.53     145.4
  1  9   41.8  16     100.9    -340.1      2.54      87.9    -80.36     -80.9
  1 10   46.5  16      88.1    -491.8      2.03      88.1    -90.42    -349.4
 
  2  0   46.5  16      86.0    -491.8     86.67    -323.6     -8.89      86.0
  2  1   51.5  16     115.4    -369.9     76.34     -40.9     -9.00      49.2
  2  2   56.5  16     261.7    -299.4     64.74     172.9     -9.94     218.5
  2  3   61.5  16     390.7    -253.5     53.00     318.2    -16.57     323.9
  2  4   66.5  16     477.5    -208.9     41.57     390.6    -24.17     396.4
  2  5   71.5  16     494.9    -166.4     32.08     416.7    -32.48     424.0
  2  6   76.5  16     471.7    -175.8     23.87     386.6    -42.18     395.3
  2  7   81.5  16     379.5    -206.6     16.44     313.6    -53.70     318.3
  2  8   86.5  16     249.0    -240.7     10.03     210.8    -65.40     169.2
  2  9   91.5  16     108.8    -303.9     11.51      67.4    -76.87     -45.7
  2 10   96.5  16     115.8    -470.5     11.41     115.8    -87.74    -315.7
 
  3  0   96.5  16     121.5    -470.5     85.91    -321.3     -3.09     121.5
  3  1  100.7  16     104.7    -364.0     77.71     -69.4     -2.31      86.0
  3  2  104.8  16     242.4    -308.0     68.08     130.4     -6.13     202.0
  3  3  109.0  16     372.8    -269.2     57.88     278.2    -10.80     311.5
  3  4  113.1  16     468.0    -230.8     46.79     368.8    -17.01     403.4
  3  5  117.3  16     518.9    -194.6     38.76     426.6    -23.40     467.0
  3  6  121.4  16     527.8    -157.5     31.00     426.2    -30.54     490.1
  3  7  125.6  16     490.6    -118.2     22.17     373.1    -39.38     464.3
  3  8  129.7  16     406.0     -78.8     14.37     264.4    -49.63     391.9
  3  9  133.9  16     245.1     -39.4      7.40     127.3    -60.67     240.9
  3 10  138.0  16       0.0       0.0      9.99       0.0    -73.90       0.0
 

* =============================================================================================================================
# [AR:DL WORKING STRESS] 5400  <Dead Load and Superimposed Dead Load Working Stresses>
* ==================================================================================================================================
*  Values are for nearest integration point to actual tenth point.
*
*
               ------ DEAD LOADS -------  - SUPERIMPOSED DEAD LOADS -
               TOP      TOP      BOTTOM   TOP      TOP      BOTTOM
               OF       OF       OF       OF       OF       OF
SPAN    DIST   SLAB     GIRDER   GIRDER   SLAB     GIRDER   GIRDER
 #  TP  (ft)   (psi)    (psi)    (psi)    (psi)    (psi)    (psi)
=== ==  ===.=  =====.=  =====.=  =====.=  =====.=  =====.=  =====.=
  1  0    0.0      0.0     -0.0      0.0     -0.0     -0.0      0.0
  1  1    4.7      0.0   -402.5    352.4    -13.1     -8.3     38.1
  1  2    9.3      0.0   -866.6    690.6    -22.7    -12.7     77.6
  1  3   14.0      0.0  -1150.6    916.9    -28.4    -15.9     97.1
  1  4   18.6      0.0  -1351.0   1076.6    -30.1    -16.9    103.2
  1  5   23.3      0.0  -1431.3   1140.6    -27.7    -15.5     95.0
  1  6   27.9      0.0  -1363.0   1086.2    -21.3    -11.9     72.9
  1  7   32.5      0.0  -1175.4    936.7     -9.8     -5.5     33.5
  1  8   37.2      0.0   -905.3    721.4      4.6      2.6    -15.8
  1  9   41.8      0.0   -427.6    380.2     22.5     14.6    -63.2
  1 10   46.5      0.0    -39.6     36.7     43.6     30.2   -108.8
 
  2  0   46.5      0.0     -0.0      0.0     46.1     31.9   -115.1
  2  1   51.5      0.0   -447.9    403.4     25.0     16.5    -68.2
  2  2   56.5      0.0  -1033.3    823.5      8.2      4.6    -28.0
  2  3   61.5      0.0  -1358.8   1082.9     -4.4     -2.5     15.2
  2  4   66.5      0.0  -1564.5   1246.7    -12.3     -6.9     42.1
  2  5   71.5      0.0  -1650.3   1315.1    -15.4     -8.6     52.7
  2  6   76.5      0.0  -1563.8   1246.2    -13.8     -7.7     47.1
  2  7   81.5      0.0  -1357.4   1081.8     -7.4     -4.1     25.3
  2  8   86.5      0.0  -1031.2    821.8      3.7      2.1    -12.8
  2  9   91.5      0.0   -446.2    401.8     19.2     12.7    -52.4
  2 10   96.5      0.0     -0.0      0.0     39.0     27.0    -97.3
 
  3  0   96.5      0.0     -0.0      0.0     39.0     27.0    -97.3
  3  1  100.7      0.0   -283.4    260.5     21.5     14.7    -55.2
  3  2  104.8      0.0   -704.8    561.7      7.0      3.9    -24.1
  3  3  109.0      0.0   -928.9    740.3     -4.9     -2.8     16.9
  3  4  113.1      0.0  -1093.3    871.2    -14.9     -8.4     51.1
  3  5  117.3      0.0  -1156.2    921.4    -20.5    -11.5     70.2
  3  6  121.4      0.0  -1101.3    877.7    -23.0    -12.9     78.7
  3  7  125.6      0.0   -948.8    756.1    -22.3    -12.5     76.3
  3  8  129.7      0.0   -728.3    580.4    -18.3    -10.3     62.7
  3  9  133.9      0.0   -357.4    313.0    -11.2     -7.1     32.8
  3 10  138.0      0.0     -0.0      0.0      0.0      0.0     -0.0
 

* =============================================================================================================================
# [AR:PS WORKING STRESS] 5401  <Prestress and Secondary Working Stresses>
* ==================================================================================================================================
*  Values are for nearest integration point to actual tenth point.
*
               ------- PRESTRESS -------  ------- SECONDARY -------
               TOP      TOP      BOTTOM   TOP      TOP      BOTTOM
               OF       OF       OF       OF       OF       OF
SPAN    DIST   SLAB     GIRDER   GIRDER   SLAB     GIRDER   GIRDER
 #  TP  (ft)   (psi)    (psi)    (psi)    (psi)    (psi)    (psi)
=== ==  ===.=  =====.=  =====.=  =====.=  =====.=  =====.=  =====.=
  1  0    0.0      0.0     -0.0      0.0      0.0     -0.0      0.0
  1  1    4.7      0.0      3.5  -1399.1      0.0     -0.0      0.0
  1  2    9.3      0.0     58.8  -1883.9      0.0     -0.0      0.0
  1  3   14.0      0.0    346.0  -2112.8      0.0     -0.0      0.0
  1  4   18.6      0.0    476.0  -2216.5      0.0     -0.0      0.0
  1  5   23.3      0.0    476.0  -2216.5      0.0     -0.0      0.0
  1  6   27.9      0.0    476.0  -2216.5      0.0     -0.0      0.0
  1  7   32.5      0.0    377.9  -2138.2      0.0     -0.0      0.0
  1  8   37.2      0.0     90.7  -1909.3      0.0     -0.0      0.0
  1  9   41.8      0.0     61.2  -1369.9      0.0     -0.0      0.0
  1 10   46.5      0.0    -14.5   -242.1      0.0     -0.0      0.0
 
  2  0   46.5      0.0     -0.0      0.0      0.0     -0.0      0.0
  2  1   51.5      0.0    -96.3  -1291.4      0.0     -0.0      0.0
  2  2   56.5      0.0    -41.9  -2003.3      0.0     -0.0      0.0
  2  3   61.5      0.0    385.7  -2344.0      0.0     -0.0      0.0
  2  4   66.5      0.0    532.4  -2460.9      0.0     -0.0      0.0
  2  5   71.5      0.0    532.4  -2460.9      0.0     -0.0      0.0
  2  6   76.5      0.0    532.4  -2460.9      0.0     -0.0      0.0
  2  7   81.5      0.0    383.2  -2342.0      0.0     -0.0      0.0
  2  8   86.5      0.0    -51.7  -1995.5      0.0     -0.0      0.0
  2  9   91.5      0.0   -109.3  -1279.7      0.0     -0.0      0.0
  2 10   96.5      0.0     -0.0      0.0      0.0     -0.0      0.0
 
  3  0   96.5      0.0     -0.0      0.0      0.0     -0.0      0.0
  3  1  100.7      0.0     92.9  -1008.4      0.0     -0.0      0.0
  3  2  104.8      0.0     74.8  -1575.4      0.0     -0.0      0.0
  3  3  109.0      0.0    324.3  -1774.3      0.0     -0.0      0.0
  3  4  113.1      0.0    441.9  -1868.0      0.0     -0.0      0.0
  3  5  117.3      0.0    441.9  -1868.0      0.0     -0.0      0.0
  3  6  121.4      0.0    441.9  -1868.0      0.0     -0.0      0.0
  3  7  125.6      0.0    355.5  -1799.1      0.0     -0.0      0.0
  3  8  129.7      0.0    105.9  -1600.2      0.0     -0.0      0.0
  3  9  133.9      0.0     39.8  -1186.8      0.0     -0.0      0.0
  3 10  138.0      0.0     -0.0      0.0      0.0     -0.0      0.0
 

* =============================================================================================================================
# [AR:LL WORKING STRESS] 5402  <Live Load Working Stresses for Load Combinations>
* ==================================================================================================================================
*  LC = LOAD COMBINATION.
*  Values are for nearest integration point to actual tenth point.
*
*
                   ---- POSITIVE MOMENT ----  ----- NEGATIVE MOMENT ----
                   TOP      TOP      BOTTOM   TOP      TOP      BOTTOM
                   OF       OF       OF       OF       OF       OF
SPAN    DIST       SLAB     GIRDER   GIRDER   SLAB     GIRDER   GIRDER
 #  TP  (ft)   LC  (psi)    (psi)    (psi)    (psi)    (psi)    (psi)
=== ==  ===.=  ==  =====.=  =====.=  =====.=  =====.=  =====.=  =====.=
***** Combination: NRL (6) *****************************************************
  1  0    0.0   6     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7   6    -97.5    -61.8    283.9      14.2     9.0    -41.4
  1  2    9.3   6   -175.8    -98.5    602.4      28.7    16.1    -98.4
  1  3   14.0   6   -230.4   -129.1    789.4      43.1    24.1   -147.6
  1  4   18.6   6   -258.7   -144.9    886.2      59.0    33.1   -202.3
  1  5   23.3   6   -253.6   -142.1    868.8      73.4    41.1   -251.5
  1  6   27.9   6   -223.9   -125.5    767.3      86.7    48.6   -297.1
  1  7   32.5   6   -163.3    -91.5    559.4     102.5    57.4   -351.1
  1  8   37.2   6    -89.2    -50.0    305.6     116.7    65.4   -399.7
  1  9   41.8   6     -3.7     -2.4     10.5     129.0    83.6   -363.1
  1 10   46.5   6    -29.6    -20.5     73.9     159.6   110.6   -398.5
 
  2  0   46.5   6    -36.1    -25.0     90.1     165.8   114.9   -414.2
  2  1   51.5   6     -9.9     -6.5     27.0     146.4    96.7   -398.9
  2  2   56.5   6    -98.4    -55.2    337.3     127.0    71.1   -435.1
  2  3   61.5   6   -166.1    -93.1    569.0     104.9    58.8   -359.4
  2  4   66.5   6   -207.3   -116.1    710.1      82.8    46.4   -283.7
  2  5   71.5   6   -218.3   -122.3    748.1      61.5    34.4   -210.6
  2  6   76.5   6   -204.4   -114.5    700.2      68.4    38.3   -234.3
  2  7   81.5   6   -160.7    -90.1    550.7      86.1    48.3   -295.1
  2  8   86.5   6    -92.0    -51.6    315.3     103.9    58.2   -355.9
  2  9   91.5   6     -5.0     -3.3     13.6     119.5    78.9   -325.5
  2 10   96.5   6    -47.6    -33.0    118.9     156.4   108.4   -390.7
 
  3  0   96.5   6    -50.0    -34.6    124.7     156.4   108.4   -390.7
  3  1  100.7   6     -0.0     -0.0      0.0     142.0    97.0   -364.6
  3  2  104.8   6    -71.4    -40.0    244.8     130.3    73.0   -446.5
  3  3  109.0   6   -139.7    -78.3    478.7     114.8    64.3   -393.2
  3  4  113.1   6   -196.4   -110.1    673.1      97.3    54.5   -333.2
  3  5  117.3   6   -222.9   -124.9    763.5      81.7    45.8   -279.9
  3  6  121.4   6   -228.7   -128.1    783.6      67.7    37.9   -232.0
  3  7  125.6   6   -207.4   -116.2    710.6      49.8    27.9   -170.6
  3  8  129.7   6   -160.4    -89.9    549.5      33.9    19.0   -116.0
  3  9  133.9   6    -93.3    -59.1    271.7      17.7    11.2    -51.7
  3 10  138.0   6     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: LEGAL_LANE (7) **********************************************
  1  0    0.0   7     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7   7    -56.5    -35.8    164.6       6.9     4.4    -20.1
  1  2    9.3   7    -91.2    -51.1    312.5      13.9     7.8    -47.7
  1  3   14.0   7   -110.1    -61.7    377.3      20.9    11.7    -71.5
  1  4   18.6   7   -117.2    -65.7    401.5      28.6    16.0    -98.0
  1  5   23.3   7   -122.2    -68.5    418.8      35.6    19.9   -121.8
  1  6   27.9   7   -111.0    -62.2    380.3      42.0    23.5   -143.9
  1  7   32.5   7    -84.2    -47.2    288.4      49.6    27.8   -170.1
  1  8   37.2   7    -49.5    -27.7    169.6      56.7    31.8   -194.4
  1  9   41.8   7     -4.0     -2.6     11.2      72.5    46.9   -203.9
  1 10   46.5   7    -14.7    -10.2     36.8     128.1    88.8   -319.9
 
  2  0   46.5   7    -17.3    -12.0     43.1     134.9    93.5   -336.8
  2  1   51.5   7     -9.0     -5.9     24.5      74.9    49.4   -203.9
  2  2   56.5   7    -52.0    -29.1    178.1      62.2    34.9   -213.2
  2  3   61.5   7    -81.7    -45.8    279.9      52.5    29.4   -179.8
  2  4   66.5   7    -94.1    -52.7    322.4      42.9    24.1   -147.1
  2  5   71.5   7    -92.3    -51.7    316.3      33.8    18.9   -115.9
  2  6   76.5   7    -92.0    -51.5    315.1      35.8    20.1   -122.8
  2  7   81.5   7    -78.9    -44.2    270.4      42.6    23.8   -145.8
  2  8   86.5   7    -48.6    -27.2    166.6      49.9    27.9   -170.8
  2  9   91.5   7     -5.6     -3.7     15.1      68.1    45.0   -185.4
  2 10   96.5   7    -23.3    -16.2     58.2     128.1    88.8   -319.9
 
  3  0   96.5   7    -24.5    -17.0     61.1     128.1    88.8   -319.9
  3  1  100.7   7     -6.2     -4.3     16.0      79.7    54.5   -204.7
  3  2  104.8   7    -44.1    -24.7    151.2      63.0    35.3   -215.7
  3  3  109.0   7    -74.3    -41.6    254.4      55.4    31.0   -189.7
  3  4  113.1   7    -98.0    -54.9    335.9      46.9    26.3   -160.8
  3  5  117.3   7   -107.3    -60.1    367.6      39.4    22.1   -135.1
  3  6  121.4   7   -102.4    -57.4    350.7      32.7    18.3   -112.0
  3  7  125.6   7    -92.6    -51.9    317.3      24.0    13.5    -82.3
  3  8  129.7   7    -78.6    -44.1    269.4      16.3     9.2    -56.0
  3  9  133.9   7    -51.8    -32.8    151.0       8.6     5.4    -24.9
  3 10  138.0   7     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: LEGAL_LANE_2 (8) ********************************************
  1  0    0.0   8     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7   8    -56.9    -36.1    165.7       6.9     4.4    -20.1
  1  2    9.3   8    -93.1    -52.1    318.8      13.9     7.8    -47.7
  1  3   14.0   8   -113.0    -63.3    387.2      20.9    11.7    -71.5
  1  4   18.6   8   -118.4    -66.4    405.7      28.6    16.0    -98.0
  1  5   23.3   8   -122.2    -68.5    418.8      35.6    19.9   -121.8
  1  6   27.9   8   -111.0    -62.2    380.3      42.0    23.5   -143.9
  1  7   32.5   8    -84.2    -47.2    288.4      49.6    27.8   -170.1
  1  8   37.2   8    -49.5    -27.7    169.6      57.8    32.4   -197.9
  1  9   41.8   8     -4.0     -2.6     11.2      83.2    53.9   -234.2
  1 10   46.5   8    -14.7    -10.2     36.8     128.5    89.1   -320.9
 
  2  0   46.5   8    -17.3    -12.0     43.1     134.9    93.5   -336.8
  2  1   51.5   8     -9.5     -6.3     25.8      82.6    54.6   -225.0
  2  2   56.5   8    -52.0    -29.1    178.1      62.2    34.9   -213.2
  2  3   61.5   8    -81.7    -45.8    279.9      52.5    29.4   -179.8
  2  4   66.5   8    -94.1    -52.7    322.4      42.9    24.1   -147.1
  2  5   71.5   8    -91.1    -51.0    312.1      33.8    18.9   -115.9
  2  6   76.5   8    -92.0    -51.5    315.1      35.8    20.1   -122.8
  2  7   81.5   8    -78.7    -44.1    269.7      42.6    23.8   -145.8
  2  8   86.5   8    -48.7    -27.3    167.0      49.9    27.9   -170.8
  2  9   91.5   8     -8.0     -5.3     21.8      70.0    46.3   -190.8
  2 10   96.5   8    -23.3    -16.2     58.2     128.1    88.8   -319.9
 
  3  0   96.5   8    -24.5    -17.0     61.1     128.1    88.8   -319.9
  3  1  100.7   8     -6.2     -4.3     16.0      83.1    56.8   -213.3
  3  2  104.8   8    -44.1    -24.7    151.2      61.6    34.5   -211.1
  3  3  109.0   8    -74.3    -41.6    254.4      53.9    30.2   -184.5
  3  4  113.1   8    -98.0    -54.9    335.9      45.6    25.6   -156.4
  3  5  117.3   8   -107.3    -60.1    367.6      38.3    21.5   -131.4
  3  6  121.4   8   -102.4    -57.4    350.7      31.8    17.8   -108.9
  3  7  125.6   8    -98.0    -54.9    335.7      23.4    13.1    -80.1
  3  8  129.7   8    -82.6    -46.3    283.0      15.9     8.9    -54.5
  3  9  133.9   8    -53.5    -33.9    155.9       8.3     5.3    -24.3
  3 10  138.0   8     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: TYPE_3 (9) **************************************************
  1  0    0.0   9     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7   9    -76.3    -48.3    222.2       9.0     5.7    -26.3
  1  2    9.3   9   -128.7    -72.1    441.1      18.3    10.2    -62.5
  1  3   14.0   9   -157.5    -88.3    539.7      27.4    15.3    -93.8
  1  4   18.6   9   -170.4    -95.5    583.7      37.5    21.0   -128.6
  1  5   23.3   9   -165.0    -92.5    565.4      46.6    26.1   -159.8
  1  6   27.9   9   -148.7    -83.3    509.5      55.1    30.9   -188.8
  1  7   32.5   9   -113.3    -63.5    388.3      65.1    36.5   -223.1
  1  8   37.2   9    -68.5    -38.4    234.7      74.1    41.5   -254.0
  1  9   41.8   9    -12.8     -8.3     36.0      82.0    53.1   -230.7
  1 10   46.5   9    -18.8    -13.0     47.0     101.0    70.0   -252.3
 
  2  0   46.5   9    -23.0    -15.9     57.3     104.9    72.7   -262.1
  2  1   51.5   9    -18.9    -12.5     51.4      92.6    61.2   -252.4
  2  2   56.5   9    -74.2    -41.6    254.1      80.3    45.0   -275.3
  2  3   61.5   9   -113.2    -63.4    387.8      66.4    37.2   -227.4
  2  4   66.5   9   -137.6    -77.1    471.3      52.4    29.4   -179.5
  2  5   71.5   9   -142.9    -80.1    489.7      38.9    21.8   -133.2
  2  6   76.5   9   -135.8    -76.1    465.3      43.5    24.4   -149.0
  2  7   81.5   9   -109.8    -61.5    376.2      54.8    30.7   -187.7
  2  8   86.5   9    -69.3    -38.8    237.4      66.1    37.0   -226.4
  2  9   91.5   9    -13.7     -9.0     37.3      76.0    50.2   -207.1
  2 10   96.5   9    -30.1    -20.9     75.2      99.4    68.9   -248.2
 
  3  0   96.5   9    -31.6    -21.9     78.9      99.4    68.9   -248.2
  3  1  100.7   9     -8.3     -5.7     21.2      90.2    61.6   -231.6
  3  2  104.8   9    -59.6    -33.4    204.3      82.8    46.4   -283.6
  3  3  109.0   9   -100.0    -56.0    342.5      72.9    40.8   -249.8
  3  4  113.1   9   -131.8    -73.8    451.5      61.8    34.6   -211.7
  3  5  117.3   9   -146.0    -81.8    500.3      51.9    29.1   -177.8
  3  6  121.4   9   -151.8    -85.0    520.0      43.0    24.1   -147.4
  3  7  125.6   9   -141.8    -79.5    485.9      31.6    17.7   -108.4
  3  8  129.7   9   -118.9    -66.6    407.3      21.5    12.1    -73.7
  3  9  133.9   9    -74.7    -47.3    217.5      11.3     7.1    -32.8
  3 10  138.0   9     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: TYPE_3S2 (10) ***********************************************
  1  0    0.0  10     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7  10    -71.0    -45.0    206.8       8.7     5.5    -25.4
  1  2    9.3  10   -116.1    -65.1    397.8      17.6     9.9    -60.5
  1  3   14.0  10   -143.5    -80.4    491.8      26.5    14.8    -90.7
  1  4   18.6  10   -154.6    -86.6    529.7      36.3    20.3   -124.3
  1  5   23.3  10   -150.7    -84.4    516.4      45.1    25.3   -154.5
  1  6   27.9  10   -133.8    -75.0    458.3      53.3    29.8   -182.5
  1  7   32.5  10   -103.9    -58.2    356.1      62.9    35.3   -215.7
  1  8   37.2  10    -59.0    -33.1    202.2      71.7    40.2   -245.5
  1  9   41.8  10     -0.1     -0.0      0.2      79.3    51.3   -223.0
  1 10   46.5  10    -16.5    -11.5     41.3     138.4    95.9   -345.8
 
  2  0   46.5  10    -20.2    -14.0     50.4     145.7   101.0   -363.9
  2  1   51.5  10     -6.0     -3.9     16.3      86.6    57.2   -235.9
  2  2   56.5  10    -64.2    -36.0    219.9      75.1    42.1   -257.3
  2  3   61.5  10   -106.5    -59.7    364.9      62.0    34.8   -212.5
  2  4   66.5  10   -127.0    -71.2    435.1      49.0    27.4   -167.8
  2  5   71.5  10   -128.3    -71.9    439.5      36.3    20.4   -124.5
  2  6   76.5  10   -125.3    -70.2    429.4      38.2    21.4   -131.0
  2  7   81.5  10   -103.3    -57.9    353.8      48.1    27.0   -165.0
  2  8   86.5  10    -59.4    -33.3    203.7      58.1    32.5   -199.0
  2  9   91.5  10     -0.0     -0.0      0.0      76.0    50.2   -207.0
  2 10   96.5  10    -28.1    -19.5     70.3     142.1    98.5   -354.9
 
  3  0   96.5  10    -29.5    -20.5     73.8     142.1    98.5   -354.9
  3  1  100.7  10     -1.5     -1.0      3.9      88.8    60.6   -227.8
  3  2  104.8  10    -52.4    -29.4    179.7      80.3    45.0   -275.0
  3  3  109.0  10    -87.3    -48.9    299.1      70.7    39.6   -242.1
  3  4  113.1  10   -117.0    -65.5    400.8      59.9    33.6   -205.2
  3  5  117.3  10   -135.0    -75.7    462.6      50.3    28.2   -172.4
  3  6  121.4  10   -139.6    -78.2    478.2      41.7    23.4   -142.9
  3  7  125.6  10   -130.0    -72.8    445.3      30.7    17.2   -105.1
  3  8  129.7  10   -107.6    -60.3    368.8      20.9    11.7    -71.5
  3  9  133.9  10    -67.2    -42.6    195.8      10.9     6.9    -31.8
  3 10  138.0  10     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: TYPE_3-3 (11) ***********************************************
  1  0    0.0  11     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7  11    -65.3    -41.4    190.3       7.6     4.8    -22.3
  1  2    9.3  11   -103.9    -58.2    355.9      15.4     8.7    -52.9
  1  3   14.0  11   -123.8    -69.4    424.3      23.2    13.0    -79.4
  1  4   18.6  11   -130.4    -73.1    446.8      31.7    17.8   -108.8
  1  5   23.3  11   -137.1    -76.8    469.7      39.5    22.1   -135.2
  1  6   27.9  11   -124.7    -69.9    427.3      46.6    26.1   -159.7
  1  7   32.5  11    -94.6    -53.0    324.3      55.1    30.9   -188.8
  1  8   37.2  11    -55.8    -31.3    191.3      62.7    35.1   -214.9
  1  9   41.8  11     -0.4     -0.3      1.1      77.5    50.2   -218.2
  1 10   46.5  11    -16.0    -11.1     39.9     139.5    96.7   -348.3
 
  2  0   46.5  11    -19.5    -13.5     48.7     146.9   101.8   -366.9
  2  1   51.5  11     -8.3     -5.5     22.5      80.1    52.9   -218.3
  2  2   56.5  11    -61.1    -34.2    209.3      69.5    38.9   -238.1
  2  3   61.5  11    -93.7    -52.5    320.9      57.4    32.2   -196.7
  2  4   66.5  11   -105.9    -59.3    362.7      45.3    25.4   -155.3
  2  5   71.5  11   -102.1    -57.2    350.0      33.6    18.8   -115.3
  2  6   76.5  11   -103.3    -57.9    354.1      36.9    20.7   -126.6
  2  7   81.5  11    -90.5    -50.7    310.2      46.5    26.1   -159.4
  2  8   86.5  11    -57.0    -31.9    195.3      56.1    31.5   -192.3
  2  9   91.5  11     -3.0     -2.0      8.1      73.9    48.8   -201.2
  2 10   96.5  11    -26.1    -18.1     65.1     140.6    97.4   -351.1
 
  3  0   96.5  11    -27.3    -18.9     68.3     140.6    97.4   -351.1
  3  1  100.7  11     -2.4     -1.6      6.1      86.7    59.2   -222.5
  3  2  104.8  11    -48.9    -27.4    167.4      69.7    39.1   -238.8
  3  3  109.0  11    -83.0    -46.5    284.2      61.4    34.4   -210.3
  3  4  113.1  11   -110.0    -61.6    376.9      52.0    29.1   -178.2
  3  5  117.3  11   -120.4    -67.5    412.6      43.7    24.5   -149.7
  3  6  121.4  11   -113.9    -63.8    390.3      36.2    20.3   -124.1
  3  7  125.6  11   -103.3    -57.9    354.0      26.6    14.9    -91.3
  3  8  129.7  11    -89.0    -49.9    305.1      18.1    10.1    -62.1
  3  9  133.9  11    -59.7    -37.9    174.0       9.5     6.0    -27.6
  3 10  138.0  11     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: OVERLOAD_1 (12) *********************************************
  1  0    0.0  12     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7  12    -75.1    -47.6    218.6       9.8     6.2    -28.6
  1  2    9.3  12   -124.2    -69.6    425.5      19.9    11.1    -68.1
  1  3   14.0  12   -154.9    -86.8    530.7      29.8    16.7   -102.1
  1  4   18.6  12   -167.9    -94.1    575.4      40.8    22.9   -139.9
  1  5   23.3  12   -163.3    -91.5    559.6      50.8    28.4   -173.9
  1  6   27.9  12   -146.8    -82.3    503.1      60.1    33.7   -205.9
  1  7   32.5  12   -108.3    -60.7    371.0      71.0    39.8   -243.3
  1  8   37.2  12    -58.1    -32.5    199.0      80.9    45.3   -277.0
  1  9   41.8  12     -0.0     -0.0      0.0      89.4    57.9   -251.7
  1 10   46.5  12    -20.0    -13.8     49.9     110.2    76.4   -275.2
 
  2  0   46.5  12    -24.5    -17.0     61.1     114.5    79.3   -285.9
  2  1   51.5  12     -2.0     -1.3      5.5     101.1    66.8   -275.3
  2  2   56.5  12    -65.0    -36.4    222.8      87.6    49.1   -300.3
  2  3   61.5  12   -109.1    -61.1    373.8      72.4    40.6   -248.0
  2  4   66.5  12   -135.3    -75.8    463.6      57.2    32.0   -195.8
  2  5   71.5  12   -140.7    -78.8    481.9      42.7    23.9   -146.4
  2  6   76.5  12   -133.5    -74.8    457.5      46.6    26.1   -159.7
  2  7   81.5  12   -105.4    -59.1    361.2      58.7    32.9   -201.2
  2  8   86.5  12    -59.7    -33.5    204.6      70.8    39.7   -242.6
  2  9   91.5  12     -0.0     -0.0      0.0      81.4    53.8   -221.9
  2 10   96.5  12    -32.9    -22.8     82.2     109.3    75.8   -273.1
 
  3  0   96.5  12    -34.9    -24.2     87.2     109.3    75.8   -273.1
  3  1  100.7  12     -0.0     -0.0      0.0      99.3    67.8   -254.8
  3  2  104.8  12    -48.9    -27.4    167.5      91.1    51.0   -312.1
  3  3  109.0  12    -94.1    -52.7    322.3      80.2    44.9   -274.8
  3  4  113.1  12   -128.8    -72.2    441.4      68.0    38.1   -232.9
  3  5  117.3  12   -142.9    -80.1    489.5      57.1    32.0   -195.6
  3  6  121.4  12   -147.7    -82.8    506.0      47.6    26.7   -163.0
  3  7  125.6  12   -138.5    -77.6    474.6      35.0    19.6   -119.8
  3  8  129.7  12   -113.3    -63.5    388.2      23.8    13.3    -81.5
  3  9  133.9  12    -72.7    -46.1    211.7      12.5     7.9    -36.3
  3 10  138.0  12     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: OVERLOAD_2 (13) *********************************************
  1  0    0.0  13     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7  13    -84.0    -53.2    244.5       9.2     5.9    -26.9
  1  2    9.3  13   -139.5    -78.2    477.9      18.7    10.5    -64.0
  1  3   14.0  13   -171.4    -96.1    587.4      28.0    15.7    -96.0
  1  4   18.6  13   -180.4   -101.1    618.1      38.4    21.5   -131.5
  1  5   23.3  13   -170.2    -95.4    583.1      47.7    26.7   -163.5
  1  6   27.9  13   -158.6    -88.9    543.5      56.5    31.7   -193.5
  1  7   32.5  13   -121.5    -68.1    416.4      66.8    37.4   -228.7
  1  8   37.2  13    -63.2    -35.4    216.5      77.6    43.5   -265.8
  1  9   41.8  13     -0.0     -0.0      0.0     129.4    83.8   -364.1
  1 10   46.5  13    -21.6    -15.0     53.9     209.7   145.4   -523.8
 
  2  0   46.5  13    -26.4    -18.3     66.0     219.5   152.1   -548.2
  2  1   51.5  13     -4.4     -2.9     12.0     133.8    88.4   -364.5
  2  2   56.5  13    -72.6    -40.7    248.8     100.2    56.2   -343.3
  2  3   61.5  13   -113.8    -63.7    389.8      82.8    46.4   -283.6
  2  4   66.5  13   -127.3    -71.3    436.2      65.3    36.6   -223.9
  2  5   71.5  13   -132.7    -74.4    454.7      48.9    27.4   -167.4
  2  6   76.5  13   -122.3    -68.5    419.0      50.4    28.2   -172.6
  2  7   81.5  13   -109.1    -61.1    373.7      63.5    35.6   -217.4
  2  8   86.5  13    -67.7    -37.9    232.0      76.5    42.9   -262.3
  2  9   91.5  13     -0.0     -0.0      0.0     116.7    77.1   -318.1
  2 10   96.5  13    -37.7    -26.1     94.0     213.3   147.8   -532.6
 
  3  0   96.5  13    -39.9    -27.7     99.7     213.3   147.8   -532.6
  3  1  100.7  13     -0.0     -0.0      0.0     141.9    96.9   -364.1
  3  2  104.8  13    -52.7    -29.5    180.6      83.3    46.7   -285.5
  3  3  109.0  13   -103.5    -58.0    354.6      73.4    41.1   -251.4
  3  4  113.1  13   -135.9    -76.2    465.8      62.2    34.8   -213.1
  3  5  117.3  13   -148.9    -83.5    510.3      52.2    29.3   -179.0
  3  6  121.4  13   -154.6    -86.6    529.6      43.5    24.4   -149.1
  3  7  125.6  13   -149.1    -83.6    510.9      32.0    17.9   -109.6
  3  8  129.7  13   -124.3    -69.6    425.8      21.8    12.2    -74.6
  3  9  133.9  13    -79.3    -50.3    231.0      11.4     7.2    -33.2
  3 10  138.0  13     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: EV2 (14) ****************************************************
  1  0    0.0  14     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7  14    -91.5    -58.0    266.4      10.6     6.7    -30.8
  1  2    9.3  14   -155.2    -86.9    531.6      21.3    12.0    -73.1
  1  3   14.0  14   -190.5   -106.8    652.8      32.0    17.9   -109.7
  1  4   18.6  14   -200.0   -112.1    685.2      43.9    24.6   -150.3
  1  5   23.3  14   -192.2   -107.7    658.6      54.5    30.6   -186.8
  1  6   27.9  14   -178.3    -99.9    611.0      64.4    36.1   -220.7
  1  7   32.5  14   -138.9    -77.8    476.0      76.1    42.7   -260.8
  1  8   37.2  14    -86.1    -48.2    294.9      86.7    48.6   -296.9
  1  9   41.8  14    -21.5    -13.9     60.5      95.8    62.1   -269.7
  1 10   46.5  14    -22.2    -15.4     55.4     118.3    82.0   -295.5
 
  2  0   46.5  14    -27.0    -18.7     67.6     122.9    85.2   -307.0
  2  1   51.5  14    -27.9    -18.4     76.1     108.5    71.7   -295.6
  2  2   56.5  14    -92.5    -51.8    316.8      94.1    52.7   -322.5
  2  3   61.5  14   -138.7    -77.7    475.4      77.7    43.6   -266.4
  2  4   66.5  14   -163.5    -91.6    560.3      61.4    34.4   -210.3
  2  5   71.5  14   -166.2    -93.1    569.3      45.5    25.5   -156.1
  2  6   76.5  14   -161.8    -90.7    554.3      51.3    28.7   -175.6
  2  7   81.5  14   -134.7    -75.5    461.6      64.6    36.2   -221.2
  2  8   86.5  14    -86.8    -48.7    297.5      77.9    43.6   -266.9
  2  9   91.5  14    -22.2    -14.6     60.4      89.6    59.2   -244.0
  2 10   96.5  14    -35.3    -24.4     88.1     116.2    80.5   -290.2
 
  3  0   96.5  14    -37.0    -25.7     92.5     116.2    80.5   -290.2
  3  1  100.7  14    -15.7    -10.7     40.4     105.5    72.1   -270.8
  3  2  104.8  14    -75.5    -42.3    258.6      96.8    54.2   -331.6
  3  3  109.0  14   -123.5    -69.2    423.1      85.2    47.8   -292.0
  3  4  113.1  14   -159.7    -89.5    547.3      72.2    40.5   -247.5
  3  5  117.3  14   -171.0    -95.8    585.9      60.7    34.0   -207.9
  3  6  121.4  14   -178.5   -100.0    611.4      50.3    28.2   -172.3
  3  7  125.6  14   -173.2    -97.0    593.3      37.0    20.7   -126.7
  3  8  129.7  14   -144.1    -80.7    493.8      25.2    14.1    -86.2
  3  9  133.9  14    -90.0    -57.1    262.2      13.2     8.4    -38.4
  3 10  138.0  14     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: EV3 (15) ****************************************************
  1  0    0.0  15     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7  15   -134.6    -85.3    392.1      15.7    10.0    -45.8
  1  2    9.3  15   -228.0   -127.7    781.1      31.8    17.8   -108.9
  1  3   14.0  15   -279.5   -156.6    957.7      47.7    26.7   -163.4
  1  4   18.6  15   -301.8   -169.1   1034.0      65.3    36.6   -223.9
  1  5   23.3  15   -293.2   -164.3   1004.4      81.2    45.5   -278.3
  1  6   27.9  15   -262.9   -147.3    900.7      96.0    53.8   -328.8
  1  7   32.5  15   -202.4   -113.4    693.5     113.4    63.5   -388.5
  1  8   37.2  15   -124.2    -69.6    425.5     129.1    72.3   -442.3
  1  9   41.8  15    -28.1    -18.2     79.1     142.8    92.5   -401.8
  1 10   46.5  15    -32.9    -22.8     82.3     176.0   121.9   -439.4
 
  2  0   46.5  15    -40.2    -27.8    100.4     182.8   126.7   -456.4
  2  1   51.5  15    -38.1    -25.2    103.8     161.3   106.6   -439.5
  2  2   56.5  15   -134.0    -75.1    459.0     139.9    78.4   -479.4
  2  3   61.5  15   -202.4   -113.4    693.6     115.6    64.8   -396.0
  2  4   66.5  15   -244.0   -136.7    835.8      91.2    51.1   -312.6
  2  5   71.5  15   -254.6   -142.6    872.2      67.7    37.9   -232.0
  2  6   76.5  15   -240.8   -134.9    825.0      76.2    42.7   -260.9
  2  7   81.5  15   -196.5   -110.1    673.2      95.9    53.8   -328.7
  2  8   86.5  15   -125.6    -70.4    430.3     115.7    64.8   -396.4
  2  9   91.5  15    -29.4    -19.4     80.0     133.1    87.9   -362.5
  2 10   96.5  15    -52.5    -36.4    131.0     173.0   119.9   -432.0
 
  3  0   96.5  15    -55.0    -38.1    137.5     173.0   119.9   -432.0
  3  1  100.7  15    -19.6    -13.4     50.3     157.0   107.3   -403.1
  3  2  104.8  15   -108.5    -60.8    371.7     144.1    80.7   -493.7
  3  3  109.0  15   -179.1   -100.4    613.7     126.9    71.1   -434.7
  3  4  113.1  15   -233.7   -130.9    800.6     107.5    60.3   -368.4
  3  5  117.3  15   -260.4   -145.9    892.3      90.3    50.6   -309.5
  3  6  121.4  15   -270.0   -151.3    925.1      74.9    42.0   -256.6
  3  7  125.6  15   -253.3   -141.9    867.9      55.1    30.9   -188.7
  3  8  129.7  15   -211.4   -118.4    724.1      37.4    21.0   -128.3
  3  9  133.9  15   -132.3    -83.8    385.2      19.6    12.4    -57.1
  3 10  138.0  15     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 
***** Combination: HL-93 (16) **************************************************
  1  0    0.0  16     -0.0     -0.0      0.0      -0.0    -0.0      0.0
  1  1    4.7  16   -147.9    -93.7    430.7      18.7    11.9    -54.5
  1  2    9.3  16   -249.9   -140.0    856.2      37.8    21.2   -129.6
  1  3   14.0  16   -305.8   -171.4   1047.9      56.7    31.8   -194.4
  1  4   18.6  16   -329.2   -184.5   1127.9      77.7    43.6   -266.4
  1  5   23.3  16   -322.1   -180.5   1103.4      96.7    54.2   -331.2
  1  6   27.9  16   -292.8   -164.1   1003.2     114.2    64.0   -391.2
  1  7   32.5  16   -221.7   -124.2    759.5     134.9    75.6   -462.3
  1  8   37.2  16   -142.3    -79.7    487.6     154.3    86.5   -528.7
  1  9   41.8  16    -60.8    -39.4    171.1     182.2   118.0   -512.6
  1 10   46.5  16    -39.6    -27.5     98.9     251.4   174.2   -627.8
 
  2  0   46.5  16    -46.1    -31.9    115.1     263.6   182.7   -658.3
  2  1   51.5  16    -62.7    -41.4    170.8     200.9   132.7   -547.4
  2  2   56.5  16   -144.8    -81.1    496.0     165.6    92.8   -567.5
  2  3   61.5  16   -216.1   -121.1    740.5     140.2    78.6   -480.5
  2  4   66.5  16   -264.1   -148.0    905.0     115.6    64.8   -396.0
  2  5   71.5  16   -273.7   -153.4    937.9      92.0    51.6   -315.3
  2  6   76.5  16   -260.9   -146.2    893.9      97.3    54.5   -333.2
  2  7   81.5  16   -209.9   -117.6    719.3     114.3    64.0   -391.6
  2  8   86.5  16   -137.8    -77.2    472.0     133.1    74.6   -456.1
  2  9   91.5  16    -59.1    -39.0    161.0     165.1   109.0   -449.7
  2 10   96.5  16    -62.0    -43.0    155.0     252.2   174.8   -629.8
 
  3  0   96.5  16    -65.1    -45.1    162.6     252.2   174.8   -629.8
  3  1  100.7  16    -53.7    -36.7    137.9     197.3   134.8   -506.4
  3  2  104.8  16   -128.5    -72.0    440.4     171.9    96.3   -589.1
  3  3  109.0  16   -198.9   -111.4    681.4     151.2    84.7   -518.1
  3  4  113.1  16   -258.0   -144.6    883.9     128.2    71.8   -439.1
  3  5  117.3  16   -286.2   -160.4    980.6     107.7    60.3   -368.8
  3  6  121.4  16   -291.9   -163.6   1000.0      89.2    50.0   -305.8
  3  7  125.6  16   -271.8   -152.3    931.3      65.6    36.8   -224.8
  3  8  129.7  16   -227.5   -127.5    779.4      44.6    25.0   -152.9
  3  9  133.9  16   -142.7    -90.4    415.6      23.4    14.8    -68.1
  3 10  138.0  16     -0.0     -0.0      0.0      -0.0    -0.0      0.0
 

* =============================================================================================================================
# [AR:UNFACTORED REACT]  5600  <Unfactored Reactions>
* ==================================================================================================================================
*
* TYPE KEYWORDS - DEAD = Dead Load Reactions
*                 SDL  = Superimposed Dead Load Reactions
*                 PS   = Prestress Reactions
*                 UNL  = Uniform Load of (1) KIP per FOOT across bridge
*                 Txxx = Truck Load Reactions, where "xxx" is the truck number.
*                 CBxx = Combination Reactions, where xx is the load combination number.
*                        Combinations include impact as specified in CARD 1050.
*
SUPPORT           MAXIMUM     MINIMUM
LOCATION          REACTION    REACTION
  (Ft)     TYPE   (K)         (K)          TRUCK NAME
====.==    ====  =====.===   =====.===     ========================================================================================
   0.00    DEAD     30.533
   0.00    SDLC      6.125
   0.00    SDLW      0.000
   0.00    UNL      17.857
   0.00    PS       -0.000
   0.00    T001     54.260      -5.524     HL-93_14_14_Truck
   0.00    T002     46.718      -4.541     HL-93_14_22_Truck
   0.00    T003     40.240      -3.430     HL-93_14_30_Truck
   0.00    T004     47.257      -4.543     HL-93_TANDEM
   0.00    T005     48.834      -4.971     HL-93_14_14_TRAIN
   0.00    T006     20.944      -2.823     UNIFORM_LANE_1KPF
   0.00    T007     40.084      -4.016     TYPE_3_Truck
   0.00    T008     39.015      -3.882     TYPE_3S2_Truck
   0.00    T009     36.308      -3.397     TYPE_3-3_Truck
   0.00    T010     51.262      -6.320     NRL_Truck
   0.00    T011     27.231      -2.548     LEGAL_LANE
   0.00    T012     27.231      -2.548     LEGAL_LANE_2
   0.00    T013     65.591      -7.112     OVERLOAD_1_Truck
   0.00    T014     74.909      -6.685     OVERLOAD_2_Truck
   0.00    T015     47.827      -4.694     EV2_Truck
   0.00    T016     70.522      -6.993     EV3_Truck
 
  46.50    DEAD     63.696
  46.50    SDLC     18.725
  46.50    SDLW      0.000
  46.50    UNL      54.421
  46.50    PS       -0.000
  46.50    T001     68.263      -7.462     HL-93_14_14_Truck
  46.50    T002     64.531      -5.822     HL-93_14_22_Truck
  46.50    T003     59.551      -4.747     HL-93_14_30_Truck
  46.50    T004     50.057      -6.462     HL-93_TANDEM
  46.50    T005     61.436      -6.716     HL-93_14_14_TRAIN
  46.50    T006     57.904      -3.501     UNIFORM_LANE_1KPF
  46.50    T007     48.082      -5.507     TYPE_3_Truck
  46.50    T008     61.861      -4.839     TYPE_3S2_Truck
  46.50    T009     63.097      -4.677     TYPE_3-3_Truck
  46.50    T010     76.801      -8.655     NRL_Truck
  46.50    T011     47.323      -3.508     LEGAL_LANE
  46.50    T012     47.323      -3.508     LEGAL_LANE_2
  46.50    T013     90.284      -9.510     OVERLOAD_1_Truck
  46.50    T014    148.808     -10.279     OVERLOAD_2_Truck
  46.50    T015     55.676      -6.490     EV2_Truck
  46.50    T016     82.994      -9.641     EV3_Truck
 
  96.50    DEAD     60.832
  96.50    SDLC     17.177
  96.50    SDLW      0.000
  96.50    UNL      50.079
  96.50    PS       -0.000
  96.50    T001     67.663      -9.776     HL-93_14_14_Truck
  96.50    T002     63.617      -7.912     HL-93_14_22_Truck
  96.50    T003     58.207      -6.056     HL-93_14_30_Truck
  96.50    T004     49.837      -8.084     HL-93_TANDEM
  96.50    T005     60.896      -8.798     HL-93_14_14_TRAIN
  96.50    T006     54.974      -4.903     UNIFORM_LANE_1KPF
  96.50    T007     47.680      -7.123     TYPE_3_Truck
  96.50    T008     60.686      -6.656     TYPE_3S2_Truck
  96.50    T009     61.409      -6.161     TYPE_3-3_Truck
  96.50    T010     76.189     -11.256     NRL_Truck
  96.50    T011     46.057      -4.621     LEGAL_LANE
  96.50    T012     46.057      -4.621     LEGAL_LANE_2
  96.50    T013     89.409     -12.615     OVERLOAD_1_Truck
  96.50    T014    143.477     -14.424     OVERLOAD_2_Truck
  96.50    T015     55.267      -8.343     EV2_Truck
  96.50    T016     82.309     -12.404     EV3_Truck
 
 138.00    DEAD     27.442
 138.00    SDLC      5.383
 138.00    SDLW      0.000
 138.00    UNL      15.644
 138.00    PS       -0.000
 138.00    T001     52.540      -6.735     HL-93_14_14_Truck
 138.00    T002     44.484      -5.547     HL-93_14_22_Truck
 138.00    T003     38.019      -4.184     HL-93_14_30_Truck
 138.00    T004     46.966      -5.527     HL-93_TANDEM
 138.00    T005     47.286      -6.061     HL-93_14_14_TRAIN
 138.00    T006     19.356      -3.451     UNIFORM_LANE_1KPF
 138.00    T007     39.097      -4.893     TYPE_3_Truck
 138.00    T008     36.356      -4.744     TYPE_3S2_Truck
 138.00    T009     33.383      -4.120     TYPE_3-3_Truck
 138.00    T010     48.999      -7.703     NRL_Truck
 138.00    T011     25.037      -3.090     LEGAL_LANE
 138.00    T012     25.435      -2.988     LEGAL_LANE_2
 138.00    T013     62.694      -8.677     OVERLOAD_1_Truck
 138.00    T014     70.107      -7.939     OVERLOAD_2_Truck
 138.00    T015     46.851      -5.721     EV2_Truck
 138.00    T016     68.979      -8.517     EV3_Truck
 

* =============================================================================================================================
# [AR:SPAN DL DISP]      5602  <Span static load vertical elastic displacements>
* ==================================================================================================================================
*  Values are for nearest integration point to actual tenth point.
*
                                                  DL+SDL
          X                              DL+SDL   +PS
SPAN      COOR.    DL     SDL    PS      +PS      +CREEP
 #    TP  (ft)     (in)   (in)   (in)    (in)     (in)
===   ==  ====.==  ==.==  ==.==  ==.==   ==.==    ==.==
  1    0     0.00   0.00   0.00   0.00    0.00     0.00
  1    1     4.65  -0.12  -0.01   0.07   -0.05    -0.16
  1    2     9.30  -0.23  -0.01   0.13   -0.10    -0.31
  1    3    13.95  -0.31  -0.01   0.18   -0.14    -0.43
  1    4    18.60  -0.37  -0.01   0.22   -0.17    -0.52
  1    5    23.25  -0.40  -0.01   0.23   -0.18    -0.55
  1    6    27.90  -0.38  -0.01   0.22   -0.17    -0.52
  1    7    32.55  -0.32  -0.01   0.19   -0.14    -0.43
  1    8    37.20  -0.24  -0.01   0.14   -0.10    -0.31
  1    9    41.85  -0.13  -0.00   0.08   -0.05    -0.16
  1   10    46.50  -0.01  -0.00   0.01   -0.01    -0.02
 
  2    0    46.50   0.00   0.00   0.00    0.00     0.00
  2    1    51.50  -0.16   0.00   0.09   -0.07    -0.22
  2    2    56.50  -0.31  -0.00   0.17   -0.14    -0.43
  2    3    61.50  -0.43  -0.00   0.23   -0.20    -0.59
  2    4    66.50  -0.50  -0.00   0.27   -0.23    -0.70
  2    5    71.50  -0.53  -0.01   0.28   -0.25    -0.75
  2    6    76.50  -0.50  -0.00   0.27   -0.24    -0.71
  2    7    81.50  -0.43  -0.00   0.23   -0.20    -0.60
  2    8    86.50  -0.31  -0.00   0.17   -0.14    -0.43
  2    9    91.50  -0.16  -0.00   0.09   -0.07    -0.22
  2   10    96.50  -0.00   0.00   0.00   -0.00    -0.00
 
  3    0    96.50   0.00   0.00   0.00    0.00     0.00
  3    1   100.65  -0.08  -0.00   0.05   -0.03    -0.08
  3    2   104.80  -0.14  -0.00   0.09   -0.06    -0.17
  3    3   108.95  -0.20  -0.01   0.12   -0.08    -0.24
  3    4   113.10  -0.24  -0.01   0.15   -0.10    -0.30
  3    5   117.25  -0.25  -0.01   0.15   -0.11    -0.32
  3    6   121.40  -0.24  -0.01   0.15   -0.10    -0.31
  3    7   125.55  -0.21  -0.01   0.13   -0.09    -0.26
  3    8   129.70  -0.15  -0.01   0.10   -0.06    -0.19
  3    9   133.85  -0.08  -0.00   0.05   -0.03    -0.10
  3   10   138.00   0.00   0.00   0.00    0.00     0.00
 

* =============================================================================================================================
# [AR:SPAN LL DISP]      5603  <Span live load vertical elastic displacements>
* ==================================================================================================================================
* NOTES: See 5602 output for tenth point coordinates.
*        LC = Load Combination
*        Deflections factored with: Impact, Lane load reduction, and Lane multiplier.
*        Values are for nearest integration point to actual tenth point.
*
*
SPAN      MIN   -----------  Tenth point deflections ( Inches ) ----------------
 #    LC  MAX    0     1     2     3     4     5     6     7     8     9    10
===   ==  ===  ==.== ==.== ==.== ==.== ==.== ==.== ==.== ==.== ==.== ==.== ==.==
***** Combination: HL-93_14_14 (1) *********************************************
  1    1  MAX   0.00  0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00
  1    1  MIN   0.00 -0.01 -0.08 -0.15 -0.17 -0.18 -0.16 -0.13 -0.02 -0.01 -0.00
 
  2    1  MAX   0.00  0.01  0.02  0.02  0.02  0.02  0.02  0.02  0.01  0.01  0.00
  2    1  MIN   0.00 -0.01 -0.02 -0.12 -0.15 -0.15 -0.15 -0.12 -0.02 -0.01  0.00
 
  3    1  MAX   0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00  0.00
  3    1  MIN   0.00 -0.01 -0.01 -0.02 -0.11 -0.12 -0.12 -0.11 -0.02 -0.01  0.00
 
 
***** Combination: HL-93_14_22 (2) *********************************************
  1    2  MAX   0.00  0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00
  1    2  MIN   0.00 -0.01 -0.07 -0.12 -0.14 -0.14 -0.13 -0.11 -0.02 -0.01 -0.00
 
  2    2  MAX   0.00  0.01  0.02  0.02  0.02  0.02  0.02  0.02  0.01  0.01  0.00
  2    2  MIN   0.00 -0.01 -0.02 -0.10 -0.12 -0.13 -0.12 -0.10 -0.02 -0.01  0.00
 
  3    2  MAX   0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00  0.00
  3    2  MIN   0.00 -0.01 -0.01 -0.02 -0.09 -0.10 -0.10 -0.09 -0.02 -0.01  0.00
 
 
***** Combination: HL-93_14_30 (3) *********************************************
  1    3  MAX   0.00  0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00
  1    3  MIN   0.00 -0.01 -0.06 -0.11 -0.12 -0.13 -0.12 -0.09 -0.02 -0.01 -0.00
 
  2    3  MAX   0.00  0.01  0.02  0.02  0.02  0.02  0.02  0.02  0.01  0.01  0.00
  2    3  MIN   0.00 -0.01 -0.02 -0.08 -0.10 -0.10 -0.10 -0.08 -0.02 -0.01  0.00
 
  3    3  MAX   0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00  0.00
  3    3  MIN   0.00 -0.01 -0.01 -0.02 -0.08 -0.09 -0.09 -0.08 -0.02 -0.01  0.00
 
 
***** Combination: HL-93_tandem (4) ********************************************
  1    4  MAX   0.00  0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00
  1    4  MIN   0.00 -0.01 -0.07 -0.13 -0.15 -0.16 -0.14 -0.12 -0.02 -0.01 -0.00
 
  2    4  MAX   0.00  0.01  0.02  0.02  0.02  0.02  0.02  0.02  0.01  0.01  0.00
  2    4  MIN   0.00 -0.01 -0.02 -0.11 -0.13 -0.14 -0.13 -0.11 -0.02 -0.01  0.00
 
  3    4  MAX   0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00  0.00
  3    4  MIN   0.00 -0.01 -0.01 -0.02 -0.11 -0.12 -0.11 -0.10 -0.02 -0.01  0.00
 
 
***** Combination: HL-93_14_14_train (5) ***************************************
  1    5  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1    5  MIN   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
 
  2    5  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2    5  MIN   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
 
  3    5  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3    5  MIN   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
 
 
***** Combination: NRL (6) *****************************************************
  1    6  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1    6  MIN   0.00  0.00 -0.05 -0.11 -0.13 -0.13 -0.12 -0.10  0.00  0.00  0.00
 
  2    6  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2    6  MIN   0.00  0.00  0.00 -0.09 -0.11 -0.12 -0.11 -0.09  0.00  0.00  0.00
 
  3    6  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3    6  MIN   0.00  0.00  0.00  0.00 -0.09 -0.10 -0.09 -0.08  0.00  0.00  0.00
 
 
***** Combination: LEGAL_LANE (7) **********************************************
  1    7  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1    7  MIN   0.00 -0.00 -0.03 -0.05 -0.06 -0.06 -0.06 -0.05 -0.01 -0.00 -0.00
 
  2    7  MAX   0.00  0.00  0.00  0.01  0.01  0.01  0.01  0.01  0.00  0.00  0.00
  2    7  MIN   0.00 -0.00 -0.01 -0.04 -0.05 -0.05 -0.05 -0.04 -0.01 -0.00  0.00
 
  3    7  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3    7  MIN   0.00 -0.00 -0.00 -0.01 -0.04 -0.05 -0.04 -0.04 -0.01 -0.00  0.00
 
 
***** Combination: LEGAL_LANE_2 (8) ********************************************
  1    8  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1    8  MIN   0.00 -0.00 -0.03 -0.05 -0.06 -0.06 -0.06 -0.05 -0.01 -0.00 -0.00
 
  2    8  MAX   0.00  0.00  0.00  0.01  0.01  0.01  0.01  0.01  0.00  0.00  0.00
  2    8  MIN   0.00 -0.00 -0.01 -0.04 -0.05 -0.05 -0.05 -0.04 -0.01 -0.00  0.00
 
  3    8  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3    8  MIN   0.00 -0.00 -0.00 -0.01 -0.04 -0.05 -0.04 -0.04 -0.01 -0.00  0.00
 
 
***** Combination: TYPE_3 (9) **************************************************
  1    9  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1    9  MIN   0.00  0.00 -0.03 -0.07 -0.08 -0.08 -0.08 -0.06  0.00  0.00  0.00
 
  2    9  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2    9  MIN   0.00  0.00  0.00 -0.06 -0.07 -0.07 -0.07 -0.06  0.00  0.00  0.00
 
  3    9  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3    9  MIN   0.00  0.00  0.00  0.00 -0.06 -0.06 -0.06 -0.05  0.00  0.00  0.00
 
 
***** Combination: TYPE_3S2 (10) ***********************************************
  1   10  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1   10  MIN   0.00  0.00 -0.03 -0.06 -0.07 -0.08 -0.07 -0.06  0.00  0.00  0.00
 
  2   10  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2   10  MIN   0.00  0.00  0.00 -0.06 -0.07 -0.07 -0.07 -0.06  0.00  0.00  0.00
 
  3   10  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3   10  MIN   0.00  0.00  0.00  0.00 -0.05 -0.05 -0.05 -0.05  0.00  0.00  0.00
 
 
***** Combination: TYPE_3-3 (11) ***********************************************
  1   11  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1   11  MIN   0.00  0.00 -0.03 -0.06 -0.07 -0.07 -0.07 -0.05  0.00  0.00  0.00
 
  2   11  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2   11  MIN   0.00  0.00  0.00 -0.05 -0.05 -0.06 -0.05 -0.05  0.00  0.00  0.00
 
  3   11  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3   11  MIN   0.00  0.00  0.00  0.00 -0.05 -0.05 -0.05 -0.04  0.00  0.00  0.00
 
 
***** Combination: OVERLOAD_1 (12) *********************************************
  1   12  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1   12  MIN   0.00  0.00 -0.04 -0.08 -0.09 -0.09 -0.08 -0.07  0.00  0.00  0.00
 
  2   12  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2   12  MIN   0.00  0.00  0.00 -0.06 -0.08 -0.08 -0.08 -0.06  0.00  0.00  0.00
 
  3   12  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3   12  MIN   0.00  0.00  0.00  0.00 -0.06 -0.06 -0.06 -0.06  0.00  0.00  0.00
 
 
***** Combination: OVERLOAD_2 (13) *********************************************
  1   13  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1   13  MIN   0.00  0.00 -0.04 -0.08 -0.10 -0.10 -0.09 -0.08  0.00  0.00  0.00
 
  2   13  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2   13  MIN   0.00  0.00  0.00 -0.06 -0.07 -0.07 -0.06 -0.05  0.00  0.00  0.00
 
  3   13  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3   13  MIN   0.00  0.00  0.00  0.00 -0.06 -0.07 -0.07 -0.06  0.00  0.00  0.00
 
 
***** Combination: EV2 (14) ****************************************************
  1   14  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1   14  MIN   0.00  0.00 -0.04 -0.08 -0.10 -0.10 -0.09 -0.07  0.00  0.00  0.00
 
  2   14  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2   14  MIN   0.00  0.00  0.00 -0.07 -0.08 -0.09 -0.08 -0.07  0.00  0.00  0.00
 
  3   14  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3   14  MIN   0.00  0.00  0.00  0.00 -0.07 -0.07 -0.07 -0.06  0.00  0.00  0.00
 
 
***** Combination: EV3 (15) ****************************************************
  1   15  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  1   15  MIN   0.00  0.00 -0.06 -0.12 -0.14 -0.15 -0.14 -0.11  0.00  0.00  0.00
 
  2   15  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  2   15  MIN   0.00  0.00  0.00 -0.10 -0.13 -0.13 -0.12 -0.10  0.00  0.00  0.00
 
  3   15  MAX   0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00  0.00
  3   15  MIN   0.00  0.00  0.00  0.00 -0.10 -0.11 -0.10 -0.09  0.00  0.00  0.00
 
 
***** Combination: HL-93 (16) **************************************************
  1   16  MAX   0.00  0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00
  1   16  MIN   0.00 -0.01 -0.08 -0.15 -0.17 -0.18 -0.16 -0.13 -0.02 -0.01 -0.00
 
  2   16  MAX   0.00  0.01  0.02  0.02  0.02  0.02  0.02  0.02  0.01  0.01  0.00
  2   16  MIN   0.00 -0.01 -0.02 -0.12 -0.15 -0.15 -0.15 -0.12 -0.02 -0.01  0.00
 
  3   16  MAX   0.00  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.01  0.00  0.00
  3   16  MIN   0.00 -0.01 -0.01 -0.02 -0.11 -0.12 -0.12 -0.11 -0.02 -0.01  0.00
 
 

* =============================================================================================================================
# [AR:LOAD RATINGS-LRFR] 5700B <Load Rating Factors per AASHTO Criteria>
* ==================================================================================================================================
* NOTES:
* 1) Controlling Ratings are computed as follows:
*      SHEAR   The value of vertical shear rating.
*      MOMENT  1) Conventionally reinforced bridges are controlled by the Ultimate rating.
*              2) Prestress bridges are controlled by either the LESSER of the SERVICE LOAD rating or ULTIMATE rating.
*
* 2) THE FOLLOWING SYMBOLS MEAN:
*       N/A -- No value computed
*       INF -- Value is a large positive number out of range for this printout
*       NEG -- Value is a large negative number out of range for this printout
*
* 3) Values are for nearest integration point to actual tenth point.
*

SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
 
***** Combination: NRL (6) -- LEGAL rating *************************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1       3.5   6   WORST CASE LEGAL SHEAR RATING =           1.42
* 1      20.5   6   WORST CASE LEGAL MOMENT RATING =          2.45
* 1      20.5   6   WORST CASE LEGAL SVC MOMENT RATING =      1.65
  1  0    0.0   6    5.06          INF        N/C
  1  1    4.7   6    1.81          3.97       5.19
  1  2    9.3   6    2.40          3.61       2.62
  1  3   14.0   6    3.59          2.80       1.98
  1  4   18.6   6    5.18          2.49       1.69
  1  5   23.3   6    4.60          2.51       1.66
  1  6   27.9   6    2.97          2.90       1.98
  1  7   32.5   6    2.35          4.07       2.92
  1  8   37.2   6    1.76          5.01       4.50
  1  9   41.8   6    6.40          4.47       5.16
  1 10   46.5   6    5.66          2.72       N/C
 
 
***** Combination: NRL (6) -- LEGAL rating *************************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0   6   WORST CASE LEGAL SHEAR RATING =           1.79
* 2       0.5   6   WORST CASE LEGAL MOMENT RATING =          2.67
* 2      25.0   6   WORST CASE LEGAL SVC MOMENT RATING =      2.08
  2  0   46.5   6    N/C           N/C        N/C
  2  1   51.5   6    2.68          4.21       4.82
  2  2   56.5   6    2.04          4.88       4.13
  2  3   61.5   6    2.98          4.48       3.01
  2  4   66.5   6    3.84          3.56       2.31
  2  5   71.5   6    6.23          3.32       2.08
  2  6   76.5   6    3.71          3.60       2.33
  2  7   81.5   6    2.91          4.61       3.09
  2  8   86.5   6    2.01          6.01       5.08
  2  9   91.5   6    2.65          5.21       5.94
  2 10   96.5   6    N/C           N/C        N/C
 
 
***** Combination: NRL (6) -- LEGAL rating *************************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      37.5   6   WORST CASE LEGAL SHEAR RATING =           1.35
* 3      23.0   6   WORST CASE LEGAL MOMENT RATING =          2.26
* 3      23.0   6   WORST CASE LEGAL SVC MOMENT RATING =      1.72
  3  0   96.5   6    N/C           N/C        N/C
  3  1  100.7   6    4.26          3.65       5.48
  3  2  104.8   6    1.82          4.17       4.21
  3  3  109.0   6    2.44          3.86       3.10
  3  4  113.1   6    3.08          2.70       2.10
  3  5  117.3   6    4.52          2.32       1.76
  3  6  121.4   6    6.04          2.28       1.76
  3  7  125.6   6    3.96          2.54       2.01
  3  8  129.7   6    2.62          3.21       2.59
  3  9  133.9   6    1.52          3.38       4.81
  3 10  138.0   6    7.61          INF        N/C
 
 
***** Combination: LEGAL_LANE (7) -- LEGAL rating ******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      39.0   7   WORST CASE LEGAL SHEAR RATING =           2.88
* 1      46.0   7   WORST CASE LEGAL MOMENT RATING =          3.39
* 1      23.0   7   WORST CASE LEGAL SVC MOMENT RATING =      3.45
  1  0    0.0   7    8.62          INF        N/C
  1  1    4.7   7    4.70          6.86       8.95
  1  2    9.3   7    4.37          6.95       5.06
  1  3   14.0   7    6.57          5.86       4.14
  1  4   18.6   7    9.41          5.49       3.74
  1  5   23.3   7    7.09          5.20       3.45
  1  6   27.9   7    5.04          5.85       4.00
  1  7   32.5   7    4.20          7.89       5.66
  1  8   37.2   7    3.16         10.29       9.25
  1  9   41.8   7   11.17          7.95       9.19
  1 10   46.5   7   10.14          3.39       N/C
 
 
***** Combination: LEGAL_LANE (7) -- LEGAL rating ******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0   7   WORST CASE LEGAL SHEAR RATING =           3.15
* 2       0.5   7   WORST CASE LEGAL MOMENT RATING =          3.41
* 2      25.0   7   WORST CASE LEGAL SVC MOMENT RATING =      4.93
  2  0   46.5   7    N/C           N/C        N/C
  2  1   51.5   7    4.60          8.23       9.42
  2  2   56.5   7    3.66          9.96       8.42
  2  3   61.5   7    5.13          9.10       6.11
  2  4   66.5   7    5.98          7.84       5.08
  2  5   71.5   7    8.74          7.85       4.93
  2  6   76.5   7    6.13          8.01       5.18
  2  7   81.5   7    5.21          9.38       6.29
  2  8   86.5   7    3.68         12.53       9.91
  2  9   91.5   7    4.59          9.15      10.43
  2 10   96.5   7    N/C           N/C        N/C
 
 
***** Combination: LEGAL_LANE (7) -- LEGAL rating ******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3       8.0   7   WORST CASE LEGAL SHEAR RATING =           3.28
* 3       0.5   7   WORST CASE LEGAL MOMENT RATING =          3.59
* 3      21.0   7   WORST CASE LEGAL SVC MOMENT RATING =      3.64
  3  0   96.5   7    N/C           N/C        N/C
  3  1  100.7   7   13.36          6.50       9.76
  3  2  104.8   7    3.28          8.63       8.72
  3  3  109.0   7    4.29          7.26       5.82
  3  4  113.1   7    5.08          5.41       4.20
  3  5  117.3   7    6.50          4.83       3.65
  3  6  121.4   7    9.33          5.10       3.92
  3  7  125.6   7    7.27          5.69       4.51
  3  8  129.7   7    5.04          6.54       5.28
  3  9  133.9   7    5.41          6.09       8.65
  3 10  138.0   7   14.54          INF        N/C
 
 
***** Combination: LEGAL_LANE_2 (8) -- LEGAL rating ****************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      39.0   8   WORST CASE LEGAL SHEAR RATING =           2.81
* 1      46.0   8   WORST CASE LEGAL MOMENT RATING =          3.38
* 1      23.0   8   WORST CASE LEGAL SVC MOMENT RATING =      3.45
  1  0    0.0   8    8.58          INF        N/C
  1  1    4.7   8    4.67          6.81       8.89
  1  2    9.3   8    4.28          6.81       4.96
  1  3   14.0   8    6.33          5.71       4.04
  1  4   18.6   8    8.55          5.43       3.70
  1  5   23.3   8    6.24          5.20       3.45
  1  6   27.9   8    4.63          5.85       4.00
  1  7   32.5   8    3.99          7.89       5.66
  1  8   37.2   8    3.07         10.11       9.09
  1  9   41.8   8   10.96          6.92       8.00
  1 10   46.5   8    9.93          3.38       N/C
 
 
***** Combination: LEGAL_LANE_2 (8) -- LEGAL rating ****************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0   8   WORST CASE LEGAL SHEAR RATING =           2.96
* 2       0.5   8   WORST CASE LEGAL MOMENT RATING =          3.41
* 2      22.5   8   WORST CASE LEGAL SVC MOMENT RATING =      4.93
  2  0   46.5   8    N/C           N/C        N/C
  2  1   51.5   8    4.35          7.46       8.54
  2  2   56.5   8    3.37          9.96       8.42
  2  3   61.5   8    4.78          9.10       6.11
  2  4   66.5   8    5.73          7.84       5.08
  2  5   71.5   8    8.10          7.96       4.99
  2  6   76.5   8    6.10          8.01       5.18
  2  7   81.5   8    4.95          9.41       6.30
  2  8   86.5   8    3.45         12.53       9.89
  2  9   91.5   8    4.45          8.89      10.14
  2 10   96.5   8    N/C           N/C        N/C
 
 
***** Combination: LEGAL_LANE_2 (8) -- LEGAL rating ****************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3       8.0   8   WORST CASE LEGAL SHEAR RATING =           3.19
* 3       0.5   8   WORST CASE LEGAL MOMENT RATING =          3.59
* 3      21.0   8   WORST CASE LEGAL SVC MOMENT RATING =      3.64
  3  0   96.5   8    N/C           N/C        N/C
  3  1  100.7   8   13.13          6.24       9.37
  3  2  104.8   8    3.19          8.82       8.91
  3  3  109.0   8    4.06          7.26       5.82
  3  4  113.1   8    4.74          5.41       4.20
  3  5  117.3   8    6.17          4.83       3.65
  3  6  121.4   8    8.11          5.10       3.92
  3  7  125.6   8    7.07          5.38       4.26
  3  8  129.7   8    4.78          6.23       5.02
  3  9  133.9   8    5.24          5.90       8.38
  3 10  138.0   8   14.07          INF        N/C
 
 
***** Combination: TYPE_3 (9) -- LEGAL rating **********************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      39.0   9   WORST CASE LEGAL SHEAR RATING =           2.18
* 1      20.5   9   WORST CASE LEGAL MOMENT RATING =          3.76
* 1      20.5   9   WORST CASE LEGAL SVC MOMENT RATING =      2.52
  1  0    0.0   9    6.34          INF        N/C
  1  1    4.7   9    3.40          5.08       6.63
  1  2    9.3   9    2.93          4.92       3.58
  1  3   14.0   9    4.09          4.10       2.90
  1  4   18.6   9    5.31          3.77       2.57
  1  5   23.3   9    4.84          3.85       2.56
  1  6   27.9   9    3.50          4.36       2.99
  1  7   32.5   9    2.98          5.86       4.21
  1  8   37.2   9    2.32          7.88       7.08
  1  9   41.8   9    8.96          7.03       8.12
  1 10   46.5   9    8.07          4.29       N/C
 
 
***** Combination: TYPE_3 (9) -- LEGAL rating **********************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0   9   WORST CASE LEGAL SHEAR RATING =           2.32
* 2       0.5   9   WORST CASE LEGAL MOMENT RATING =          4.23
* 2      25.0   9   WORST CASE LEGAL SVC MOMENT RATING =      3.18
  2  0   46.5   9    N/C           N/C        N/C
  2  1   51.5   9    3.60          6.65       7.61
  2  2   56.5   9    2.61          7.71       6.52
  2  3   61.5   9    3.60          6.57       4.41
  2  4   66.5   9    4.26          5.36       3.47
  2  5   71.5   9    6.07          5.07       3.18
  2  6   76.5   9    4.16          5.42       3.51
  2  7   81.5   9    3.55          6.75       4.52
  2  8   86.5   9    2.58          9.45       6.96
  2  9   91.5   9    3.57          8.19       9.34
  2 10   96.5   9    N/C           N/C        N/C
 
 
***** Combination: TYPE_3 (9) -- LEGAL rating **********************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      38.5   9   WORST CASE LEGAL SHEAR RATING =           1.44
* 3      23.0   9   WORST CASE LEGAL MOMENT RATING =          3.44
* 3      23.0   9   WORST CASE LEGAL SVC MOMENT RATING =      2.62
  3  0   96.5   9    N/C           N/C        N/C
  3  1  100.7   9    7.81          5.75       8.63
  3  2  104.8   9    2.35          6.56       6.63
  3  3  109.0   9    3.03          5.39       4.33
  3  4  113.1   9    3.61          4.02       3.12
  3  5  117.3   9    4.87          3.55       2.68
  3  6  121.4   9    5.71          3.44       2.65
  3  7  125.6   9    4.40          3.72       2.95
  3  8  129.7   9    3.15          4.33       3.49
  3  9  133.9   9    2.68          4.22       6.00
  3 10  138.0   9    9.61          INF        N/C
 
 
***** Combination: TYPE_3S2 (10) -- LEGAL rating *******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      39.0  10   WORST CASE LEGAL SHEAR RATING =           2.28
* 1      46.0  10   WORST CASE LEGAL MOMENT RATING =          3.13
* 1      20.5  10   WORST CASE LEGAL SVC MOMENT RATING =      2.75
  1  0    0.0  10    6.77          INF        N/C
  1  1    4.7  10    3.65          5.46       7.12
  1  2    9.3  10    3.28          5.46       3.97
  1  3   14.0  10    4.55          4.50       3.18
  1  4   18.6  10    5.81          4.16       2.83
  1  5   23.3  10    5.15          4.22       2.80
  1  6   27.9  10    3.69          4.85       3.32
  1  7   32.5  10    3.16          6.39       4.59
  1  8   37.2  10    2.49          8.15       7.32
  1  9   41.8  10    9.04          7.27       8.40
  1 10   46.5  10    8.09          3.13       N/C
 
 
***** Combination: TYPE_3S2 (10) -- LEGAL rating *******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0  10   WORST CASE LEGAL SHEAR RATING =           2.43
* 2       0.5  10   WORST CASE LEGAL MOMENT RATING =          3.15
* 2      25.0  10   WORST CASE LEGAL SVC MOMENT RATING =      3.54
  2  0   46.5  10    N/C           N/C        N/C
  2  1   51.5  10    3.67          7.11       8.15
  2  2   56.5  10    2.70          8.25       6.98
  2  3   61.5  10    3.67          6.98       4.69
  2  4   66.5  10    4.40          5.81       3.76
  2  5   71.5  10    6.74          5.65       3.54
  2  6   76.5  10    4.34          5.88       3.80
  2  7   81.5  10    3.66          7.17       4.80
  2  8   86.5  10    2.71         10.76       8.11
  2  9   91.5  10    3.64          8.19       9.35
  2 10   96.5  10    N/C           N/C        N/C
 
 
***** Combination: TYPE_3S2 (10) -- LEGAL rating *******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      38.5  10   WORST CASE LEGAL SHEAR RATING =           1.85
* 3       0.5  10   WORST CASE LEGAL MOMENT RATING =          3.23
* 3      23.0  10   WORST CASE LEGAL SVC MOMENT RATING =      2.83
  3  0   96.5  10    N/C           N/C        N/C
  3  1  100.7  10    8.90          5.84       8.77
  3  2  104.8  10    2.46          6.77       6.84
  3  3  109.0  10    3.09          6.18       4.95
  3  4  113.1  10    3.61          4.53       3.52
  3  5  117.3  10    4.82          3.84       2.90
  3  6  121.4  10    6.15          3.74       2.88
  3  7  125.6  10    4.82          4.06       3.21
  3  8  129.7  10    3.50          4.78       3.86
  3  9  133.9  10    3.68          4.69       6.67
  3 10  138.0  10   10.82          INF        N/C
 
 
***** Combination: TYPE_3-3 (11) -- LEGAL rating *******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      39.0  11   WORST CASE LEGAL SHEAR RATING =           2.47
* 1      46.0  11   WORST CASE LEGAL MOMENT RATING =          3.11
* 1      23.0  11   WORST CASE LEGAL SVC MOMENT RATING =      3.08
  1  0    0.0  11    7.34          INF        N/C
  1  1    4.7  11    3.98          5.93       7.74
  1  2    9.3  11    3.68          6.10       4.44
  1  3   14.0  11    5.54          5.21       3.69
  1  4   18.6  11    7.96          4.93       3.36
  1  5   23.3  11    6.00          4.63       3.08
  1  6   27.9  11    4.26          5.20       3.56
  1  7   32.5  11    3.58          7.02       5.04
  1  8   37.2  11    2.71          9.31       8.37
  1  9   41.8  11    9.67          7.43       8.59
  1 10   46.5  11    8.69          3.11       N/C
 
 
***** Combination: TYPE_3-3 (11) -- LEGAL rating *******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0  11   WORST CASE LEGAL SHEAR RATING =           2.72
* 2       0.5  11   WORST CASE LEGAL MOMENT RATING =          3.13
* 2      22.5  11   WORST CASE LEGAL SVC MOMENT RATING =      4.43
  2  0   46.5  11    N/C           N/C        N/C
  2  1   51.5  11    4.00          7.69       8.80
  2  2   56.5  11    3.18          8.92       7.54
  2  3   61.5  11    4.44          7.94       5.33
  2  4   66.5  11    5.14          6.97       4.51
  2  5   71.5  11    7.58          7.09       4.45
  2  6   76.5  11    5.24          7.13       4.61
  2  7   81.5  11    4.48          8.18       5.48
  2  8   86.5  11    3.19         11.13       8.45
  2  9   91.5  11    3.97          8.43       9.61
  2 10   96.5  11    N/C           N/C        N/C
 
 
***** Combination: TYPE_3-3 (11) -- LEGAL rating *******************************
 
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      38.5  11   WORST CASE LEGAL SHEAR RATING =           2.42
* 3       0.5  11   WORST CASE LEGAL MOMENT RATING =          3.28
* 3      21.0  11   WORST CASE LEGAL SVC MOMENT RATING =      3.24
  3  0   96.5  11    N/C           N/C        N/C
  3  1  100.7  11   10.78          5.98       8.98
  3  2  104.8  11    2.81          7.80       7.88
  3  3  109.0  11    3.65          6.50       5.21
  3  4  113.1  11    4.31          4.82       3.74
  3  5  117.3  11    5.49          4.30       3.25
  3  6  121.4  11    7.91          4.59       3.53
  3  7  125.6  11    6.14          5.10       4.04
  3  8  129.7  11    4.27          5.78       4.66
  3  9  133.9  11    4.60          5.28       7.51
  3 10  138.0  11   12.22          INF        N/C
 
 
***** Combination: OVERLOAD_1 (12) -- PERMIT rating ****************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      39.0  12   WORST CASE PERMIT SHEAR RATING =          2.35
* 1      20.5  12   WORST CASE PERMIT MOMENT RATING =         4.60
* 1      20.5  12   WORST CASE PERMIT SVC MOMENT RATING =     2.68
  1  0    0.0  12    7.04           INF       N/C
  1  1    4.7  12    3.80           6.24      7.06
  1  2    9.3  12    3.39           6.17      3.88
  1  3   14.0  12    4.89           5.04      3.08
  1  4   18.6  12    6.67           4.63      2.73
  1  5   23.3  12    6.09           4.70      2.71
  1  6   27.9  12    4.20           5.34      3.16
  1  7   32.5  12    3.40           7.41      4.59
  1  8   37.2  12    2.55           8.73      7.79
  1  9   41.8  12    9.43           7.78      8.88
  1 10   46.5  12    8.50           4.76      N/C
 
 
***** Combination: OVERLOAD_1 (12) -- PERMIT rating ****************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0  12   WORST CASE PERMIT SHEAR RATING =          2.56
* 2       0.5  12   WORST CASE PERMIT MOMENT RATING =         4.68
* 2      25.0  12   WORST CASE PERMIT SVC MOMENT RATING =     3.38
  2  0   46.5  12    N/C            N/C       N/C
  2  1   51.5  12    3.86           7.36      8.29
  2  2   56.5  12    2.92           8.54      7.18
  2  3   61.5  12    4.18           8.23      4.76
  2  4   66.5  12    5.19           6.59      3.68
  2  5   71.5  12    7.85           6.23      3.38
  2  6   76.5  12    5.05           6.66      3.72
  2  7   81.5  12    4.10           8.49      4.90
  2  8   86.5  12    2.87          10.66      8.41
  2  9   91.5  12    3.82           9.24     10.34
  2 10   96.5  12    N/C            N/C       N/C
 
 
***** Combination: OVERLOAD_1 (12) -- PERMIT rating ****************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      38.5  12   WORST CASE PERMIT SHEAR RATING =          2.08
* 3      23.0  12   WORST CASE PERMIT MOMENT RATING =         4.27
* 3      23.0  12   WORST CASE PERMIT SVC MOMENT RATING =     2.83
  3  0   96.5  12    N/C            N/C       N/C
  3  1  100.7  12    9.28           6.31      9.26
  3  2  104.8  12    2.64           7.21      7.18
  3  3  109.0  12    3.55           6.93      4.81
  3  4  113.1  12    4.41           4.98      3.35
  3  5  117.3  12    6.30           4.38      2.88
  3  6  121.4  12    7.48           4.28      2.86
  3  7  125.6  12    5.43           4.60      3.16
  3  8  129.7  12    3.74           5.49      3.84
  3  9  133.9  12    4.20           5.24      6.50
  3 10  138.0  12   11.11           INF       N/C
 
 
***** Combination: OVERLOAD_2 (13) -- PERMIT rating ****************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      40.5  13   WORST CASE PERMIT SHEAR RATING =          1.72
* 1      46.0  13   WORST CASE PERMIT MOMENT RATING =         2.50
* 1      20.5  13   WORST CASE PERMIT SVC MOMENT RATING =     2.51
  1  0    0.0  13    6.27           INF       N/C
  1  1    4.7  13    3.38           5.58      6.31
  1  2    9.3  13    3.08           5.49      3.45
  1  3   14.0  13    4.58           4.55      2.78
  1  4   18.6  13    6.79           4.31      2.54
  1  5   23.3  13    5.19           4.51      2.60
  1  6   27.9  13    3.63           4.94      2.93
  1  7   32.5  13    2.99           6.61      4.09
  1  8   37.2  13    2.16           9.10      8.03
  1  9   41.8  13    6.17           5.38      6.14
  1 10   46.5  13    6.44           2.50      N/C
 
 
***** Combination: OVERLOAD_2 (13) -- PERMIT rating ****************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0  13   WORST CASE PERMIT SHEAR RATING =          2.04
* 2       0.5  13   WORST CASE PERMIT MOMENT RATING =         2.51
* 2      25.0  13   WORST CASE PERMIT SVC MOMENT RATING =     3.58
  2  0   46.5  13    N/C            N/C       N/C
  2  1   51.5  13    2.32           5.56      6.26
  2  2   56.5  13    2.36           7.47      6.28
  2  3   61.5  13    3.49           7.90      4.57
  2  4   66.5  13    4.16           7.00      3.91
  2  5   71.5  13    6.47           6.60      3.58
  2  6   76.5  13    4.26           7.28      4.06
  2  7   81.5  13    3.47           8.20      4.73
  2  8   86.5  13    2.36           9.86      7.42
  2  9   91.5  13    2.37           6.44      7.22
  2 10   96.5  13    N/C            N/C       N/C
 
 
***** Combination: OVERLOAD_2 (13) -- PERMIT rating ****************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      38.5  13   WORST CASE PERMIT SHEAR RATING =          1.66
* 3       0.5  13   WORST CASE PERMIT MOMENT RATING =         2.59
* 3      23.0  13   WORST CASE PERMIT SVC MOMENT RATING =     2.68
  3  0   96.5  13    N/C            N/C       N/C
  3  1  100.7  13    7.41           4.42      6.48
  3  2  104.8  13    2.23           7.88      7.85
  3  3  109.0  13    3.00           6.29      4.38
  3  4  113.1  13    3.53           4.71      3.18
  3  5  117.3  13    4.76           4.20      2.76
  3  6  121.4  13    7.10           4.08      2.73
  3  7  125.6  13    5.27           4.27      2.94
  3  8  129.7  13    3.51           5.00      3.50
  3  9  133.9  13    3.35           4.81      5.96
  3 10  138.0  13   10.04           INF       N/C
 
 
***** Combination: EV2 (14) -- Emergency Vehicle rating ************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      39.0  14   WORST CASE EV SHEAR RATING =              2.03
* 1      18.0  14   WORST CASE EV MOMENT RATING =             3.58
* 1      20.5  14   WORST CASE EV SVC MOMENT RATING =         2.17
  1  0    0.0  14    5.91           INF       N/C
  1  1    4.7  14    2.89           4.72      5.53
  1  2    9.3  14    2.70           4.56      2.97
  1  3   14.0  14    3.74           3.78      2.40
  1  4   18.6  14    4.81           3.59      2.19
  1  5   23.3  14    4.34           3.69      2.19
  1  6   27.9  14    3.19           4.06      2.49
  1  7   32.5  14    2.75           5.34      3.43
  1  8   37.2  14    2.17           7.52      5.66
  1  9   41.8  14    8.44           6.70      6.95
  1 10   46.5  14    7.57           4.09      N/C
 
 
***** Combination: EV2 (14) -- Emergency Vehicle rating ************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0  14   WORST CASE EV SHEAR RATING =              2.16
* 2       0.5  14   WORST CASE EV MOMENT RATING =             4.02
* 2      25.0  14   WORST CASE EV SVC MOMENT RATING =         2.74
  2  0   46.5  14    N/C            N/C       N/C
  2  1   51.5  14    3.37           6.33      6.50
  2  2   56.5  14    2.42           7.34      5.28
  2  3   61.5  14    3.32           5.98      3.60
  2  4   66.5  14    3.89           5.03      2.92
  2  5   71.5  14    5.48           4.86      2.74
  2  6   76.5  14    3.80           5.08      2.95
  2  7   81.5  14    3.27           6.13      3.68
  2  8   86.5  14    2.40           8.95      5.55
  2  9   91.5  14    3.35           7.75      7.93
  2 10   96.5  14    N/C            N/C       N/C
 
 
***** Combination: EV2 (14) -- Emergency Vehicle rating ************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      38.5  14   WORST CASE EV SHEAR RATING =              1.19
* 3      25.0  14   WORST CASE EV MOMENT RATING =             3.25
* 3      25.0  14   WORST CASE EV SVC MOMENT RATING =         2.25
  3  0   96.5  14    N/C            N/C       N/C
  3  1  100.7  14    6.80           5.48      7.38
  3  2  104.8  14    2.18           6.26      5.67
  3  3  109.0  14    2.78           4.87      3.50
  3  4  113.1  14    3.26           3.70      2.58
  3  5  117.3  14    4.32           3.38      2.29
  3  6  121.4  14    5.13           3.27      2.25
  3  7  125.6  14    3.99           3.40      2.41
  3  8  129.7  14    2.88           3.98      2.88
  3  9  133.9  14    2.16           3.91      4.98
  3 10  138.0  14    8.81           INF       N/C
 
 
***** Combination: EV3 (15) -- Emergency Vehicle rating ************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1       4.0  15   WORST CASE EV SHEAR RATING =              0.89
* 1      20.5  15   WORST CASE EV MOMENT RATING =             2.36
* 1      20.5  15   WORST CASE EV SVC MOMENT RATING =         1.42
  1  0    0.0  15    4.01           INF       N/C
  1  1    4.7  15    0.95           3.21      3.76
  1  2    9.3  15    1.77           3.10      2.02
  1  3   14.0  15    2.45           2.58      1.63
  1  4   18.6  15    3.17           2.38      1.45
  1  5   23.3  15    2.89           2.42      1.44
  1  6   27.9  15    2.10           2.75      1.69
  1  7   32.5  15    1.81           3.66      2.35
  1  8   37.2  15    1.42           5.04      3.92
  1  9   41.8  15    4.57           4.50      4.66
  1 10   46.5  15    4.86           2.75      N/C
 
 
***** Combination: EV3 (15) -- Emergency Vehicle rating ************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       8.0  15   WORST CASE EV SHEAR RATING =              1.42
* 2       0.5  15   WORST CASE EV MOMENT RATING =             2.71
* 2      25.0  15   WORST CASE EV SVC MOMENT RATING =         1.79
  2  0   46.5  15    N/C            N/C       N/C
  2  1   51.5  15    1.77           4.26      4.37
  2  2   56.5  15    1.59           4.94      3.64
  2  3   61.5  15    2.18           4.10      2.47
  2  4   66.5  15    2.56           3.37      1.96
  2  5   71.5  15    3.63           3.18      1.79
  2  6   76.5  15    2.50           3.41      1.98
  2  7   81.5  15    2.15           4.20      2.53
  2  8   86.5  15    1.58           6.02      3.84
  2  9   91.5  15    1.77           5.22      5.34
  2 10   96.5  15    N/C            N/C       N/C
 
 
***** Combination: EV3 (15) -- Emergency Vehicle rating ************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3      36.5  15   WORST CASE EV SHEAR RATING =              0.90
* 3      23.0  15   WORST CASE EV MOMENT RATING =             2.15
* 3      23.0  15   WORST CASE EV SVC MOMENT RATING =         1.47
  3  0   96.5  15    N/C            N/C       N/C
  3  1  100.7  15    2.92           3.68      4.96
  3  2  104.8  15    1.44           4.21      3.81
  3  3  109.0  15    1.84           3.36      2.41
  3  4  113.1  15    2.16           2.53      1.76
  3  5  117.3  15    2.89           2.22      1.50
  3  6  121.4  15    3.41           2.16      1.49
  3  7  125.6  15    2.64           2.32      1.65
  3  8  129.7  15    1.90           2.71      1.96
  3  9  133.9  15    0.94           2.66      3.39
  3 10  138.0  15    5.64           INF       N/C
 
 
***** Combination: HL-93 (16) -- OPERATING rating ******************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      40.0  16   WORST CASE OPERATING SHEAR RATING =       0.51
* 1      46.0  16   WORST CASE OPERATING MOMENT RATING =      1.85
* 1      18.0  16   WORST CASE OPERATING SVC MOMENT RATING = 15.93
  1  0    0.0  16    3.57          INF        N/C
  1  1    4.7  16    0.75          2.81      37.76
  1  2    9.3  16    1.51          2.72      22.46
  1  3   14.0  16    1.87          2.27      17.28
  1  4   18.6  16    2.40          2.10      15.94
  1  5   23.3  16    2.35          2.12      16.24
  1  6   27.9  16    1.79          2.38      17.94
  1  7   32.5  16    1.56          3.22      23.91
  1  8   37.2  16    1.20          4.06      39.61
  1  9   41.8  16    2.25          3.40      91.78
  1 10   46.5  16    3.75          1.85       N/C
 
***** Combination: HL-93 (16) -- INVENTORY rating ******************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 1      40.0  16   WORST CASE INVENTORY SHEAR RATING =       0.39
* 1      46.0  16   WORST CASE INVENTORY MOMENT RATING =      1.43
* 1      20.5  16   WORST CASE INVENTORY SVC MOMENT RATING =  1.30
  1  0    0.0  16    2.75          INF        N/C
  1  1    4.7  16    0.58          2.17       3.42
  1  2    9.3  16    1.17          2.10       1.85
  1  3   14.0  16    1.44          1.75       1.49
  1  4   18.6  16    1.85          1.62       1.33
  1  5   23.3  16    1.81          1.63       1.31
  1  6   27.9  16    1.38          1.84       1.52
  1  7   32.5  16    1.20          2.48       2.15
  1  8   37.2  16    0.93          3.14       3.40
  1  9   41.8  16    1.73          2.62       3.65
  1 10   46.5  16    2.89          1.43       N/C
 
 
***** Combination: HL-93 (16) -- OPERATING rating ******************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       6.0  16   WORST CASE OPERATING SHEAR RATING =       0.67
* 2       0.5  16   WORST CASE OPERATING MOMENT RATING =      1.87
* 2      25.0  16   WORST CASE OPERATING SVC MOMENT RATING = 19.92
  2  0   46.5  16    N/C           N/C        N/C
  2  1   51.5  16    0.74          3.29      91.55
  2  2   56.5  16    1.34          4.02      40.36
  2  3   61.5  16    1.88          3.69      25.53
  2  4   66.5  16    2.24          3.00      20.74
  2  5   71.5  16    3.13          2.84      19.92
  2  6   76.5  16    2.21          3.03      20.99
  2  7   81.5  16    1.86          3.79      26.27
  2  8   86.5  16    1.34          5.04      42.39
  2  9   91.5  16    0.75          4.05      97.00
  2 10   96.5  16    N/C           N/C        N/C
 
***** Combination: HL-93 (16) -- INVENTORY rating ******************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 2       6.0  16   WORST CASE INVENTORY SHEAR RATING =       0.52
* 2       0.5  16   WORST CASE INVENTORY MOMENT RATING =      1.44
* 2      25.0  16   WORST CASE INVENTORY SVC MOMENT RATING =  1.66
  2  0   46.5  16    N/C           N/C        N/C
  2  1   51.5  16    0.57          2.54       3.51
  2  2   56.5  16    1.04          3.10       3.16
  2  3   61.5  16    1.45          2.85       2.31
  2  4   66.5  16    1.73          2.31       1.81
  2  5   71.5  16    2.41          2.19       1.66
  2  6   76.5  16    1.71          2.34       1.83
  2  7   81.5  16    1.44          2.92       2.36
  2  8   86.5  16    1.03          3.89       3.50
  2  9   91.5  16    0.58          3.13       4.30
  2 10   96.5  16    N/C           N/C        N/C
 
 
***** Combination: HL-93 (16) -- OPERATING rating ******************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3       7.0  16   WORST CASE OPERATING SHEAR RATING =       0.62
* 3      23.0  16   WORST CASE OPERATING MOMENT RATING =      1.91
* 3      23.0  16   WORST CASE OPERATING SVC MOMENT RATING = 16.45
  3  0   96.5  16    N/C           N/C        N/C
  3  1  100.7  16    4.01          2.82      93.45
  3  2  104.8  16    1.24          3.39      39.93
  3  3  109.0  16    1.62          2.91      24.41
  3  4  113.1  16    1.56          2.21      18.66
  3  5  117.3  16    1.86          1.94      16.75
  3  6  121.4  16    2.10          1.92      16.46
  3  7  125.6  16    1.78          2.08      17.79
  3  8  129.7  16    1.30          2.43      22.50
  3  9  133.9  16    0.86          2.37      35.62
  3 10  138.0  16    3.44          INF        N/C
 
***** Combination: HL-93 (16) -- INVENTORY rating ******************************
SPAN   X Coor.                               SRV.
 #  TP  (ft)   LC   SHEAR         MOMENT    MOMENT
=== ==  ===.=  ==   ==.==         ==.==      ==.==
* 3       7.0  16   WORST CASE INVENTORY SHEAR RATING =       0.48
* 3      23.0  16   WORST CASE INVENTORY MOMENT RATING =      1.48
* 3      23.0  16   WORST CASE INVENTORY SVC MOMENT RATING =  1.35
  3  0   96.5  16    N/C           N/C        N/C
  3  1  100.7  16    3.09          2.18       3.95
  3  2  104.8  16    0.96          2.62       3.19
  3  3  109.0  16    1.25          2.25       2.17
  3  4  113.1  16    1.21          1.70       1.60
  3  5  117.3  16    1.43          1.50       1.37
  3  6  121.4  16    1.62          1.48       1.38
  3  7  125.6  16    1.38          1.61       1.54
  3  8  129.7  16    1.00          1.87       1.82
  3  9  133.9  16    0.66          1.83       3.14
  3 10  138.0  16    2.65          INF        N/C
 

* =============================================================================================================================
# [AR:LRFR-LLRF] 5800 <Live Load Reduction Factor per LRFR>
* ==================================================================================================================================
*
*  SPAN   span ID
*  TP     1/10th point 0=left end to 10=right end of SPAN
*  X      position of cross section in ft
*
*  SD     Shear design factor
*  MD     Moment design factor
*  SP     Shear permit factor
*  MP     Moment permit factor
*  DF     Moment distribution factor used with LFR (FHWA or STD)
*

SPAN TP   X     ------- LRFR ------  ------- LRFR ------   - LFR -
                ------ bottom -----  ------- top -------
 #    #  (ft)     SD   MD   SP   MP    SD   MD   SP   MP      DF
===  == ====.=  =.== =.== =.== =.==  =.== =.== =.== =.==    =.==
  1   0    0.0  0.90 0.83 0.61 0.51  0.90 0.83 0.61 0.51    0.82
  1   1    4.5  0.90 0.83 0.61 0.51  0.90 0.83 0.61 0.51    0.82
  1   2    9.0  0.90 0.83 0.61 0.51  0.90 0.83 0.61 0.51    0.82
  1   3   13.5  0.90 0.83 0.61 0.51  0.90 0.83 0.61 0.51    0.82
  1   4   18.0  0.90 0.83 0.61 0.51  0.90 0.83 0.61 0.51    0.82
  1   5   23.5  0.90 0.83 0.61 0.51  0.90 0.83 0.61 0.51    0.82
  1   6   28.5  0.90 0.83 0.61 0.51  0.90 0.82 0.61 0.51    0.82
  1   7   33.0  0.90 0.83 0.61 0.51  0.90 0.82 0.61 0.51    0.82
  1   8   37.5  0.90 0.83 0.61 0.51  0.90 0.82 0.61 0.51    0.82
  1   9   42.0  0.90 0.83 0.61 0.51  0.90 0.82 0.61 0.51    0.82
  1  10   46.5  0.90 0.83 0.61 0.51  0.90 0.82 0.61 0.51    0.82
  2   0   46.5  0.90 0.81 0.61 0.50  0.90 0.82 0.61 0.51    0.82
  2   1   51.5  0.90 0.81 0.61 0.50  0.90 0.82 0.61 0.51    0.82
  2   2   56.5  0.90 0.81 0.61 0.50  0.90 0.82 0.61 0.51    0.82
  2   3   61.5  0.90 0.81 0.61 0.50  0.90 0.82 0.61 0.51    0.82
  2   4   66.5  0.90 0.81 0.61 0.50  0.90 0.82 0.61 0.51    0.82
  2   5   71.5  0.90 0.81 0.61 0.50  0.90 0.82 0.61 0.51    0.82
  2   6   76.5  0.90 0.81 0.61 0.50  0.90 0.83 0.61 0.52    0.82
  2   7   81.5  0.90 0.81 0.61 0.50  0.90 0.83 0.61 0.52    0.82
  2   8   86.5  0.90 0.81 0.61 0.50  0.90 0.83 0.61 0.52    0.82
  2   9   91.5  0.90 0.81 0.61 0.50  0.90 0.83 0.61 0.52    0.82
  2  10   96.5  0.90 0.81 0.61 0.50  0.90 0.83 0.61 0.52    0.82
  3   0   96.5  0.90 0.85 0.61 0.53  0.90 0.83 0.61 0.52    0.82
  3   1  100.5  0.90 0.85 0.61 0.53  0.90 0.83 0.61 0.52    0.82
  3   2  104.5  0.90 0.85 0.61 0.53  0.90 0.83 0.61 0.52    0.82
  3   3  108.5  0.90 0.85 0.61 0.53  0.90 0.83 0.61 0.52    0.82
  3   4  112.5  0.90 0.85 0.61 0.53  0.90 0.83 0.61 0.52    0.82
  3   5  117.5  0.90 0.85 0.61 0.53  0.90 0.83 0.61 0.52    0.82
  3   6  122.0  0.90 0.85 0.61 0.53  0.90 0.85 0.61 0.53    0.82
  3   7  126.0  0.90 0.85 0.61 0.53  0.90 0.85 0.61 0.53    0.82
  3   8  130.0  0.90 0.85 0.61 0.53  0.90 0.85 0.61 0.53    0.82
  3   9  134.0  0.90 0.85 0.61 0.53  0.90 0.85 0.61 0.53    0.82
  3  10  138.0  0.90 0.85 0.61 0.53  0.90 0.85 0.61 0.53    0.82
 
