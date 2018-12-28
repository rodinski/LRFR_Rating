#!/perl
use warnings;
use strict;
use feature 'say';

use Data::Dumper;
sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

while ( my $line = <DATA> ) {
  chomp $line;
  if ( $line =~ /^# \[/ ) { say "$line"; &read2star }
  #if ( $line =~ /^==[ =\|\.]\+$/ ) { say $line} #; &read2star}
#  say $line;
}

sub read2star {
  my $ln;
  while ( $ln = <DATA> ) {
    chomp $ln;
    last if  ($ln =~ /^\* /) ;
    say $ln;
  }
}


# ===========================================================
__DATA__
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
__END__
