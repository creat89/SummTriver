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
# -----	Program to calculate different smoothing methods
#	V 1.0  9 March 2017
#  	Luis Adrián Cabrera Diego adrian.9819@gmail.com
use strict;
use utf8;
binmode STDOUT, ":encoding(utf8)";

sub smoothing_all
{
	my %param=	(
					H => undef,
					method => "",
					@_
				);
	die "Hash not defined" unless (defined($param{H}));
	die "Smoothing method not defined" unless ($param{method} ne "");
	return good_turing($param{H}) if($param{method} eq "GT");
	return louis_nenkova($param{H}) if($param{method} eq "LN");
	die "Unknown Smoothing method";
}

sub good_turing
{
	my %original=%{$_[0]};
	my %smoothed;
	my %Nc;
	my $c;
	my $total=0;
	my $gram;
	my $unkn;
	my %smoothed;
	my $min=-1;																	#Smaller frenquency
	my $max=-1;
	foreach $gram (keys(%original))
	{
		$total+=$original{$gram};
		$Nc{$original{$gram}}++;												#Frequency of frequencies
		if($original{$gram} < $min || $min==-1)
		{
			$min=$original{$gram};												#Min should be in theory 1, but in some cases it is not the case
		}
	}
	$unkn=$Nc{$min}/$total**2;													#The value for unknown cases.
	foreach $gram (keys(%original))
	{
		$c=$original{$gram};
		if(exists($Nc{$c+1}))
		{
			$smoothed{$gram}=($c+1)*($Nc{$c+1}/$Nc{$c});
		}
		else
		{
			$smoothed{$gram}=$c;
		}
	}
	return(\%smoothed, $unkn);
}

#Only for divergences. See the formula in Automatically Assessing Machine Summary Content Without a Gold Standard
#Note: I multiply the resulting value by total (document size) although it is not done in the article. The reason
# is that in trivergenciaSR3,2, I divide the count number, by the document size. Thefore, the only way to use in
#trivergenciaSR3,2 the smoothed value is to multiply the value by total, which will disapear when it'll be devided
#by total.
sub louis_nenkova
{
	my %original=%{$_[0]};
	my %smoothed;
	my $total=0;
	my $gram;
	my $unkn;
	my $den;																	#Denominator of the smoothing
	my $delta=0.0005;
	my $V=keys(%original);														#Vocabulary size (different from total, which document size)
	foreach $gram (keys(%original))
	{
		$total+=$original{$gram};
	}
	#print("Total: $total\n Den:");
	$den=$total+($delta*1.5*$V);
	#print("$den\n");
	$unkn=($delta/$den);														#Unknown is the only value in which it should be given the probabily
	foreach $gram (keys(%original))
	{
		#print("Original: $gram\t$original{$gram}\n");
		$smoothed{$gram}=$total*(($original{$gram}+$delta)/$den);
	}
	return(\%smoothed, $unkn);
}
