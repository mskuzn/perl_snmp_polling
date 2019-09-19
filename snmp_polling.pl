#!/usr/local/bin/perl
#V3 изменения от 30.10.2018
use strict;
use warnings;
use diagnostics;
use Net::SNMP;
use threads;
use threads::shared;
use Time::HiRes;

eval { unlink ('result.txt') or die "$!";};  if ($@) {print "$@\n"; } #файл с предыдущими результатами удаляется
my $file_start = 'hosts.txt';
open(my $fs, '<', $file_start) or die print "Unable to open '$file_start' $!";

my $file_accessory = 'snmp_oids.txt';
open(my $fa, '<', $file_accessory) or die print "Unable to open '$file_accessory' $!";

my $file_fin = 'result.txt';
my $qurent_region = 'start_value';


our $return_tab:shared;

my $thred_limit = 10;
our @threads_status_arr:shared; #массив содержащий статус выполнения того или иного потока

my @threads;
my @snmp_set;
while (my $row = <$fa>){
	chomp $row;
	my @oids = split(/\t/,$row);
 	push  @snmp_set, [@oids];
}



sub snmp_get{
	my ($farsh,$snmp_community, $snmp_host, $snmp_oid) = @_;
	my $z = $snmp_oid;
	my @ret;
	eval {
	my $snmp_session = Net::SNMP->session(-hostname => $snmp_host,-community => $snmp_community,-version => 2,) or die "$! (Unable to connect!)";
	my $result = $snmp_session->get_request(-varbindlist => [$z],)or die "$! (Unable to poll!)";

	my $addr = $snmp_session->var_bind_list();
	my %hash = %$addr;
		for my $key (keys %hash) {
			my $value = $hash{$key};
			@ret =  ($farsh,$key, $value);
		}
	$snmp_session->close();
	};if ($@) {
	my $cho =$@;
	chomp $cho;
	$cho = ' Unable to ' . $cho;
	@ret =  ($farsh,'',$cho);
	}
	return  @ret;
}

sub snmp_walk{ #функция возвращает массив массивов во внутреннем массиве 3 записи.
	my ($farsh,$snmp_community, $snmp_host, $snmp_oid) = @_;
	my $z = $snmp_oid;
	my @ret;
	do{
		eval {

			my $snmp_session = Net::SNMP->session(-hostname => $snmp_host,-community => $snmp_community,-version => 2,) or die "$! (Unable to connect!)";
			my $result = $snmp_session->get_next_request(-varbindlist => [$z],)or die "$! (Unable to poll!)";

			my $addr = $snmp_session->var_bind_list();
			my %hash = %$addr;
			for my $key (keys %hash) {
				my $value = $hash{$key};
			

				$z=$key;

				if ($z =~ /(^$snmp_oid).*$/) {push @ret, [$farsh,$key,$value]; }
				elsif(@ret==0){push @ret, [$farsh,'','noInstancesOnBranch'];}
			}

		$snmp_session->close();
		};
		if ($@) {
			my $cho =$@;
			chomp $cho;
			$cho = ' Unable to ' . $cho;
			push @ret, [$farsh,'',$cho];
			$z='start_value';
		}
	}while($z =~ /(^$snmp_oid).*$/); #если следующий OID принадлежит исходной ветви,то идём на следующий круг.
	return  @ret;
}

sub snmp_get_all{   #Функция ничего не возвращает она тупо записывает результаты в print $файл
	my ($farsh_tab,$snmp_community_tab, $snmp_host_tab, $snmp_oid_tab,$slot_thred) = @_;
	my @ret_tab;
	my @walk_strings=(['START VALUE','START VALUE']);
	print "Стартуем опрос >>>> Thread $slot_thred >>>>> $farsh_tab\n";
	
	foreach (@$snmp_oid_tab) { #цикл по OID-ам
	if (@walk_strings==0) {@walk_strings = (['START VALUE','START VALUE']);}
		my @last_val=@{$walk_strings[$#walk_strings]}; #в последнем массиве
		my $last_string = $last_val[$#last_val]; #последняя запись

		if (($last_string !~ /^.*Unable to .*$/) && (@$_->[2] eq 'to_walk')) { # если запрос по предыдущему OID-у прокатил и текущий OID должен учесть индексы

			@walk_strings = snmp_walk("$farsh_tab\t@$_->[0]\t@$_->[1]\t@$_->[2]",$snmp_community_tab, $snmp_host_tab, @$_->[1]); # для текущего OID получаем walk (в виде массива массивов)
			
			foreach (@walk_strings) { #цикл по записям команды типа Walk
				my @i=@$_; #получаем строку в виде массива

				push @ret_tab, [@i];
			}

		}elsif(($last_string !~ /^.*Unable to .*$/) && (@$_->[2] eq 'to_get')) {
			my @get_string = snmp_get("$farsh_tab\t@$_->[0]\t@$_->[1]\t@$_->[2]",$snmp_community_tab, $snmp_host_tab, @$_->[1]); # для текущего OID получаем одну строку get (в виде массива)
			push @ret_tab, [@get_string];
		}

	}
		foreach (@ret_tab) {
			$return_tab .= join ("\t",@$_, "\n");
		}

	print "Окончен опрос >>>> Thread $slot_thred >>>>>  $farsh_tab\n";
	$threads_status_arr[$slot_thred] = 1;
    return;
	threads->exit();

}

my @hosts; #массив массивов
#Нарезаем файл на массив массивов
while (my $row = <$fs>) { #цикл по строкам файла с хостами (по фаршу)
	chomp $row;
	push @hosts, [split(/\t/,$row)]; #Разделили строку по знаку табуляции.
}
my $host_row_count = $#hosts+1; #количество строк с хостами

if($host_row_count<$thred_limit){#Учёт случая, когда хостов меньше, чем лимит трэдов
$thred_limit=$host_row_count; #снижаем лимит тредов
}



#цикл по хостам, идущим в первую серию трэдов
for(my $thread_i=0;$thread_i<$thred_limit;$thread_i++){
	push @threads_status_arr, 0;
	push @threads, threads->create(\&snmp_get_all, $hosts[$thread_i][0] . "\t" . $hosts[$thread_i][5],$hosts[$thread_i][4],$hosts[$thread_i][5],\@snmp_set,$thread_i);

}
#цикл по всем остальным хостам
for(my $thread_i=$thred_limit;$thread_i<$host_row_count;$thread_i++){
	while(1){ # бесконечно проверяем трэды, пока один из них не отработает
		my $n=0;
		foreach my $thread_is_done (@threads_status_arr){
			if ($thread_is_done){
				$threads[$n]->join();
				$threads[$n]=threads->create(\&snmp_get_all, $hosts[$thread_i][0] . "\t" . $hosts[$thread_i][5],$hosts[$thread_i][4],$hosts[$thread_i][5],\@snmp_set,$n);
				$threads_status_arr[$n]=0;
				goto NEXT_HOST;
			}
		$n++;
		}
	Time::HiRes::usleep(100); #Задержка, чтобы не грузить проц
	}

	NEXT_HOST:
}

#ждём выполнения последней группы трэдов
foreach my $thread (@threads) {
	$thread->join ();
}

open(my $ff, '>>', $file_fin) or die print "Unable to open '$file_fin' $!";
print $ff $return_tab;
close $ff;
print "\nDone!\n";