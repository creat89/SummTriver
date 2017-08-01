# Copyright (C) 2009-2015 Luis Adrián Cabrera-Diego; Juan-Manuel Torres-Moreno
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
# 	File: n-grams1.perl
#	V 1.1     27 january 2016
#  	Luis Adrián Cabrera Diego:
#		LIA/UAPV - Avignon, France
#		Adoc Talent Management - Paris, France
#		adrian.9819@gmail.com
#
# 	The fucntions to create unigrams, bigrams and skip bigrams comme from:
#		FRESA (a FRamework for Evaluating of Summaries Automatically
#	Base sur la divergence de KL (INEX 11, SanJuan et al 2011)
#	v 0.6	10 octobre 2012	stemming porter
#  	Juan-Manuel Torres-Moreno:
#		LIA/UAPV - Avignon, France
#		juan-manuel.torres@univ-avignon.fr

#N-grams program
#Created by: Luis Adrián Cabrera Diego
#Date: 30-01-2015
#Last update: 15-03-2017
#Version: 1.2
#Add of relative frequencies calculation
#Add the TF-IDF

use strict;
use utf8;
use Cwd;
use Storable;
use Data::Dumper;
use Lingua::StopWords qw( getStopWords );
use Lingua::Stem::Snowball;
binmode STDOUT, ":encoding(utf8)";

#The fuction ngramsJM is a basic way to generate n-grams
#Based on the method of create n-grams for FRESA
sub ngramsJM
{
	my %param=(
				stem => 1,														#Stemmin of words (1)
				ultra => 0,														#If ultra is bigger than 0, then it is used Ultrastemming instead of Porter stemmer
				stop => 1,														#Deletion of stopwords (1). If 2, the list from ./stop/$param{lang}.stop will be used
				case => 1,														#Convertion of text to lowecase (1)
				num => 1,														#Deletion of numbers (1)
				letter => 1,													#Delete of "words" of one letter
				freqR => 0,														#Use relative frequency instead of absolute frequency to weight vectors
				skip => 0,														#A vector composed of SX, SX-1 up to bigrams, where X is the size of the gap
				uni => 1,														#Unigrams
				bi => 1,														#Bigrams
				skipU => 0,														#Similar to skip, but it adds the unigrams to the vector. SUX, SUX-1 up to bigrams and unigrams.
				tri => 0,														#Trigrams
				tetra => 0,														#Tetragrams
				idf => "",														#IDF path
 				@_);
	my $text=$param{text} || die "There is no text";
	my $stop;
	my @text;
	my %unigrams=()		if($param{uni});
	my %bigrams=()		if($param{bi});
	my %skip=()			if($param{skip});
	my %trigrams=()		if($param{tri});
	my %tetragrams=()	if($param{tetra});
	my %skipU=()		if($param{skipU});
	my %idf 			if($param{idf});
	my @temp;
	my %temp;
	my $stopwords;
	$text=~s{\p{P}|\p{Sm}|\p{Sc}}{ }g;											#Deletes all the puctuation, maths and currency symbols
	$text=lc($text) if ($param{case});											#If 1 or nothing: lowercase
	$text=~s{\b\d+\b}{ }g if($param{num});										#If 1 or nothing: Delete numbers
	$text=~s{\b\w\b}{ }gi if($param{letter});									#If 1 or nothing: Delete of letters which alone
	$param{freqR}=1 if($param{idf} ne "");										#When TF-IDF is used we must use relative frequencies
	if($param{stop})															#If 1> or nothing: Delete stopwords
	{
		die "Not specified language" if($param{lang} eq "");
		if($param{stop}==2)
		{
			$stopwords=retrieve(getcwd()."/../LibGrl/StopLists/$param{lang}.stop");
		}
		else
		{
			$stopwords=getStopWords($param{lang}, 'UTF-8') unless ($param{lang} eq "ENCRYPT");#Gets the Hash ref of the stopwords in UTF8
			$stopwords=retrieve(getcwd()."/../LibGrl/StopLists/ADOC_STOPW.encrypt") if($param{lang} eq "ENCRYPT");
		}
		#print Dumper \$stopwords;
		foreach $stop (keys %$stopwords)
		{
			$text=~s{\b\Q$stop\E\b}{ }gi;											#Deletes the $stopwords
		}
		#print $text;
		#die;
	}
	#print "\n\n$text\n\n";
	$text=~s{^ +}{};
	$text=~s{ +$}{};
	@text=split(/ +/,$text);
	@text=@{stemming(\@text, $param{lang}, $param{ultra})} if($param{stem});	#If 1 or nothing: Stemming

	%unigrams=%{unigrammes(@text)}						if(@text>0 && $param{uni});
	%bigrams=%{bigrammes(@text)}						if(@text>1 && $param{bi});
	%skip=%{skipbigrams(\@text, $param{skip}, 0)} 		if(@text>1 && $param{skip}>0);			#Includes in one same vector, bigrams, SU3 and SU4
	%trigrams=%{trigrammes(@text)}						if(@text>2 && $param{tri});
	%tetragrams=%{tetragrammes(@text)}					if(@text>3 && $param{tetra});
	%skipU=%{skipbigrams(\@text, $param{skipU}, 1)}		if(@text>1 && $param{skipU}>0);

	if($param{freqR})															#We convert the absolute frequency to relative one
	{
		%unigrams=%{relative_freq(\%unigrams)}				if ($param{uni});
		%bigrams=%{relative_freq(\%bigrams)}				if ($param{bi});
		%trigrams=%{relative_freq(\%trigrams)}				if ($param{tri});
		%tetragrams=%{relative_freq(\%tetragrams)}			if ($param{tetra});
		%skip=%{relative_freq(\%skip)}						if ($param{skip});
		%skipU=%{relative_freq(\%skipU)}						if ($param{skipU});
	}

	if($param{idf} ne "")														#We modify the weight with IDF if a path is given
	{
		my %idf=%{retrieve($param{idf})}										#We open the idf file (must be an array of hashes)
			or die "It couldn't be opened the hash $param{idf}\n";
		%unigrams=%{IDF(\%unigrams, "uni", \%idf)}			if ($param{uni});
		%bigrams=%{IDF(\%bigrams, "bi", \%idf)}				if ($param{bi});
		%trigrams=%{IDF(\%trigrams, "tri", \%idf)}			if ($param{tri});
		%tetragrams=%{IDF(\%tetragrams, "tetra", \%idf)}	if ($param{tetra});
		%skip=%{IDF(\%skip, "skip", \%idf)}					if ($param{skip});
		%skipU=%{IDF(\%skipU, "skipU", \%idf)}				if ($param{skipU});
	}

	$temp{"uni"}   = \%unigrams								if ($param{uni});
	$temp{"bi"}    = \%bigrams 								if ($param{bi});
	$temp{"tri"}   = \%trigrams								if ($param{tri});
	$temp{"tetra"} = \%tetragrams							if ($param{tetra});
	$temp{"skip"}  = \%skip									if ($param{skip});
	$temp{"skipU"} = \%skipU								if ($param{skipU});

	return(\%temp);
}

sub stemming
{
	my @text=@{$_[0]};
	my @stext;
	my $word;
	if($_[2] > 0)																#Ultrastemming from Juan Manuel Torres Moreno
	{
		foreach $word (@text)
		{
			next if $word=~m{^$};
			$word=substr($word, 0, $_[2]);
			push(@stext, $word) if ($word ne "");
		}
	}
	else
	{
		die "Not specified language" if($_[1] eq "");
		my $stemmer=Lingua::Stem::Snowball->new(lang=> $_[1], encoding => 'UTF-8');
		foreach $word (@text)
		{
			next if $word=~m{^$};
		  	$word=$stemmer->stem($word);
		  	push(@stext, $word) if ($word ne "");
	  	}
  	}
  	return (\@stext);
}

sub unigrammes
{
	my %unigrammes = () ;
	for (my $i = 0; $i < @_; $i++) {									# Parcourir chaque mot de $text
	      	$unigrammes{$_[$i]}++;     									# Stocker le unigramme dans l'index du hachage %unigr ($unigr{"puces"}=1, $unigr{"informatique"}=1, etc}
 	}
 	return \%unigrammes
}

sub bigrammes
{
 	my $nbmots    = @_-1 ;
 	my %bigrammes = () ;
 	for (my $i = 0; $i < $nbmots; $i++) {								# Parcourir chaque mot de $text
	      	$bigrammes{$_[$i]." ".$_[$i+1]}++ ;     					# Stocker le bigram dans l'index du hachage %bigr ($bigr{"puces Intel"}=1, $bigr{"module informatique"}=1, etc}
 	}
 	return \%bigrammes
}

sub trigrammes
{
 	my $nbmots    = @_-2 ;
 	my %trigrammes = () ;
 	for (my $i = 0; $i < $nbmots; $i++) {								# Parcourir chaque mot de $text
	      	$trigrammes{$_[$i]." ".$_[$i+1]." ".$_[$i+2]}++;			# Stocker le trigram dans l'index
 	}
 	return \%trigrammes
}

sub tetragrammes
{
 	my $nbmots    = @_-3 ;
 	my %tetragrammes = () ;
 	for (my $i = 0; $i < $nbmots; $i++) {											# Parcourir chaque mot de $text
	      	$tetragrammes{$_[$i]." ".$_[$i+1]." ".$_[$i+2]." ".$_[$i+3]}++;			# Stocker le trigram dans l'index
 	}
 	return \%tetragrammes;
}

sub skipbigrams
{
	my @text = @{$_[0]};
	my $maxDist = $_[1];
  	my $numbWords = @text-1;
  	my %skipJM = () ;
  	for (my $i = 0; $i<$numbWords; $i++)
	{
		if($_[2] == 1)															#Skip bigrams with unigrams
		{
			$skipJM{$text[$i]}++;
		}
		for (my $j = $i+1; $j < $i+$maxDist; $j++)
		{
    		$skipJM{$text[$i]." ".$text[$j]}++ if($j < $numbWords+1) ;
       	}
  	}
  	return \%skipJM;
}

# sub SU3
# {
# 	my $nbmots=@_-2;
# 	my %SU3;
# 	for (my $i = 0; $i<$nbmots; $i++)
# 	{
# 		$SU3{$_[$i]." ".$_[$i+2]}++ if($i+2 < $nbmots+2) ;					#SU3
# 	}
# 	return(\%SU3);
# }

# sub SU4
# {
# 	my $nbmots=@_-2;
# 	my %SU4;
# 	for (my $i = 0; $i<$nbmots; $i++)
# 	{
# 		$SU4{$_[$i]." ".$_[$i+3]}++ if($i+3 < $nbmots+2) ;					#SU4
# 	}
# 	return(\%SU4);
# }

sub relative_freq
{
	my $ngram;
	my %hash=%{$_[0]};
	my %hashR=();
	my $size=0;
	foreach $ngram (keys(%hash))
	{
		$size+=$hash{$ngram};
	}
	#print("Size: $size\n");
	foreach $ngram (keys(%hash))
	{
		$hashR{$ngram}=$hash{$ngram}/$size;
		#print("$ngram: $hashR{$ngram}\n");
	}
	return(\%hashR);
}

sub IDF
{
	my $ngram;
	my %hash=%{$_[0]};
	my $type=$_[1];
	my %idf=%{$_[2]};
	foreach $ngram (keys(%hash))
	{
		#print "$ngram\n";
		if(exists($idf{$type}{$ngram}))
		{
			$hash{$ngram}*=$idf{$type}{$ngram};
		}
		else
		{
			#print "N-gram \"$ngram\" of type \"$type\" not found\n";
			die "N-gram \"$ngram\" of type \"$type\" not found";
		}
	}
	return(\%hash);
}
