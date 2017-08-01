# Copyright (C) 2015-2016  Luis Adrián Cabrera Diego
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
#		V 4.2  11 november 2016
#  		Luis Adrián Cabrera Diego adrian.9819@gmail.com

#Library to calculate the Trivergence
#Created by: Luis Adrián Cabrera Diego
#Date: 16-06-2015
#Version: 5.0
#Last update: 15-02-2017
#Notes:
#	The version 5.0 deletes completely the possibility to use a n-grams model language. Some erros were corrected in JS and KL.
#	The version 4.2 adds the possibility to use the unsmoothed and smoothed JS. And correction of the JS measure, there was an error in their calculation
#	The version 4.1 makes a correction with the n-gram model. It is possible to make use of vectorial model.
#	The version 4.0 support a merge of n-grams models
#	The version 3.2 includes a smoothing function caller and improves the code
#	The version 3.1 deletes the cardianality and changes the normalization for the composite trivergence
#	The version 3 corrects the way we calculate the probability of the divergences. The version 2 used to divide between the frequency instead of The
#		vocabulary size. The error commes from version 3.0bis, which was the one used in the next versions.

use strict;
use utf8;
use Storable;
use Data::Dumper;
use Clone 'clone';
use Cwd;
require "".getcwd()."/../LibGrl/smoothing.perl";
binmode STDOUT, ":encoding(utf8)";

#Trivergence
sub Trivergence
{
	my $key;
	my %order;
	my %trivergence;
	my %smooth; 								#It will be a hash reference
	my $pre_smooth;
	my %param=	(
					P => undef,
					R => undef,
					Q => undef,
					fP => undef,
					fR => undef,
					fQ => undef,
					T => "KL",					#Default. Others options: JS|sJS
					t => "m",					#Default. Other options: c (composition)
					sset => 1,					#Default. It will consider that R is a subset of P
					order => "",				#Order of the comparison
					N => 0,						#Normalizes the trivergence by composition multipliying inner divergence by * norm factor
					smooth => "LN",				#The smoothing for unseen values [FIXED|GT|LN]
					@_
				);
	#Parameters verification
	die "Hashes not defined" unless (defined($param{P}) || defined($param{Q}) || defined($param{R}));
	die "Frequencies not defined" unless (defined($param{fP}) || defined($param{fQ}) || defined($param{fR}));
	die "Wrong divergence [KL|JS|sJS]" unless ($param{T}=~m{^(?:s?JS|KL)$});
	die "Wrong smoothing [D|GT|LN] or not fixed one (ex. 1E-5, 2.5E-20)" unless ($param{smooth}=~m{^(?:(?:\d(?:\.\d+)?E-\d+)|GT|LN|D)$});
	die "Wrong type trivergence [m|c]" unless ($param{t}=~m{^(?:m|c)$});
	die "Order not defined" if ($param{order} eq "");
	$param{smooth}=0.0000000001 if($param{smooth} eq "D");
	#Trivergence order verification
	%order=%{orderParser(order => $param{order}, type => $param{t})};
	#Setting
	my $tri=0;

	#Hash cloning (deep copy) to avoid problems with data
	my %hashP=%{clone($param{P})};
	my %hashQ=%{clone($param{Q})};
	my %hashR=%{clone($param{R})};

	$param{Q}=\%hashQ;
	$param{R}=\%hashR;
	$param{P}=\%hashP;

	#If R is a subset of P
	if($param{sset})
	{
		foreach $key (keys(%{$param{R}}))										#The original hash is not changed because I copy the ref into a new hash
		{
			$param{P}{$key}-=$param{R}{$key};
			delete($param{P}{$key}) if ($param{P}{$key}==0);
		}
		$param{fP}-=$param{fR};
	}
	#print Dumper $param{P};

	#Smoothing excepting for JS
	unless($param{T} eq "JS")
	{
		($param{P}, $param{Q}, $param{R}, $pre_smooth)=smoothCaller(P => $param{P}, Q => $param{Q}, R => $param{R}, method => $param{smooth}, type => $param{T}, order => \%order);

		$smooth{P}=$pre_smooth->{P};
		$smooth{Q}=$pre_smooth->{Q};
		$smooth{R}=$pre_smooth->{R};
	}

	#Trivergence type
	if($param{t} eq "m")			#Multiplication
	{
		#Trivergence order
		if($param{T} eq "KL")
		{
			#Kullback-Leibler sorted by the last letter (to see clearer which smooth to use)
			$trivergence{"QP"}=KL(v1 => $param{Q}, v2 => $param{P}, f1 => $param{fQ}, f2 => $param{fP}, smooth => $smooth{P}) if(exists($order{"QP"}));
			$trivergence{"RP"}=KL(v1 => $param{R}, v2 => $param{P}, f1 => $param{fR}, f2 => $param{fP}, smooth => $smooth{P}) if(exists($order{"RP"}));

			$trivergence{"PQ"}=KL(v1 => $param{P}, v2 => $param{Q}, f1 => $param{fP}, f2 => $param{fQ}, smooth => $smooth{Q}) if(exists($order{"PQ"}));
			$trivergence{"RQ"}=KL(v1 => $param{R}, v2 => $param{Q}, f1 => $param{fR}, f2 => $param{fQ}, smooth => $smooth{Q}) if(exists($order{"RQ"}));

			$trivergence{"PR"}=KL(v1 => $param{P}, v2 => $param{R}, f1 => $param{fP}, f2 => $param{fR}, smooth => $smooth{R}) if(exists($order{"PR"}));
			$trivergence{"QR"}=KL(v1 => $param{Q}, v2 => $param{R}, f1 => $param{fQ}, f2 => $param{fR}, smooth => $smooth{R}) if(exists($order{"QR"}));
		}
		elsif($param{T} eq "sJS")
		{
			#Jensen-Shannon	(The smoothing for both letters must be sent)
			$trivergence{"PQ"}=JS(v1 => $param{P}, v2 => $param{Q}, f1 => $param{fP}, f2 => $param{fQ}, s1 => $smooth{P}, s2 => $smooth{Q}) if(exists($order{"PQ"}) | exists($order{"QP"}));
			$trivergence{"PR"}=JS(v1 => $param{P}, v2 => $param{R}, f1 => $param{fP}, f2 => $param{fR}, s1 => $smooth{P}, s2 => $smooth{R}) if(exists($order{"PR"}) | exists($order{"RP"}));
			$trivergence{"QR"}=JS(v1 => $param{Q}, v2 => $param{R}, f1 => $param{fQ}, f2 => $param{fR}, s1 => $smooth{Q}, s2 => $smooth{R}) if(exists($order{"QR"}) | exists($order{"RQ"}));
		}
		else	#Normal JS without smoothing
		{
			$trivergence{"PQ"}=JS(v1 => $param{P}, v2 => $param{Q}, f1 => $param{fP}, f2 => $param{fQ}) if(exists($order{"PQ"}) | exists($order{"QP"}));
			$trivergence{"PR"}=JS(v1 => $param{P}, v2 => $param{R}, f1 => $param{fP}, f2 => $param{fR}) if(exists($order{"PR"}) | exists($order{"RP"}));
			$trivergence{"QR"}=JS(v1 => $param{Q}, v2 => $param{R}, f1 => $param{fQ}, f2 => $param{fR}) if(exists($order{"QR"}) | exists($order{"RQ"}));
		}
		$tri=1;
		foreach $key (keys(%trivergence))
		{
			$tri*=$trivergence{$key};
		}

	}
	else
	{
		if($param{T} eq "KL")
		{
			#Kullback-Leibler sorted by the last letter (to see clearer which smooth to use)
			$trivergence{"Q,PR"}=compKL(v1 => $param{Q}, v2 => $param{P}, v3 => $param{R}, f1 => $param{fQ}, f2 => $param{fP}, f3 => $param{fR}, N => $param{N}, sI => $smooth{R}) if($order{"PR"} eq "right");
			$trivergence{"P,QR"}=compKL(v1 => $param{P}, v2 => $param{Q}, v3 => $param{R}, f1 => $param{fP}, f2 => $param{fQ}, f3 => $param{fR}, N => $param{N}, sI => $smooth{R}) if($order{"QR"} eq "right");

			$trivergence{"Q,RP"}=compKL(v1 => $param{Q}, v2 => $param{R}, v3 => $param{P}, f1 => $param{fQ}, f2 => $param{fR}, f3 => $param{fP}, N => $param{N}, sI => $smooth{P}) if($order{"RP"} eq "right");
			$trivergence{"R,QP"}=compKL(v1 => $param{R}, v2 => $param{Q}, v3 => $param{P}, f1 => $param{fR}, f2 => $param{fQ}, f3 => $param{fP}, N => $param{N}, sI => $smooth{P}) if($order{"QP"} eq "right");

			$trivergence{"P,RQ"}=compKL(v1 => $param{P}, v2 => $param{R}, v3 => $param{Q}, f1 => $param{fP}, f2 => $param{fR}, f3 => $param{fQ}, N => $param{N}, sI => $smooth{Q}) if($order{"RQ"} eq "right");
			$trivergence{"R,PQ"}=compKL(v1 => $param{R}, v2 => $param{P}, v3 => $param{Q}, f1 => $param{fR}, f2 => $param{fP}, f3 => $param{fQ}, N => $param{N}, sI => $smooth{Q}) if($order{"PQ"} eq "right");
		}
		elsif($param{T} eq "sJS")
		{
			#Jensen-Shannon Smoothed
			#For each composition we send the first outer smoothing value (belongs to the left distribution) and the two inner smoothings
			$trivergence{"Q,PR"}=compJS(v1 => $param{Q}, v2 => $param{P}, v3 => $param{R}, f1 => $param{fQ}, f2 => $param{fP}, f3 => $param{fR}, N => $param{N}, sO1 => $smooth{Q}, sI1 => $smooth{P}, sI2 => $smooth{R}) if($order{"PR"} eq "right" || $order{"RP"} eq "right");
			$trivergence{"P,QR"}=compJS(v1 => $param{P}, v2 => $param{Q}, v3 => $param{R}, f1 => $param{fP}, f2 => $param{fQ}, f3 => $param{fR}, N => $param{N}, sO1 => $smooth{P}, sI1 => $smooth{Q}, sI2 => $smooth{R}) if($order{"QR"} eq "right" || $order{"RQ"} eq "right");
			$trivergence{"R,PQ"}=compJS(v1 => $param{R}, v2 => $param{P}, v3 => $param{Q}, f1 => $param{fR}, f2 => $param{fP}, f3 => $param{fQ}, N => $param{N}, sO1 => $smooth{R}, sI1 => $smooth{P}, sI2 => $smooth{Q}) if($order{"PQ"} eq "right" || $order{"QP"} eq "right");
		}
		else
		{
			#Jensen-Shannon
			$trivergence{"Q,PR"}=compJS(v1 => $param{Q}, v2 => $param{P}, v3 => $param{R}, f1 => $param{fQ}, f2 => $param{fP}, f3 => $param{fR}, N => $param{N}) if($order{"PR"} eq "right" || $order{"RP"} eq "right");
			$trivergence{"P,QR"}=compJS(v1 => $param{P}, v2 => $param{Q}, v3 => $param{R}, f1 => $param{fP}, f2 => $param{fQ}, f3 => $param{fR}, N => $param{N}) if($order{"QR"} eq "right" || $order{"RQ"} eq "right");
			$trivergence{"R,PQ"}=compJS(v1 => $param{R}, v2 => $param{P}, v3 => $param{Q}, f1 => $param{fR}, f2 => $param{fP}, f3 => $param{fQ}, N => $param{N}) if($order{"PQ"} eq "right" || $order{"QP"} eq "right");
		}
		foreach $key (keys(%trivergence))	#In this case it is only one possible solution
		{
			$tri=$trivergence{$key};
			last;
		}
	}
	return($tri);
	#return(\%trivergence);
}

sub smoothCaller
{
	my %param=(
					P => undef,
					R => undef,
					Q => undef,
					order => undef,
					type => "",
					method => "",
					@_
				);
	my %smooth;
	my %order=%{$param{order}};
	if($param{method} ne  "GT" && $param{method} ne  "LN")					#Type of smoothing
	{
		$smooth{P}=$smooth{Q}=$smooth{R}=$param{method};
	}
	else
	{
		if($param{type} eq "KL")									#Divergence measure is Kullback-Leibler
		{
			($param{P}, $smooth{P})=smoothing_all(H=>$param{P}, method=>$param{method}) if(exists($order{"QP"}) || exists($order{"RP"}));
			($param{Q}, $smooth{Q})=smoothing_all(H=>$param{Q}, method=>$param{method}) if(exists($order{"PQ"}) || exists($order{"RQ"}));
			($param{R}, $smooth{R})=smoothing_all(H=>$param{R}, method=>$param{method}) if(exists($order{"PR"}) || exists($order{"QR"}));
		}
		elsif ($param{type} eq "sJS")								#Divergence measure is smoothed Jensen-Shannon
		{													#We need to calculate more smoothing as it is symmetric this divergence.
															#The last option in the if is for the trivergence by composition.
			($param{P}, $smooth{P})=smoothing_all(H=>$param{P}, method=>$param{method}) if(exists($order{"PQ"}) || exists($order{"PR"}) || exists($order{"QP"}) || exists($order{"RP"}) || exists($order{"P"}));
			($param{Q}, $smooth{Q})=smoothing_all(H=>$param{Q}, method=>$param{method}) if(exists($order{"PQ"}) || exists($order{"QR"}) || exists($order{"QP"}) || exists($order{"RQ"}) || exists($order{"Q"}));
			($param{R}, $smooth{R})=smoothing_all(H=>$param{R}, method=>$param{method}) if(exists($order{"PR"}) || exists($order{"QR"}) || exists($order{"RP"}) || exists($order{"RQ"}) || exists($order{"R"}));
		}
	}
	#print Dumper \%smooth;
	return ($param{P}, $param{Q}, $param{R}, \%smooth);							#P, Q and R are references
}

sub orderParser
{
	my %param=(
					order => "",
					type => "",
					@_
			  );
	my %order;
	die "Wrong syntax" if($param{order}=~m{[^PQR,]}gi);													#We verify if the order contains the correct letters
	die "Wrong syntax" if($param{order}=~m{^,|,$});														#We verify if the comma is at the end of the order
	uc($param{order});																					#Upper case
	if($param{type} eq "m")
	{
		die "Wrong order syntax ".$param{order} if(length($param{order}) != 8);							#We verify if the size of order
		die "Wrong order syntax ".$param{order} unless($param{order}=~m{(?:^|,)(?:PQ|QP){1}(?:,|$)});	#We verify one possible combination
		die "Wrong order syntax ".$param{order} unless($param{order}=~m{(?:^|,)(?:PR|RP){1}(?:,|$)});	#We verify one possible combination
		die "Wrong order syntax ".$param{order} unless($param{order}=~m{(?:^|,)(?:QR|RQ){1}(?:,|$)});	#We verify one possible combination
		@order{split(/,/,$param{order})}=();
	}
	else
	{
		die "Wrong order syntax ".$param{order} if(length($param{order}) != 4);							#We verify if the size of order
		#die "Wrong order syntax" unless($order=~m{^(?:..,)?[PQR]{1}(?:,..)?$});						#We verify one possible combination (for the right or left)
		die "Wrong order syntax ".$param{order} unless($param{order}=~m{P{1}});							#We verify one possible combination
		die "Wrong order syntax ".$param{order} unless($param{order}=~m{Q{1}});							#We verify one possible combination
		die "Wrong order syntax ".$param{order} unless($param{order}=~m{R{1}});							#We verify one possible combination
		die "Wrong order syntax ".$param{order} unless($param{order}=~m{(?:PQ|QP|QR|RQ|PR|RP){1}});		#We verify one possible combination
		$param{order}=~s{,}{,left;};																	#Each part is separated by side left or right
		$param{order}=~s{$}{;right};
		%order=split(/[,;]/,$param{order});
	}
	return(\%order);
}

sub probability
{
	my %param=(@_);
	my $type;
	my $prob=0;											#The value if no smoothing is used
	$prob=$param{smooth} if(defined($param{smooth}));	#Not used in some cases, only if needed
	$prob=$param{dist}{$param{gram}}/$param{size} if(exists($param{dist}{$param{gram}}));
	return $prob;
}

sub KL
{
	my %param=(@_);
	my $gram;
	my $KL=0;
	my $P1;
	my $P2;
	my $norm=0;										#The maximum divergence is calculated (to use it for the composite trivergence)
	foreach $gram (keys(%{$param{v1}}))
	{
		$P2=probability(gram=>$gram, dist=>$param{v2}, size=>$param{f2}, smooth=>$param{smooth});
		$P1=probability(gram=>$gram, dist=>$param{v1}, size=>$param{f1});
		$KL+=$P1*log2($P1/$P2);

		if($param{norm})		#Calculation of the normalization factor
		{
			$P2=$param{smooth};
			$norm+=$P1*log2($P1/$P2);
		}
	}
	return($KL, $norm)								if($param{norm});
	return($KL);
}

sub JS
{
	my %param=(@_);
	my $gram;
	my $JS=0;
	my $norm=0;											#The maximum divergence is calculated (to use it for the composite trivergence)
	my $P1;
	my $P1b;
	my $P2;
	my $P2b;
	my %merge = (%{$param{v1}},%{$param{v2}});			#We obtain the vocabulary used in both distributions


	foreach $gram (keys(%merge))
	{
		#print("$gram: $merge{$gram}\n");
		if(defined($param{s2}) && defined($param{s1}))	#If the smooth is defined
		{
			$P1=probability(gram=>$gram, dist=>$param{v1}, size=>$param{f1}, smooth=>$param{s1});
			$P2=probability(gram=>$gram, dist=>$param{v2}, size=>$param{f2}, smooth=>$param{s2});

		}
		else
		{
			$P1=probability(gram=>$gram, dist=>$param{v1}, size=>$param{f1});
			$P2=probability(gram=>$gram, dist=>$param{v2}, size=>$param{f2});
		}
	#	print("\tProb $gram:\t\t\t$P1 ($param{v1}{$gram}), $P2 ($param{v2}{$gram})\n");
		#Right
		$JS+=$P1*log2((2*$P1)/($P1+$P2)) if(exists($param{v1}{$gram}));			#We only do the right side if it exists in the right document
		#Left
		$JS+=$P2*log2((2*$P2)/($P1+$P2)) if(exists($param{v2}{$gram}));			#We only do the left side if it exists in the left document

		if($param{norm})																#Normalization factor
		{
			if(defined($param{s2}) && defined($param{s1}))								#If we calculated previously a smooth
			{
				$P2b=smooth=>$param{s2};
				$P1b=smooth=>$param{s1};
			}
			else
			{
				$P2b=0;																	#As there is no smoothing this is zero
				$P1b=0;
			}
			#Right
			$norm+=$P1*log2(2*$P1/($P1+$P2b)) if(exists($param{v1}{$gram}));
			#Left
			$norm+=$P2*log2(2*$P2/($P1b+$P2)) if(exists($param{v2}{$gram}));
		}
	}
	return($JS/2, $norm)								if($param{comp});
	return($JS/2);
}

sub compKL
{
	my %param=(@_);
	my $KL;
	my $KL2=0;
	my $P1;
	my $P2;
	my $gram;
	my $norm;

	($KL,$norm)=KL(v1 => $param{v2}, v2 => $param{v3}, f1 => $param{f2}, f2 => $param{f3}, norm => $param{N}, smooth => $param{sI});
	$KL/=$norm if($norm!=0);												#This will be true only when $param{N} is equal to 1
	foreach $gram (keys(%{$param{v1}}))
	{
		$P2=0.0000000001;					#Smoothing for the outer divergence (We haven't found a method to smooth this value as P2 is a constant)
		$P2=$KL 							if (exists($param{v2}{$gram}));

		$P1=probability(gram=>$gram, dist=>$param{v1}, size=>$param{f1});
		$KL2+=$P1*log2($P1/$P2);
 	}
	return($KL2);
}


sub compJS
{
	my %param=(@_);
	my $JS;
	my $norm;
	my %merge = (%{$param{v2}},%{$param{v3}});									#It doesn't matter the values only the keys
	my %all=(%{$param{v1}},%{$param{v2}},%{$param{v3}});						#It doesn't matter the values only the keys
	my $JS2=0;
	my $gram;
	my $P1;
	my $P2;
	if(defined($param{sI1}) && defined($param{sI2}))							#If the interior smoothings are defined
	{
		($JS, $norm)=JS(v1 => $param{v2}, v2 => $param{v3}, f1 => $param{f2}, f2 => $param{f3}, norm => $param{N}, s1 => $param{sI1}, s2 => $param{sI2});
	}
	else
	{
		($JS, $norm)=JS(v1 => $param{v2}, v2 => $param{v3}, f1 => $param{f2}, f2 => $param{f3}, norm => $param{N});
	}
	$JS/=$norm if($norm!=0);						#This will be true only when $param{N} is equal to 1
	foreach $gram (keys(%all))
	{
		#First smoothing for the outer divergence (The left distribution)
		if(defined($param{sO1}))
		{
			$P1=probability(gram=>$gram, dist=>$param{v1}, size=>$param{f1}, smooth=>$param{sO1});
			$P2=0.0000000001;							#Smoothing for the outer divergence (We haven't found a method to smooth this value as P2 is a constant)
		}
		else
		{
			$P1=probability(gram=>$gram, dist=>$param{v1}, size=>$param{f1});
			$P2=0;
		}
		$P2=$JS 						  if(exists($merge{$gram}));				#If the event existed in the inner divergence, then, we can use it's value
		#Right
		$JS2+=$P1*log2((2*$P1)/($P1+$P2)) if(exists($param{v1}{$gram}));			#We only do this side if exists in the right document
		#Left
		if(exists($merge{$gram}))													#We only do this side if exists in the right document
		{
			$JS2+=$P2*log2((2*$P2)/($P1+$P2)) if($P2!=0);							#but also when the divergence was different from 0
		}

	}
	return($JS2/2);
}

sub log2
{
	return log($_[0])/log(2);
}
1;
