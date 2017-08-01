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
	#my %temp;				#To test result JM
	#Good_Turing_smooth(\%original, \%temp);
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
		# $max=$original{$gram} if($original{$gram} > $max);						#Max
	}
	#print("start $total:\t");
	# foreach $c (sort{ $a <=> $b } keys(%Nc))
	# {
	# 	print("$c -> $Nc{$c} ");
	# 	#print("$c ");
	# }
	# print("\n");
	#die "No frequencies of 1 $min" unless(exists($Nc{1}));
	#print("NC=$Nc{1}\ttotal: $total\n");
	$unkn=$Nc{$min}/$total**2;													#The value for unknown cases.
	foreach $gram (keys(%original))
	{
		$c=$original{$gram};
		if(exists($Nc{$c+1}))
		{
			$smoothed{$gram}=($c+1)*($Nc{$c+1}/$Nc{$c});
		}
		# elsif($c+1<$max)
		# {
		# 	for(my $i=$c+1; $i<=$max; $i++)										#We try to avoid the holes (with the next freq)
		# 	{
		# 		if(exists($Nc{$c+$i}))
		# 		{
		# 			$smoothed{$gram}=($c+$i)*($Nc{$c+$i}/$Nc{$c});
		# 			last;
		# 		}
		# 	}
		# }
		else
		{
			$smoothed{$gram}=$c;
			#$smoothed{$gram}=($c+1)*(($Nc{$min}/$total)/$Nc{$c});				#We consider the next value of max as an unseen event count ($Nc{$min}/$total)
			# for(my $i=$max; $i>=$min; $i--)									#We try to avoid the holes (with the second biggest freq
			# {
			# 	if(exists($Nc{$c-$i}))
			# 	{
			# 		$smoothed{$gram}=($c-$i)*($Nc{$c-$i}/$Nc{$c});
			# 		last;
			# 	}
			# }
		}
	}
	#print("$unkn\n");
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
