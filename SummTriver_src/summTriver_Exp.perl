# Copyright (C) 2015-2017  Luis Adrián Cabrera Diego
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -----	Program to Library to calculate the Trivergence
#		Based on the ideas of Juan-Manuel Torres-Moreno
#		V 0.01  14 February 2017
#  		Luis Adrián Cabrera Diego adrian.9819@gmail.com

#Program to do the experiments about evaluating summaries using the Trivergence
#Created by: Luis Adrián Cabrera Diego
#Date: 14-02-2017
#Version: 0.01

use strict;
use utf8;
use Storable;
use Getopt::Std;
use Data::Dumper;
use Cwd;
use XML::LibXML;
use Math::Random::Secure qw(irand);

require "".getcwd()."/./trivergenciaSR5.perl";
require "".getcwd()."/../LibGrl/limpiar.perl";
require "".getcwd()."/../LibGrl/n-gramas1,2.perl";
binmode STDOUT, ":encoding(utf8)";

my %opts;
getopts('h', \%opts);

$opts{h}=1 if ($ARGV[0] eq "");

#Help
if($opts{h})
{
	print<<EOT;
	perl summTriver_Exp.perl [Options] configFile

Notes:
	P: All the documents of InputDir excepting one (R)
	R: One document from the InputDir different from P
	Q: Source Document

Options:
	Help: -h						This help guide
EOT
exit;
}


#
# Language: -l [fr|en]			Language to do the analysis. French by default.
# Trivergence: -T [KL|JS|sJS]				Measure to use, KL by default. The others are Jensen-Shannon and smoothed Jensen-Shannon
# Method: -t [m|c]					Method to do the Trivergence multiplication (m; defaullt) of divergences or composition (c) of divergences.
# Trivergence normalization: -N		If it is used it will normalize the trivergence by composition
# Smoothing -s [D|GT|LN|*]				For unseen events, the distributions can be smoothed. Methods: Fixed value [D], Good-Turing [GT], Louis-Nenkova [LN], or specific value (scientif notation)
# Order: -o [PQR,]				The order to apply the trivergence. It consists in the way that the divergences will be applied. In the case of KL the order isn't conmutative.
# 										For example, PQ,QR,PR; QP,QR,PR; PQ,RQ,RP; P,QR; ... The multiplicative trivergence has 6 letters, while the composite only 3.

#Hash
my %ngramsQ;
my %ngramsP;
my %ngramsR;
my %trivergence;

my %freqQ;
my %freqP;
my %freqR;

my %orderingOUT;

configParserAndRun();

sub configParserAndRun
{
	my %param;
	my $config;
	my $temp;
	my $DOM=XML::LibXML->load_xml(location=>$ARGV[0]);								#Load XML
	#Text processing config
	if($DOM->exists('/evaluation/text/@lang'))
	{
		$opts{l}=$DOM->findvalue('/evaluation/text/@lang');							#Language
	}
	else
	{
		die ("No language indicated\n");
	}
	#Trivergence config
	if($DOM->exists('/evaluation/trivergence/@smooth'))
	{
		$opts{s}=$DOM->findvalue('/evaluation/trivergence/@smooth');				#Smoothing method [D|GT|LN|*]
		die ("Incorrect smoothing method\n") unless($opts{s}=~m{^(?:(?:\d(?:\.\d+)?E-\d+)|GT|LN|D)$});
	}
	else
	{
		$opts{s}="LN";																#Default
	}
	foreach $config ($DOM->findnodes('/evaluation/trivergence/config'))
	{
		if($config->exists('./@norm'))												#Normalization for composition
		{
			$temp=$config->findvalue('./@norm');
			die "Wrong value for normalization [0|1]" if ($temp=~m{^\"(0|1)"$});
			push(@{$param{N}}, $temp);
		}
		else
		{
			push(@{$param{N}}, 1);
		}
		if($config->exists('./@method'))
		{
			$temp=$config->findvalue('./@method');
			die ("Incorrect Trivergence method\n") unless($temp=~m{^m|c$});
			push(@{$param{t}}, $temp);												#Method [m|c]
		}
		else
		{
			push(@{$param{t}}, "m");
		}
		if($config->exists('./@measure'))
		{
			$temp=$config->findvalue('./@measure');
			die ("Incorrect divergence measure\n") unless($temp=~m{^KL|JS|sJS$});
			push(@{$param{T}}, $temp);												#Measure [KL|JS|sJS]
		}
		else
		{
			push(@{$param{T}}, "KL");
		}
		if($config->exists('./@order'))
		{
			$temp=$config->findvalue('./@order');
			orderParser(order => $temp, type => $param{t}[-1]);						#We verify the order of the trivergence
			push(@{$param{order}}, $temp);											#Trivergence order
		}
		else
		{
			die "No Trivergence order given";
		}
	}
	#Other config
	$param{ID}=$DOM->findvalue('/evaluation/@id');
	$opts{OUT}=$DOM->findvalue('/evaluation/output/@path');							#Output path

	#Configuration for each set
	foreach my $set ($DOM->findnodes('/evaluation/set'))							#We can do multiple set of evaluations
	{
		$param{setID}=$set->findvalue('./@id');
		print($param{setID}."\n");
		%ngramsQ=%ngramsP=%ngramsR=();
		%freqQ=%freqP=%freqR=();
		%{$param{PR}}=();
		$param{Q}=$set->findvalue('./Q/@path');
		$param{QID}=$set->findvalue('./Q/@id');
		if($set->exists('./Q/@multi'))
		{
			$temp=$set->findvalue('./Q/@multi');									#Q is multidocument
			die "Wrong value for multi [0|1]" if ($temp=~m{^"(0|1)"$});
			$param{Multi}=$temp;
		}
		%{$param{PR}}=map{$_->{system} => $_->{path}} $set->findnodes('./PR/file');	#It fills a hash with each system's name and output path
		readQ(Q => $param{Q}, Multi => $param{Multi});
		readPR(PR => $param{PR});

		for($config=0; $config<@{$param{order}}; $config++)
		{
			print("\t$param{order}[$config]\t$param{T}[$config]\n");
			callerT(QID => $param{QID}, setID=>$param{setID}, ID => $param{ID}, order=> $param{order}[$config], T => $param{T}[$config], t => $param{t}[$config], N => $param{N}[$config]);
		}
	}
	printResults(ID => $param{ID});

}

sub printResults
{
	my %param=(
				ID => undef,
				@_
			  );
	my $system;
	my $set;
	my $order;
	my @orderingOUT=sort keys(%orderingOUT);
	my $type;
	my $FILE;
	open($FILE, '>:utf8', "$opts{OUT}/$param{ID}.summTriver")				#Create the output file
		or die "It couldn't be created $opts{OUT}/$param{ID}.summTriver";
	print($FILE "SYSTEM");
	foreach $order (@orderingOUT)
	{
		print($FILE "\t$order");
	}
	print($FILE "\n");
	foreach $set (keys(%trivergence))
	{
		foreach $system (keys(%{$trivergence{$set}}))
		{
			print($FILE "$system");
			foreach $order (@orderingOUT)
			{
				print($FILE "\t$trivergence{$set}{$system}{$order}");
			}
			print($FILE "\n");
		}
	}
}

sub callerT
{
	my %param=(
				order => undef,
				T => undef,
				t => undef,
				N => undef,
				ID => undef,
				QID => undef,
				setID => undef,
				@_
			  );
	my $FILE;
	my $type;
	my $system;
	#my %trivergence;
	# my %trivergence2;
	# my $order;
	# my %orders;
	# my @orders;
	#$sset=0 if($opts{R});
	#%trivergence=();
	foreach $type (keys(%ngramsR))													#				For all the types of n-grams
	{
		foreach $system (keys(%{$ngramsR{$type}}))
		{
			#print("$param{order}\_$param{T}\_$type\t$param{QID}\_$system\n");
			$orderingOUT{"$param{order}\_$param{T}\_$type"}=0;
			#$orderingOUT{"$param{order}\_$param{T}\_average"}=0;
			#print("Freq R: $freqR{$type}{$system}\n");
			$trivergence{$param{setID}}{"$param{QID}\_$system"}{"$param{order}\_$param{T}\_$type"}=  Trivergence(Q => $ngramsQ{$type}, fQ => $freqQ{$type},
																				 					 P => $ngramsP{$type}, fP => $freqP{$type},
																									 R => $ngramsR{$type}{$system}, fR => $freqR{$type}{$system},
																									 T => $param{T}, t => $param{t}, order => $param{order},
																									 N => $param{N}, sset => 1, smooth => $opts{s});
			#$trivergence{"$param{QID}\_$system"}{"$param{order}\_$param{T}\_average"}+=$trivergence{"$param{QID}\_$system"}{"$param{order}\_$param{T}\_$type"};
			#$trivergence{$system}{"AVERAGE"}+=$trivergence{$system}{$type};
		}
	}
	# foreach $type (keys(%trivergence))																#For all the types of n-grams
	# {
	# 	open($FILE, '>>:utf8', "$opts{OUT}/$param{ID}.tri_$param{T}_$param{order}")			#Create the output file
	# 		or die "It couldn't be created $opts{OUT}/$param{ID}.tri_$type\_$param{T}_$param{order}";
	#
	# 	foreach $system (sort { $trivergence{$type}{$a} <=> $trivergence{$type}{$b} } keys %{$trivergence{$type}})
	# 	{
	# 		print($FILE "$param{QID}\t$system\t");
	# 		print($FILE $trivergence{$type}{$system});
	# 		print ($FILE "\n");
	# 	}
	# 	close($FILE);
	# }
}

sub readPR
{
	my %param=(PR => undef, @_);
	my $system;
	my $text;
	foreach $system (keys(%{$param{PR}}))
	{
		$text=getText($param{PR}{$system});
		getNGrams(text => $text, system => $system);
	}
}

sub readQ
{
	my %param=(
				Q => undef,
				Multi => undef,
				@_
			  );
	my $file;
	my $text="";
	if($param{Multi})							#Multi document Summarization
	{
		opendir(DIR, $param{Q}) or die "It couldn't be opened the directory for Q: $opts{Q}";
		while($file=readdir(DIR))
		{
			next if ($file=~m{^\.});
			$text.=getText("$param{Q}/$file");
			$text.=" ";
		}
		die "No source text Q" if($text eq "");
		getNGrams(text => $text, Q => 1);
	}
	else
	{
		$text=getText($param{Q});
		die "No source text Q" if($text eq "");
		getNGrams(text => $text, Q => 1);
	}
}


sub getText
{
	my $FILE;
	my $line;
	my $text;
	open($FILE, '<:utf8', $_[0]) or die "It couldn't be opened the system's summary: $_[0]";
	while(<$FILE>)
	{
		$line=$_;
		chomp($line);
		$line=lc($line);
		$text.=" $line";
	}
	close($FILE);
	return($text);
}

sub getNGrams
{
	my %param=(
				text => "",
				Q => 0,
				system => "",
				@_
			  );
	my $type;
	my %n;
	my $gram;

	$param{text}=limpiar($param{text});
	%n=%{ngramsJM(text => $param{text}, lang => $opts{l}, uni=>0, num =>0, letter=>0, stop => 0, skipU => 4)};
	foreach $type (keys(%n))
	{
		if($param{Q})
		{
			foreach $gram (keys(%{$n{$type}}))
			{
				$ngramsQ{$type}{$gram}=$n{$type}{$gram};
				$freqQ{$type}+=$n{$type}{$gram};
			}
		}
		else
		{
			foreach $gram (keys(%{$n{$type}}))
			{
				$ngramsR{$type}{$param{system}}{$gram}=$n{$type}{$gram};
				$freqR{$type}{$param{system}}+=$n{$type}{$gram};
				$ngramsP{$type}{$gram}+=$n{$type}{$gram};
				$freqP{$type}+=$n{$type}{$gram};
			}
		}
	}
}
