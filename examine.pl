use strict;
use 5.10.0;

my %fh;
my %dh;

while(<>){
	chomp;
	my ($name, $size, $hash) = split /\t/;
	next if $name =~ /pl$/;
	next if $name =~ /html$/;
	next if $name =~ /dmu$/;
	next if $name =~ /Makefile/;
	$name =~ s/.*Photos/Photos/;
	## say $name;
	if (defined $fh{$hash}){
		my $dir = $fh{$hash};
		my $ndir = $name;
		$dir =~ s|[^/]*$||;
		$ndir =~ s|[^/]*$||;
		if ($dir eq $ndir){
			say "$name matches $fh{$hash}";
		} else {
			$dh{$dir}->{$ndir} = 1;
		}
	}
	else {$fh{$hash} = $name};

}

say ("\n## Directories");

foreach my $k (keys %dh){
	say $k;
	say join "\n", keys %{$dh{$k}};
	## say $dh{$k};
	say "";
}
