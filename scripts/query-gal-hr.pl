#!/usr/bin/perl
#Written by Sam Leitner  KICP 2008
use lib qw(/usr/lib/perl5/5.10.0/);
use CGI;
use CGI::Carp;
use LWP::Simple;
my $q = new CGI;
my $bbox = $q->url_param('BBOX');
($west, $south, $east, $north) = split ',',$bbox;
$west = $west + 180;
$east = $east + 180;
$px = $west + ($east - $west)/2 - 180;
$py = $south + ($north - $south)/2;
if($north - $south > 20){
    error_kml("Zoom in","Your viewport is too large",$px, $py);
}    
my $url = "http://casjobs.sdss.org/dr7/en/tools/search/x_sql.asp?format=csv&cmd=SELECT+TOP+500+dbo.fIAUFromEq(p.ra,p.dec),p.ra,p.dec,p.modelmag_g,p.modelmag_r,p.modelmag_i+FROM+Galaxy+as+p+WHERE+p.modelmag_r<21+and+p.ra<$east+and+p.ra>$west+and+p.dec>$south+and+p.dec<$north+order+by+p.modelmag_r";
warn "$url";
my $content = get $url;
die "Couldn't get $url" unless defined $content;

if($content =~ /ERROR/){ error_kml("Timed Out", "The query to SDSS timed out<br/>Try zooming in, or change location", $px, $py);}
@lines = split "\n", $content;
if($#lines == 0){ error_kml("No Data in SDSS", "There is no data in DR7 for the viewport location", $px, $py); }
shift(@lines);
print "Content-type: text/html\n\n";
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://www.opengis.net/kml/2.2\" hint=\"target=sky\">\n";
print "  <Document>\n";
  print "         <name>\"Color Magnitude Objects\"</name>\n";
for $line (@lines){
  ($name, $ra, $dec, $g, $r, $i) = split ',', $line;
  $x = $ra - 180;
  $y = $dec ;
  $gr = $g - $r;
  $ri = $r - $i;
  $ra = $ra;
  $ypleps = $y + .00001 ; #used for region
  $xpleps  = $x + .00001 ; #used for region
  my $hmagr = 21.;
  my $lmagr = 14.;
  my $higr = 2.0;
  my $logr = -.5;
  my $normc = ( $gr - $logr  ) / ( $higr  - $logr  );
  my $normr = ( $r  - $lmagr ) / ( $hmagr - $lmagr );


  my $hixpix = -860;
  my $loxpix =  -15;
  my $hiypix =   30;
  my $loypix = 650 ;

#upper right
#  my $appr     = $hixpix ;
#  my $colorind = $hiypix ;
#lower left 
#  my $appr =  $loxpix;
#  my $colorind = $loypix;

  my $colorind = $normc * ($hiypix- $loypix)  + $loypix  ;
  my $appr     = $normr * ($hixpix- $loxpix)  + $loxpix  ;

  if($normc    < 0.1){
    $idcolor = "FF660000";
  }elsif($normc < 0.4){
    $idcolor = "FFFF0000";
  }elsif($normc < 0.5){
    $idcolor = "FFFF0099";
  }elsif($normc < 0.6){
    $idcolor = "FFFF00CC";
#  }elsif($normc < 0.1){
#    $idcolor = "FFFF00FF";
#  }elsif($normc < 0.1){
#    $idcolor = "FF9900ff";
#  }elsif($normc < 0.1){
#    $idcolor = "FF3300ff";
  }elsif($normc < 0.8){
    $idcolor = "FF0000CC";
  }elsif($normc < 1.0){
    $idcolor = "FF000095";
  }elsif($normc < 1.1){
    $idcolor = "FF000066";
  }else {
    $idcolor = "11111111";
  }	

  print "  <ScreenOverlay >\n";
  print "         <name>$name</name>\n";
  print "         <color>$idcolor</color>\n";
  print "         <drawOrder>2</drawOrder>\n";
  print "         <Icon>\n";
  print "            <href>http://astrowiki.uchicago.edu/~sleitner/GS/images/wpx.png</href>\n";
  print "         </Icon>\n";
  print "         <overlayXY x=\"$appr\" y=\"$colorind\" xunits=\"pixels\" yunits=\"pixels\"/>\n";
  print "         <screenXY x=\"0\" y=\"1\" xunits=\"fraction\" yunits=\"fraction\"/>\n";
  print "         <size x=\"4\" y=\"4\" xunits=\"pixels\" yunits=\"pixels\"/>\n";
  print "  </ScreenOverlay>\n";



}
print "</Document>\n";
print "</kml>\n";
exit 1;


sub error_kml {
    my $short = shift;
    my $desc = shift;
    my $px = shift;
    my $py = shift;
    print "Content-type: text/html\n\n";
    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print "<kml xmlns=\"http://www.opengis.net/kml/2.2\" hint=\"target=sky\">\n";
    print "  <Document>\n";
    print "    <name>KML Sample</name>\n";
    print "    <Style id=\"SDSSIcon\">\n";
    print "      <LabelStyle>\n";
    print "          <scale>0.001</scale>\n";
    print "      </LabelStyle>\n";
    print "      <IconStyle>\n";
    print "        <Icon>\n";
    print "        <href>http://mw1.google.com/mw-earth-vectordb/sky/sky1/pics/icon.png</href>\n";
    print "        </Icon>\n";
    print "      </IconStyle>\n";
    print "      <BalloonStyle>
                    <text><![CDATA[\$[description]]]></text>
                    <color>ffffffff</color>
 	         </BalloonStyle>\n";
    print "    </Style>\n";
    print "    <styleUrl>#SDSSIcon</styleUrl>\n";
    print "    <Folder>\n";
    print "    <description><![CDATA[$desc<br/>Click <a href=\"\http://sky.astro.washington.edu/kml/LEO.kml#LEO\"> here</a> to zoom to a location in SDSS.]]></description>\n";
    print "    <name>Click Here</name>\n";
    print "    </Folder>\n";
    print "</Document>\n";
    print "</kml>\n";
    exit 1;
}
