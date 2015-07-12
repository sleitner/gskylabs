#!/usr/bin/perl
##Written by K. Simon Krughoff University of Washington 2008
##Modified by Sam Leitner University of Chicago 2008
use lib qw( /usr/lib/perl5/5.10.0 );
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
my $url = "http://casjobs.sdss.org/dr7/en/tools/search/x_sql.asp?format=csv&cmd=SELECT+TOP+999+p.ra,p.dec,p.type,p.modelmag_g,p.modelmag_r,p.modelmag_i,p.run,p.rerun,p.camcol,p.field,p.obj,p.objid,dbo.fIAUFromEq(p.ra,p.dec),p.z,p.specobjid,p.specClass+FROM+SpecPhotoAll+as+p+WHERE+p.ra<$east+and+p.ra>$west+and+p.dec>$south+and+p.dec<$north+and+(p.specClass=1+or+p.specClass=6)+order+by+p.modelmag_r";
my $content = get $url;
die "Couldn't get $url" unless defined $content;

if($content =~ /ERROR/){ error_kml("Timed Out", "The query to SDSS timed out<br/>Try zooming in, or change location", $px, $py);}
@lines = split "\n", $content;
if($#lines == 0){ error_kml("No Data in SDSS", "There is no data in DR7 for the viewport location", $px, $py); }
shift(@lines);
print "Content-type: text/html\n\n"; # Web page as default output
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://www.opengis.net/kml/2.2\" hint=\"target=sky\">\n";
print "  <Document>\n";
print "    <name>KML Sample</name>\n";
print "    <Style id=\"SDSSIcon\">\n";
print "      <LabelStyle>\n";
print "          <scale>0.001</scale>\n";
print "      </LabelStyle>\n";
print "      <IconStyle>\n";
print "      <scale>1.25</scale>\n";
print "        <Icon>\n";
print "        <href>http://sky.astro.washington.edu/icon.png</href>\n";
print "        </Icon>\n";
print "      </IconStyle>\n";
print "      <BalloonStyle>
     <text><![CDATA[\$[description]]]></text>
          <color>ffffffff</color>
	     </BalloonStyle>\n";
print "    </Style>\n";
for $line (@lines){
  ($x, $y, $type, $g, $r, $i, $run, $rerun, $camcol, $field, $obj, $objid,$name,$z,$specobjid,$specclass) = split ',', $line;
  if($specclass == 0){
    $tstr = "UNKNOWN";
  }
  elsif($specclass == 1){
    $tstr = "STAR";
  }
  elsif($specclass == 2){
    $tstr = "GALAXY";
  }
  elsif($specclass == 3){
    $tstr = "QSO";
  }
  elsif($specclass == 4){
    $tstr = "HIZ_QSO";
  }
  elsif($specclass == 5){
    $tstr = "SKY";
  }
  elsif($specclass == 6){
    $tstr = "STAR_LATE";
  }
  elsif($specclass == 7){
    $tstr = "GAL_EM";
  }
  $gr = $g - $r;
  $ri = $r - $i;
  print "  <Placemark>\n";
  print "    <styleUrl>#SDSSIcon</styleUrl>\n";
  printf "    <description><![CDATA[";
  printf " <table><tr><td><img height=\"30\" src=\"http://www.sdss.org/logos/SDSS_pi_bevel.gif\"/></td><td align=\"left\"><font size=\"40\">    SDSS</font></td></tr></table><b>$name</b><hr/><table><tr><td>RA:</td><td>%f</td></tr><tr><td> DEC:</td><td>%f</td></tr>\n",$x,$y;
  printf "    <tr><td>Spectroscopic ObjType:</td><td>$tstr ($specclass)</td></tr>";
  printf "    <tr><td>MAGS:</td><td> g=%2.4f </td></tr><tr><td></td><td>r=%2.4f </td></tr><tr><td></td><td>i=%2.4f</td></tr><tr><td>redshift:</td><td>$z</td></tr></table>",$g,$r,$i;
  printf "    <a href=\"http://cas.sdss.org/astro/en/tools/explore/obj.asp?id=$objid\">Click for SDSS Page</a><br/><a href=\"http://cas.sdss.org/astro/en/get/specById.asp?id=$specobjid\">Click for Spectrum</a><br/>Note: All magnitudes are model mags.\n";
  printf "    ]]></description>\n";
  printf "    <name>$name</name>\n";
  printf "    <Snippet></Snippet>\n";
  printf "    <Point>\n";
  $x = $x - 180;
  printf "      <coordinates>$x,$y,0</coordinates>\n";
  printf "    </Point>\n";
  printf "  </Placemark>\n";
}
printf "</Document>\n";
printf "</kml>\n";
exit 1;


sub error_kml {
  my $short = shift;
  my $desc = shift;
  my $px = shift;
  my $py = shift;
  print "Content-type: text/html\n\n"; # Web page as default output
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
  print "    <description>$desc<br/>Click <a href=\"\http://sky.astro.washington.edu/kml/LEO.kml#LEO\"> here</a> to zoom to a location in SDSS.</description>\n";
  print "    <name>Click Here</name>\n";
  print "    </Folder>\n";
  print "</Document>\n";
  print "</kml>\n";
  exit 1;
}
