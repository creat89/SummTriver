# Copyright (C) 2013-2015 Luis Adrián Cabrera-Diego
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
# 	File: limpiar.perl
#	V 0.35     3 april 2015
#  	Luis Adrián Cabrera Diego
#		LIA/UAPV - Avignon, France
#		Flejay Group - Paris, France
#		Adoc Talent Management - Paris, France
#		adrian.9819@gmail.com
#
#Cleaning subroutine
#Created by: Luis Adrián Cabrera-Diego
#Date: 6-02-13
#Last symbols update: 10-10-13
#Version: 0.35
#Last update: 3-04-15
#Notes:
# 	It was added the Private symbols
#	It was added more junk symbols
#	Simplify of the code using Unicode Properties
#	Correction of the position of some rules and no-breakable space added.

use strict;
use utf8;
binmode STDOUT, ":encoding(utf8)";
no warnings 'utf8';

my $symbols="•◦¤⊳⋄♦●–➢*+■";										#Symbols of lists

#Cleaning subroutine
sub limpiar
{
	my $linea=$_[0];
	#--Letters--
	$linea=~s{ﬁ}{fi}g;
	$linea=~s{ﬂ}{fl}g;
	$linea=~s{ﬀ}{ff}g;
	$linea=~s{ﬃ}{ffi}g;
	$linea=~s{ﬄ}{ffl}g;
	$linea=~s{œ}{oe}g;
	$linea=~s{Œ}{OE}g;
	$linea=~s{æ}{ae}g;
	$linea=~s{Æ}{AE}g;
	#Small caps
	$linea=~s{}{a}g;
	$linea=~s{}{b}g;
	$linea=~s{}{c}g;
	$linea=~s{}{d}g;
	$linea=~s{}{e}g;
	$linea=~s{}{f}g;
	$linea=~s{}{g}g;
	$linea=~s{}{h}g;
	$linea=~s{}{i}g;
	$linea=~s{}{j}g;
	$linea=~s{}{k}g;
	$linea=~s{}{l}g;
	$linea=~s{}{m}g;
	$linea=~s{}{n}g;
	$linea=~s{}{o}g;
	$linea=~s{}{p}g;
	$linea=~s{}{q}g;
	$linea=~s{}{r}g;
	$linea=~s{}{s}g;
	$linea=~s{}{t}g;
	$linea=~s{}{u}g;
	$linea=~s{}{v}g;
	$linea=~s{}{w}g;
	$linea=~s{}{x}g;
	$linea=~s{}{y}g;
	$linea=~s{}{z}g;

	$linea=~s{}{á}g;
	$linea=~s{}{à}g;
	$linea=~s{}{â}g;
	$linea=~s{}{ä}g;
	
	$linea=~s{}{ç}g;
	
	$linea=~s{}{é}g;
	
	$linea=~s{}{ü}g;
	$linea=~s{}{ö}g;
	$linea=~s{}{è}g;
	$linea=~s{}{î}g;
	
	$linea=~s{}{1}g;
	$linea=~s{}{2}g;
	$linea=~s{}{3}g;
	$linea=~s{}{4}g;
	$linea=~s{}{5}g;
	$linea=~s{}{6}g;
	$linea=~s{}{7}g;
	$linea=~s{}{8}g;
	$linea=~s{}{9}g;
	$linea=~s{}{0}g;	
	#---Symbols nomalization---
	$linea=~s{…}{...}g;
	$linea=~s{‘|’|′|΄|❜}{'}g;
	$linea=~s{”|“|„|″|‶}{"}g;											#The first 2 symbols are different
	$linea=~s{─|−|—|­}{–}g;												#Note: There is an invisible hyphen before the bracket. And the substitution it's not the common hyphen (-), it's a larger one
	$linea=~s{ | }{ }g;													#No-breakable (insecable) spaces to normal spaces
	$linea=~s{\. ?\. ?\. ?\. ?(\. ?)*}{ }g;
	$linea=~s{\* ?\* ?\* ?(\* ?)*}{ }g;
	$linea=~s{(?:=|-|–)+>}{•}g;
	$linea=~s{--+}{}g;													#To test
	$linea=~s{––+}{}g;													#To test
	$linea=~s{__+}{}g;													#To test
	$linea=~s{^\s*(✴|✶|✠|✷|⋆|[$symbols])}{•}g;							#Possible list symbols normalization
	#---Error from conversion errors---
	$linea=~s{̃}{}g;
	$linea=~s{̀}{}g;
	$linea=~s{́}{}g;
	$linea=~s{‫}{}g;														#An extrage symbol
	$linea=~s{ࠀ}{}g;													#Another extrange symbol
	$linea=~s{⁮|⁤}{}g;
	#---List symbols without information---
	$linea=~s{^• ?$}{}g;
	#---Useless symbols---
	$linea=~s{™|⋅|½|¼|±|¾|¿|&|∈|£|∑|µ|Þ|´|̂|·|⁄|¯|̧|̊|×|̈|μ|ø|~|°|`|→|⊂|↓|α|τ|∧|√|≤|∏|∣|∩|}{}g;
	$linea=~s{✵|☞|✟|ˆ|≡|←|├|│|└|¨|∨|∃|∀|¬|⊆|θ|⊥|®|§|∪|̨|γ|ð|δ|\\|✬|̆|β|✗|✔|∆|π|≥|©|≅|‰}{}g;
	$linea=~s{☎|✞|ε|⇔|σ|ν|||↑|≈|∼|↔|⌜|⍽|῎||͊|⌜|ʖ|φ|λ|✿|⇒|☛|ψ|≺|❀|ρ|κ|ω|░}{}g;
	$linea=~s{∝|≫|⊤|χ|υ|ϕ|⊃|ξ|ǫ|❳|∞|¸|✩|✫|✪|¦|ϻ|΍|‡|÷|©|⊗|ϑ|✝|^|˜}{}g;
	$linea=~s{✆||➂|➀||〈|〉|③|⊕|†}{}g;
	$linea=~s{\p{Co}}{}g;												#Private Symbols like , , 
	$linea=~s{\p{So}}{}g;												#Other symbols like ❄, ✎,
	$linea=~s{\p{Lo}}{}g;												#Other letters	 
	$linea=~s{\p{No}}{}g;												#Other numbers like superscripts ⁴,²
	$linea=~s{\p{Cs}}{}g;												#Delete subrrogate symbols
	#---Spaces---														#Must be at the end of the process
	$linea=~s{\t}{ }g;													#Note!!!: This line must be before the control symbols. Because one control symbol is the tab.
	$linea=~s{(?!\n)\s+}{ }g;											#NOTE!!!: This line must be before the control symbols. Because one control symbol is the tab.
	$linea=~s{(?!\n)\p{Cc}}{}g;											#Delete control symbols (several boxes are control symbols including \n); the (?!\n) avoid delete \n
	#$linea=~s{\s+}{ }g;												#To avoid an extrange mistake
	$linea=~s{^ }{};
	$linea=~s{ $}{};
	return($linea);
}
