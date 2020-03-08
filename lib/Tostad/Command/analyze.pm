package Tostad::Command::analyze;
use Mojo::Base 'Mojolicious::Command',-signatures,-async_await;
use Tostad::Model::WorldTradingData;
use Mojo::Util qw(dumper);
use Syntax::Keyword::Try;
use Time::Piece;
use Mojo::Promise;
has description => 'Analyze Stock Marked Data';
has usage       => sub { shift->extract_usage };

has wtd => sub ($self) {
  Tostad::Model::WorldTradingData->new( app => $self->app );
};

sub run ($self) {
  Mojo::Promise->all(
    map {
       $self->analyze($_)
    } @{$self->symbols}
  )->catch(sub ($err) {
    warn $err
  })
  ->wait;

  my $r = $self->results;

  for my $symb ( sort { $r->{$b}{factor} <=> $r->{$a}{factor}  } keys %$r ) {
    printf "%-7s: %3.0f%% %8.2f %8.2f\n",$symb,$r->{$symb}{factor}*100,$r->{$symb}{close},$r->{$symb}{avg};
  }


}

has results => sub {  {} };

async sub analyze ($self,$symbol) {
  my $data = await $self->wtd->get('history',{
    symbol => $symbol,
    # date_from => '2019-01-01'
  })->catch(sub ($err) {
    warn $err;
    return {};
  });

  my $start = (Time::Piece->new - 120*24*3600)->strftime("%Y-%m-%d");
  my $fail = '2020-01-15';
  my $n = 0;
  my @dates = sort keys %{$data->{history}};
  return if not @dates or
    time - Time::Piece->strptime($dates[-1],"%Y-%m-%d")->epoch > 7 * 24 * 3600;
  my %sum = (
    last => $dates[-1],
    avg => 0,
    low => 1e32,
    high => 0
  );
  my $entry;
  for my $date (@dates) {
    $entry = $data->{history}{$date};
    next if $date lt $start;
    $sum{first} //= $date;
    if ($date lt $fail) {
      $n++;
      $sum{avg} += ($entry->{close} - $sum{avg}) / $n
    }
    $sum{low} = $sum{low} > $entry->{low}  ?  $entry->{low} : $sum{low};
    $sum{high} = $sum{high} < $entry->{high} ? $entry->{high} : $sum{high};
    $sum{close} = $entry->{close};
  }
  if ($entry->{volume} / $entry->{close} < 100) {
    return;
  }
  $sum{factor} = $sum{close}/$sum{avg};
  $self->results->{$symbol} = \%sum;
};

has symbols => sub {
["AAD.SW","AAM.SW","AAPL.SW","ABBN.SW","ABBNE.SW","ABBV.SW","ABF.SW","ABT.SW","ABX.SW","AC.SW","ACA.SW","ACUN.SW","ADBE.SW","ADEN.SW","ADENE.SW","ADM.SW","ADS.SW","ADVN.SW","ADXN.SW","AEM.SW","AEVS.SW","AF.SW","AFPD.SW","AFX.SW","AGFB.SW","AGN.SW","AGS.SW","AI.SW","AIG.SW","AIR.SW","AIRE.SW","AIRN.SW","AIXA.SW","AKZ.SW","ALC.SW","ALLN.SW","ALO.SW","ALPH.SW","ALPN.SW","ALPNE.SW","ALSN.SW","ALU.SW","ALV.SW","ALXN.SW","AMD.SW","AMGN.SW","AMS.SW","AMZN.SW","ANDR.SW","ANF.SW","AOX.SW","APGN.SW","ARIA.SW","ARL.SW","ARM.SW","ARYN.SW","ASCN.SW","ASG.SW","ASM.SW","ASML.SW","ATLN.SW","ATLNE.SW","ATS.SW","AU.SW","AUTN.SW","AXP.SW","AZN.SW","B5A.SW","BA.SW","BABA.SW","BAC.SW","BAER.SW","BALN.SW","BALNE.SW","BANB.SW","BAP.SW","BARC.SW","BARN.SW","BAS.SW","BATS.SW","BAX.SW","BAYN.SW","BB.SW","BBDB.SW","BBN.SW","BBY.SW","BC.SW","BC8.SW","BCGE.SW","BCHN.SW","BCJ.SW","BCVN.SW","BDT.SW","BDX.SW","BEAN.SW","BEI.SW","BEKN.SW","BELL.SW","BHI.SW","BHP.SW","BIDU.SW","BIIB.SW","BIO3.SW","BIOEE.SW","BION.SW","BKW.SW","BLD.SW","BLIN.SW","BLK.SW","BLKB.SW","BLT.SW","BMPS.SW","BMW.SW","BMW3.SW","BMY.SW","BNP.SW","BNR.SW","BOBNN.SW","BOSN.SW","BOSS.SW","BP.SW","BPDG.SW","BPOST.SW","BRKN.SW","BSKP.SW","BSLN.SW","BTO.SW","BUCN.SW","BVB.SW","BVN.SW","BVZN.SW","BWO.SW","BX.SW","BYW6.SW","C.SW","CA.SW","CADN.SW","CAI.SW","CALN.SW","CAP.SW","CARLB.SW","CAS.SW","CASN.SW","CASNE.SW","CAT.SW","CBA.SW","CCO.SW","CDE.SW","CDI.SW","CELG.SW","CERN.SW","CEV.SW","CEVA.SW","CFR.SW","CFT.SW","CGG.SW","CHD.SW","CHT.SW","CICN.SW","CIE.SW","CL.SW","CLN.SW","CLTN.SW","CLXN.SW","CMBN.SW","CMCSA.SW","CNC.SW","COK.SW","COLOB.SW","COM.SW","COMD.SW","COMPG.SW","CON.SW","CONT.SW","COP.SW","COPN.SW","COTN.SW","CPEN.SW","CPENE.SW","CPGN.SW","CPHN.SW","CRM.SW","CS.SW","CSCO.SW","CSGN.SW","CSIQ.SW","CTSH.SW","CWC.SW","CWI.SW","DAE.SW","DAI.SW","DAL.SW","DAN.SW","DANG.SW","DB1.SW","DBAN.SW","DBK.SW","DCN.SW","DD.SW","DDD.SW","DE.SW","DEQ.SW","DESN.SW","DEZ.SW","DG.SW","DGC.SW","DHR.SW","DIC.SW","DIS.SW","DKSH.SW","DOKA.SW","DOW.SW","DPW.SW","DRI.SW","DRW3.SW","DSM.SW","DSY.SW","DTE.SW","DUE.SW","DUFN.SW","DWNI.SW","EBAY.SW","EBS.SW","EDF.SW","EDHN.SW","EDP.SW","EDR.SW","EEII.SW","EFGN.SW","EI.SW","ELD.SW","ELMN.SW","EMC.SW","EMMN.SW","EMR.SW","EMSN.SW","EN.SW","ENEL.SW","ENGI.SW","ENI.SW","ENPH.SW","EO.SW","EOAN.SW","ERF.SW","ERICB.SW","ESRX.SW","ESUN.SW","EVD.SW","EVE.SW","EVK.SW","EVT.SW","EW.SW","EXPE.SW","F.SW","FB.SW","FCEL.SW","FCX.SW","FDX.SW","FEYE.SW","FFI.SW","FHZN.SW","FI-N.SW","FIE.SW","FME.SW","FMS.SW","FNTN.SW","FNV.SW","FORN.SW","FORNE.SW","FP.SW","FPE3.SW","FR.SW","FRA.SW","FRE.SW","FSLR.SW","FTON.SW","FVI.SW","G.SW","G1A.SW","GALE.SW","GAM.SW","GAMEE.SW","GATE.SW","GAV.SW","GBF.SW","GBMN.SW","GE.SW","GEBN.SW","GEBNE.SW","GET.SW","GFJ.SW","GFK.SW","GIL.SW","GILD.SW","GIS.SW","GIVN.SW","GLDV.SW","GLE.SW","GLJ.SW","GLKBN.SW","GLUU.SW","GLW.SW","GM.SW","GMCR.SW","GMI.SW","GMM.SW","GMT.SW","GOB.SW","GOE.SW","GOLI.SW","GOOGL.SW","GPR.SW","GPRO.SW","GRKP.SW","GRPN.SW","GS.SW","GSK.SW","GSV.SW","GT.SW","GUR.SW","GWI1.SW","GXI.SW","HAB.SW","HAL.SW","HBH3.SW","HBLN.SW","HBMN.SW","HBMNE.SW","HD.SW","HDD.SW","HEB.SW","HEI.SW","HEID.SW","HELN.SW","HEN.SW","HEN3.SW","HHFA.SW","HIAG.SW","HL.SW","HLEE.SW","HMB.SW","HNR1.SW","HOCN.SW","HOG.SW","HOT.SW","HPQ.SW","HQCL.SW","HREN.SW","HTM.SW","HUBN.SW","HUE.SW","HYG.SW","IBM.SW","IECF.SW","IFCN.SW","IFX.SW","IHSN.SW","IIA.SW","IMB.SW","IMG.SW","IMPN.SW","ING.SW","INH.SW","INRN.SW","INTC.SW","INVN.SW","IONS.SW","IPH.SW","IPS.SW","IRBT.SW","ISN.SW","ISP.SW","ISRG.SW","IT.SW","JASO.SW","JCP.SW","JEN.SW","JFN.SW","JKS.SW","JNJ.SW","JPM.SW","JUNGH.SW","KARN.SW","KBC.SW","KCO.SW","KER.SW","KG.SW","KGX.SW","KHC.SW","KLIN.SW","KN.SW","KNDI.SW","KNIN.SW","KO.SW","KOMN.SW","KORS.SW","KPO.SW","KRN.SW","KU2.SW","KUD.SW","KUNN.SW","KWS.SW","LECN.SW","LEG.SW","LEHN.SW","LEN.SW","LEO.SW","LEON.SW","LHA.SW","LHN.SW","LIFE.SW","LIN.SW","LINN.SW","LISN.SW","LISP.SW","LLOY.SW","LLY.SW","LMN.SW","LMT.SW","LNKD.SW","LNZ.SW","LOCAL.SW","LOGN.SW","LOHN.SW","LONN.SW","LPK.SW","LUKN.SW","LVS.SW","LXS.SW","M5Z.SW","MA.SW","MAELI.SW","MAN.SW","MASN.SW","MBTN.SW","MC.SW","MCD.SW","MCHN.SW","MCP.SW","MDLZ.SW","MDT.SW","MED.SW","MER.SW","METN.SW","MIKN.SW","ML.SW","MLP.SW","MMB.SW","MMK.SW","MMM.SW","MO.SW","MOBN.SW","MOLN.SW","MOR.SW","MOVE.SW","MOZN.SW","MRK.SW","MRW.SW","MS.SW","MSFT.SW","MT.SW","MTX.SW","MU.SW","MUV2.SW","MY.SW","MYRN.SW","NBEN.SW","NCM.SW","NDA.SW","NDASEK.SW","NDX1.SW","NEM.SW","NEMA.SW","NESN.SW","NESNE.SW","NEV.SW","NEWN.SW","NFLX.SW","NHY.SW","NIHN.SW","NIN.SW","NKE.SW","NOEJ.SW","NOKIA.SW","NOVN.SW","NOVNEE.SW","NOVOB.SW","NTES.SW","NUS.SW","NVDA.SW","NWRN.SW","NZYMB.SW","O1BC.SW","O2C.SW","O2D.SW","ODHN.SW","OERL.SW","OFN.SW","OMV.SW","ONVO.SW","OR.SW","ORA.SW","ORCL.SW","ORMP.SW","ORON.SW","OSR.SW","P1Z.SW","PAA.SW","PAH3.SW","PARG.SW","PAXN.SW","PCLN.SW","PEAN.SW","PEDU.SW","PEHN.SW","PEL.SW","PEP.SW","PFE.SW","PFV.SW","PG.SW","PGHN.SW","PGM.SW","PHI.SW","PLAN.SW","PLUG.SW","PM.SW","PMI.SW","PMOX.SW","PN6.SW","PNDORA.SW","PNHO.SW","POLN.SW","POM.SW","POST.SW","PRFN.SW","PROX.SW","PRP.SW","PSAN.SW","PSEC.SW","PSM.SW","PSPN.SW","PTK.SW","PUB.SW","PUBN.SW","PUM.SW","PWTN.SW","PYPL.SW","QCOM.SW","QIHU.SW","QSC.SW","RAA.SW","RACE.SW","RB.SW","RBI.SW","RBS.SW","RCO.SW","RDN.SW","RDSA.SW","REGN.SW","REPI.SW","REPP.SW","RESOL.SW","RGSE.SW","RHI.SW","RHK.SW","RHM.SW","RI.SW","RIEN.SW","RIGN.SW","RIO.SW","RIOP.SW","RLD.SW","RNO.SW","RO.SW","ROG.SW","ROL.SW","ROS.SW","ROSE.SW","RSTI.SW","RTL.SW","RUS.SW","RWE.SW","RWE3.SW","RY.SW","S92.SW","SAF.SW","SAHN.SW","SAN.SW","SANN.SW","SAP.SW","SAX.SW","SAZ.SW","SBB.SW","SBM.SW","SBO.SW","SBS.SW","SBUX.SW","SCAB.SW","SCHN.SW","SCHNE.SW","SCHP.SW","SCHPE.SW","SCMN.SW","SCR.SW","SCTY.SW","SCZ.SW","SDF.SW","SEV.SW","SFPN.SW","SFQ.SW","SFSN.SW","SFZN.SW","SGKN.SW","SGL.SW","SGMO.SW","SGSN.SW","SGSNE.SW","SHA.SW","SHLTN.SW","SHPNE.SW","SIGN.SW","SIKA.SW","SIN.SW","SIX2.SW","SKIN.SW","SLB.SW","SLHN.SW","SLOG.SW","SLT.SW","SLW.SW","SMET.SW","SNBN.SW","SNDK.SW","SNE.SW","SOFB.SW","SONC.SW","SOON.SW","SOONE.SW","SOW.SW","SPCE.SW","SPEX.SW","SPLK.SW","SPLS.SW","SPM.SW","SPR.SW","SPSN.SW","SPWR.SW","SQN.SW","SRAIL.SW","SRCG.SW","SREN.SW","SRP.SW","SRT3.SW","SSO.SW","STGN.SW","STL.SW","STLN.SW","STMN.SW","STRN.SW","SU.SW","SUN.SW","SUR.SW","SVM.SW","SW.SW","SW1.SW","SWEDA.SW","SWON.SW","SWTQ.SW","SWVK.SW","SY1.SW","SYK.SW","SYNN.SW","SYNNE.SW","SYNNEE.SW","SZG.SW","SZU.SW","T.SW","TAMN.SW","TCG.SW","TECN.SW","TEG.SW","TEL.SW","TEMN.SW","TEVA.SW","TFS.SW","THO.SW","TIBN.SW","TIM.SW","TIT.SW","TK.SW","TKA.SW","TKBP.SW","TLX.SW","TMO.SW","TMUS.SW","TOHN.SW","TOSH.SW","TOYMO.SW","TRIP.SW","TRV.SW","TSCO.SW","TSL.SW","TSLA.SW","TTI.SW","TTK.SW","TTM.SW","TUI1.SW","TWTR.SW","TWX.SW","TXN.SW","UBI.SW","UBSG.SW","UBSNE.SW","UBXN.SW","UCG.SW","UG.SW","UHR.SW","UHRE.SW","UHRN.SW","UHRNE.SW","UIS.SW","UL.SW","UN.SW","UNH.SW","UNP.SW","UPS.SW","UTDI.SW","UTX.SW","V.SW","VACN.SW","VAHN.SW","VALE.SW","VALN.SW","VATN.SW","VBSN.SW","VCH.SW","VER.SW","VET.SW","VFC.SW","VIB3.SW","VIE.SW","VIFN.SW","VILN.SW","VIV.SW","VJET.SW","VK.SW","VLA.SW","VLRT.SW","VNA.SW","VOD.SW","VOE.SW","VONN.SW","VOS.SW","VRTX.SW","VRX.SW","VW-V.SW","VW.SW","VWS.SW","VZ.SW","VZN.SW","WAC.SW","WARN.SW","WBA.SW","WCH.SW","WDI.SW","WFC.SW","WFM.SW","WIE.SW","WIHN.SW","WIN.SW","WKBN.SW","WMT.SW","WPL.SW","WYNN.SW","XESX.SW","XOM.SW","XONE.SW","XRX.SW","YAR.SW","YELP.SW","YGE.SW","YPSN.SW","YRI.SW","YUM.SW","YY.SW","ZAG.SW","ZAL.SW","ZBH.SW","ZC.SW","ZEHN.SW","ZG.SW","ZIL2.SW","ZMS.SW","ZNGA.SW","ZO1.SW","ZUBN.SW","ZUGN.SW","ZURN.SW","ZWM.SW"];
};

1;

=encoding utf8

=head1 NAME

Tostad::Command::analyze - Get command

=head1 SYNOPSIS

  Usage: tostad analyze

=cut
