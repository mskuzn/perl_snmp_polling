#!/usr/local/bin/perl
use strict;
use warnings;
use diagnostics;
use Net::SNMP;


my $file_start = 'hosts.txt';
open(my $fs, '<', $file_start) or die "Не могу открыть '$file_start' $!";

my $file_fin = 'result.txt';
open(my $ff, '>>', $file_fin) or die "Не могу открыть '$file_fin' $!";


while (my $row = <$fs>) {
	chomp $row;
	my 	
	my @data_object = split(/\t/,$row);
	my $snmp_oid=$data_object[6];  
	my $snmp_host = $data_object[5];
	my $snmp_community = $data_object[4];
	my $z = $snmp_oid;

	eval {
	my $snmp_session = Net::SNMP->session(-hostname => $snmp_host,-community => $snmp_community,-version => 2,) or die '$!Не удалось соединиться!';
	my $result = $snmp_session->get_request(-varbindlist => [$z],)or die 'Не удалось udastsia!';

	my $addr = $snmp_session->var_bind_list();
	my %hash = %$addr;
		for my $key (keys %hash) {
			my $value = $hash{$key};

		if ($value !~ /^0x.*/) { # это условие преобразует криво закодированный hex
			$value =~ s/(.)/sprintf("%x",ord($1))/eg;
			my $n = 12-length($value);
			for (my $i=0; $i < $n; $i++) {
				$value="$value" . "0";
			}
			$value = "0x$value";
		}
			$z=$key;
			if ($z =~ /(^$snmp_oid).*$/){
				print $ff join("\t",@data_object);
				print $ff "\t $key \t $value\n";
			}
			else {goto END_NODE;}
		}
	$snmp_session->close();
	};
	if ($@) {print $@;print $ff join("\t",@data_object); print $ff "\t$data_object[6]\tError\n"; goto END_NODE; }
	while (1) {
		eval {
			my $snmp_session = Net::SNMP->session(-hostname => $snmp_host,-community => $snmp_community,-version => 2,) or die 'Не удалось соединиться!';
			my $result = $snmp_session->get_next_request(-varbindlist => [$z],)or die 'Не удалось udastsia!';

			my $addr = $snmp_session->var_bind_list();
			my %hash = %$addr;

			for my $key (keys %hash) {
				my $value = $hash{$key};
				
			if ($value !~ /^0x.*/) { # это условие преобразует криво закодированный hex
				$value =~ s/(.)/sprintf("%x",ord($1))/eg;
				my $n = 12-length($value);
				for (my $i=0; $i < $n; $i++) {
					$value="$value" . "0";
				}
				$value = "0x$value";
			}
				$z=$key;
				if ($z =~ /(^$snmp_oid).*$/){
					print $ff join("\t",@data_object);
					print $ff "\t $key \t $value\n";
				}
				else {goto END_NODE;}
			}
			$snmp_session->close();
			};
		if ($@) {print $ff join("\t",@data_object); print $ff "\t$data_object[6]\tError\n"; goto END_NODE; }
	}
END_NODE:
}
close $ff;