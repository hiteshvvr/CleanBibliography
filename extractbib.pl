#!/usr/bin/perl
#
#FLIE: EXTRACTBIB.PL
#Version: 1.0
#
#This program traverses all citations in one latex file (e.g. latexfile.tex), then go to
#a big bibtex file (e.g. references.bib) and extract only those papers that appear in the
#latex file, and outputs a new bibtex file (e.g. latexfile.bib) with the subset of papers 
#that appear in the tex file.
#
#One way to use it is to manage all the references in one big file (online, or offline),
#when a paper is finished, the author can run this program to get a small bibtex file so
#that this small file can be sent to a journal.
#
#I guess this is often needed, however, I have not found a good solution so far. So here
#is mine.  It is fairly complicated to address different cases.  I'll try to update it
#when I find a need.  If you have any suggestions, please let me know.
#
#Xiaoquan (Michael) Zhang
#Assistant Professor, Hong Kong University of Science and Technology
#July 04, 2007
#
#zhangxiaoquan (a) gmail.com
#
#
#Usage: perl extractbib.pl latexfile.tex references.bib [output.bib]
#	latexfile.tex is the original tex file
#	references.bib is the bibtex file containing all the references
#	output.bib contains the subset of references appear in the tex file
#	(If the output filename "output.bib" is omitted, the program will
#	generate a bibtex file with name: latexfile.tex)
#

our @array; # for storing bib entries
our $cont;
if (@ARGV <2){
	print "At least two arguments are needed. Write $0 -h for help\n";
	usage();
	exit;
}

my ($tex,$bib, $out)=@ARGV;
open (TEX, $tex) or die ("Could not open $tex: $!");
my @row=<TEX>;
close (TEX);

my $save;
my $state=0; #state=1 means a multi-line citation is in action
foreach $line (@row){

	next if ($line=~/^\s*%/) ; #skip comment lines
	if ($state){
		$save=$save.$line;
		$line=$save;
	}
	
	if ($line=~/\\cite/ &&!($line=~m/\\cite([^}]*){([^}]*)}/)){
		$state=1;
		$save=$line;
		next;
	}
	
        #VG begin 
        #Skip [xxxxxx] in of \cite[xxx][xxx]{}
        $line =~ s/\[[^\]]*\]//g;
        #VG end 

	while ($line=~m/\\cite([^}]*){([^}]*)}/g) {
		$state=0;
		my $cite=$2;
		if ($cite =~ /,/){ 
	#		print "$cite\n";
			my @names = split(/,/, $cite);
			my $names=@names;
			for (my $i=0; $i<=$names-1; $i++){
	#			print "@names[$i]\n";
				compare(@names[$i]);
			}
		} else {
	#		print "$cite\n";
			compare($cite);
		}
		
	} 
}

#now @array contains all references
print "\%Bibs appeared in the tex file, sorted...\n";
foreach $line (sort @array){
	print "\% $line\n";
}



extract();


close(TEX);

exit;

sub extract {
	if ($out eq ""){
		my @file=split(/\./,$tex);
		$out=$file[0].".bib";
	}
	open (OUT, ">$out") or die("Cannot open the output file $out: $!");
	print OUT "\%\% This file is created by Michael X. Zhang's $0\n";
# VG begin
# Commented : "@" generates error with bibtex
#	print OUT "\%\% For questions, please write to zhangxiaoquan@gmail.com\n";
	print OUT "\%\% For questions, please write to zhangxiaoquan {a} gmail.com\n";
# VG end
	print OUT "\%\% Copyright Michael X. Zhang, 2007\n\n";
	open (BIB, $bib) or die ("Could not open $bib: $!");
	my @row=<BIB>;
	close (BIB);
	$array=@array;
	print "\% Total Number of Citations: $array\n";
	for (my $i=0; $i<=$array-1; $i++){
		#@array[$i]='argentesi&filistrucchi05';
		#print "\% @array[$i]\n";
		
		my $found=0;
		my $line;
		foreach $line (@row){
			$line=~s /^\s+//;
			if (($found<2)){
				#print "$line\n";<STDIN>;
				if ($line=~m/{@array[$i],/i){
					$found=1;
				#	print "\% Started\n";<STDIN>;
					#print "$line";
					print OUT "$line";
				} elsif ($found==1){
					#print "$line";
					print OUT "$line";
					if
						# VG begin
                               			# commented
						#( ($line=~m/^}/)){
						# Allow ^}, inside the description of an article
                                                # Stop only if } starts the line and is followed by end of line
						( ($line=~m/^}$/)){
						# VG end
						$found=2;
					}
				}
			}
		}
		#print "out\n";<STDIN>;
		
	}
	close(OUT);
}


sub compare {
	my $cite=shift;
	$cite=~ s/^\s+//;
	$cite=~ s/\s+$//;
	#print "$cite\n";<STDIN>;
	@match=grep(/$cite/i, @array);
	$match=@match;
	if ($match == 0){
		push(@array,$cite);
		$cont++;
	}
}
sub usage {
print<<EOF;
Usage: perl $0 [options] latexfile.tex references.bib 

Extracts all bibtex entries from a .bib file that appear in the .tex file.
A new file will be created with name: latexfile.bib.

EOF
}
