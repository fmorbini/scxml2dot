#!/cygdrive/c/Perl/bin/perl
use LWP::Simple;
use XML::Simple;
use Data::Dumper;

my $ID=1;

my $hier="";
#my $tr="";
my %tr=();

sub generateEdgeForTransition {
    my ($pid,$childid,$event,$cond,$color)=@_;
    my %tmp;
    if (!exists($tr{$pid})) {
	$tr{$pid}=();
    }
    if (!exists($tr{$pid}{$childid})) {
	$tr{$pid}{$childid}=();
    }
    if (!exists($tr{$pid}{$childid}{$color})) {
	$tr{$pid}{$childid}{$color}="";
    }
    my $label="";
    if (length($event)>0) {
	$label.="EVENT=$event ";
    }
    if (length($cond)>0) {
	$label.="COND=$cond ";
    }
    if (length($label)>0) {
	$tr{$pid}{$childid}{$color}.="$label\\n";
    }   
}

sub printNodeHierEdge {
    my($el,$pid,$final,$inNewParallelContext) = @_;
    my $childid;
    if (exists($el->{'id'})) {
	$childid=$el->{'id'};
    } else {
	$childid=$pid.".child".$ID;
	$ID++;
    }
    # handle use of final attribute or child
    if (lc($el->{'final'}) eq "true") {
	$final=1;
    }
    if ($final) {
	print "\"$childid\" [shape = doublecircle,color=red];\n";
    } else {
	print "\"$childid\";\n";
    }
    $hier.="\"".$pid."\"->\"$childid\";\n";
    getNodeHier($el,$childid,$inNewParallelContext);
}
sub printTrEdge {
    my($el,$pid,$color) = @_;
    #print Dumper($el);
    my $target;
    if (exists($el->{'target'})){
	$target=$el->{'target'};
    } else {
	if (exists($el->{'next'})) {
	    $target=$el->{'next'};
	} else {
	    $target=$pid;
	}
    }
    if ($target) {
	generateEdgeForTransition($pid,$target,$el->{'event'},$el->{'cond'},$color);
    }
}

sub processElement {
    my($states,$pid,$istr,$final,$inNewParallelContext)=@_;
    my $type=ref($states);
    my $printParallelContext=0;
    if ($inNewParallelContext==2) {
	$printParallelContext=1;
	$inNewParallelContext=0;
    }
    #print $type."\n";
    if ($type eq 'ARRAY') {
	foreach $i (@$states) {
	    if ($istr) {
		printTrEdge($i,$pid,"black");
	    } else {
		if ($printParallelContext){
		    print "subgraph cluster$ID {\n";
		    print "label=parallel;\n";
		    print "color=blue;\n";
		    $ID++;
		}
		printNodeHierEdge($i,$pid,$final,$inNewParallelContext);
		if ($printParallelContext) {
		    print "}\n";
		}
	    }
	}
    } elsif ($type eq 'HASH') {
	if ($istr) {
	    printTrEdge($states,$pid,"black");
	} else {
	    if ($printParallelContext){
		print "subgraph cluster$ID {\n";
		print "label=parallel;\n";
		print "color=blue;\n";
		$ID++;
	    }
	    printNodeHierEdge($states,$pid,$final,$inNewParallelContext);
	    if ($printParallelContext) {
		print "}\n";
	    }
	}
    } else {
	die "error";
    }
}

sub addTransitionsToInitialNodes {
    my ($el,$pid)=@_;
    my $v=$el->{'initial'};
    if (defined $v) {
	if (ref($v) eq "HASH") {
	    my $istr=$v->{'transition'};
	    if (defined $istr) {
		printTrEdge($istr,$pid,"red")
	    }
	} else {
	    my @ret=split(' ',$v);
	    foreach $i (@ret) {
		generateEdgeForTransition($pid,$i,"","","red");
	    }
	}
    }
    $v=$el->{'initialstate'};
    if (defined $v) {
	if (ref($v) eq "HASH") {
	    my $istr=$v->{'transition'};
	    if (defined $istr) {
		printTrEdge($istr,$pid,"red")
	    }
	} else {
	    my @ret=split(' ',$v);
	    foreach $i (@ret) {
		generateEdgeForTransition($pid,$i,"","","red");
	    }
	}
    }
}

sub getNodeHier {
    my($el,$pid,$inNewParallelContext) = @_;
    # print Dumper($el);
    # process initial/initialstate attribute or children
    addTransitionsToInitialNodes($el,$pid);
    $states=$el->{'transition'};
    if (defined $states) {
	processElement($states,$pid,1,0,0);
    }
    $states=$el->{'state'};
    if (defined $states) {
	processElement($states,$pid,0,0,($inNewParallelContext)?2:0);
    }
    $states=$el->{'final'};
    if ((defined $states) && ((ref($states) eq "ARRAY") || (ref($states) eq "HASH"))) {
	processElement($states,$pid,0,1,0);
    }
    $states=$el->{'parallel'};
    if (defined $states) {
	processElement($states,$pid,0,0,1);
    }
}

#compound state and parallel state should be handled like a root element
#what to do for a root element:
# find all transitions
#check input argument presence
($#ARGV==0) or die "one argument required: sessionid to retreive.";
my $xs1 = XML::Simple->new();
my $doc = $xs1->XMLin($ARGV[0],keyattr => []);
#print Dumper($doc);
print "digraph G {\n";
print "graph [splines=false overlap=false];\n";

getNodeHier($doc,"root",0);

print "subgraph hier {\n";
print "edge [style=dashed];\n";
print $hier;
print "}\n";

print "subgraph tr {\n";
#print "edge [style=dashed];\n";
foreach my $p (keys %tr) {
    foreach my $c (keys %{$tr{$p}}) {
	foreach my $color (keys %{$tr{$p}{$c}}) {
	    print "\"$p\"->\"$c\" [color=\"$color\", label=\"$tr{$p}{$c}{$color}\"];\n"
	}
    }
}
print "}\n";

print "}\n";
