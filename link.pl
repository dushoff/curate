use strict;
use 5.10.0;

use File::Path qw(make_path);
use Cwd;

my $cwd = getcwd."/";  
my $targetdir = "album";

my %fh;
my %dh;

while(<>){
	chomp;
	my ($name, $size, $hash) = split /\t/;

	next if $size < 2e5;

	next if $name =~ /Makefile/;
	next if $name =~ /README/;
	next if $name =~ /Desc/;
	next if $name =~ /dmake/;
	next if $name =~ /~$/;

	next if $name =~ /pl$/i;
	next if $name =~ /html$/i;
	next if $name =~ /dmu$/i;
	next if $name =~ /jpt$/i;
	next if $name =~ /scr$/i;
	next if $name =~ /thm$/i;
	next if $name =~ /mk$/i;
	next if $name =~ /css$/i;
	next if $name =~ /ctg$/i;
	next if $name =~ /ini$/i;
	next if $name =~ /tgz$/i;
	next if $name =~ /zip$/i;
	next if $name =~ /gif$/i;
	next if $name =~ /swp$/i;
	next if $name =~ /md$/i;
	next if $name =~ /sed$/i;
	next if $name =~ /bak$/i;
	next if $name =~ /log$/i;
	next if $name =~ /miff$/i;
	next if $name =~ /ps$/i;

	next if $name =~ /avi$/i;
	next if $name =~ /mov$/i;
	next if $name =~ /mp4$/i;

	next if $name =~ /[0-9]m.jpg/i;

	$name =~ s/.*Photos/Photos/;
	$fh{$hash} = $name unless defined $fh{$hash};
}

foreach my $k (keys %fh){
	my $photo = my $new = $fh{$k};
	$new =~ s/[()& ,?!-]+/_/g;
	$new =~ s/.*Photos/$targetdir/;
	my $nd = $new;
	$nd =~ s|[^/]*$||;
	unless (defined $dh{$nd}){
		make_path($nd);
	} else {$dh{$nd} = 1};
	say "## $nd";
	say("cd $nd && /bin/ln -fs uu") or die "you suck";
	## say $cwd.$photo . " " . $cwd.$new;
}
