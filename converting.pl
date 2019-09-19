#my $string = "lr 22";
my $string = "0x6c72203sfdgsdfgsd";

if ($string !~ /^0x.*/) {
$string =~ s/(.)/sprintf("%x",ord($1))/eg;

my $n = 12-length($string);
for (my $i=0; $i < $n; $i++) {
 $string="$string" . "0";
}
$string = "0x$string";
}
print "$string\n";

#-----
#Test_hash
my %lldp_local_Chassi = (
'lldp_local_Chassi_bulk' => '.1.0.8802.1.1.2.1.3',
'lldpLocChassisIdSubtype' => '.1.0.8802.1.1.2.1.3.1.0',
'lldpLocChassisId' => '.1.0.8802.1.1.2.1.3.2.0',
'lldpLocSysName' => '.1.0.8802.1.1.2.1.3.3.0',
'lldpLocSysDesc' => '.1.0.8802.1.1.2.1.3.4.0',
'lldpLocSysCapSupported' => '.1.0.8802.1.1.2.1.3.5.0',
'lldpLocSysCapEnabled' => '.1.0.8802.1.1.2.1.3.6.0'
);


foreach $k (keys %lldp_local_Chassi){
print "$k = $lldp_local_Chassi{$k}\n";
}

print $lldp_local_Chassi{'lldpLocSysName'};






		if ($value !~ /^0x.*/) { # это условие преобразует криво закодированный hex
			$value =~ s/(.)/sprintf("%x",ord($1))/eg;
			my $n = 12-length($value);
			for (my $i=0; $i < $n; $i++) {
				$value="$value" . "0";
			}
			$value = "0x$value";
		}
		
		
		
		my %loc_port_param = (
 'ifIndex' => ['.1.3.6.1.2.1.2.2.1.1','to_walk']
,'ifName' => ['.1.3.6.1.2.1.31.1.1.1.1','to_walk']
,'ifAdminStatus' => ['.1.3.6.1.2.1.2.2.1.7','to_walk']
,'ifOperStatus' => ['.1.3.6.1.2.1.2.2.1.8','to_walk']
,'IfHighSpeed' => ['.1.3.6.1.2.1.31.1.1.1.15','to_walk']
);


foreach my $key ( keys %loc_port_param )  {
    print "$key\t";
    print ( @{$loc_port_param{$key}}[0] )  ;

    print "\n"
}

#############

my @array = ( [1, 2, 3, 4], ['q', 'w', 'e', 'r'] );
my @ar=('m','n','b','v');



foreach (@array) {


my @i = @$_;
foreach (@i) {
print "$_\n";
}
print "\n";
}




#############



# Тут я пытался сделать 
#			if ($is_first){
#				$is_first=0;
#				push @first_walk, @walk_strings;
#			} else{
#				foreach my $j  (0 .. $#first_walk){
#					push @{$first_walk[$j]} , @{$walk_strings[$j]};
#				}
#			}
		}
		
	}
#	foreach my $element (@first_walk) {
#		
#		print join("\t","@{$element}\n");
#	}