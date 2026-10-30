#!/usr/bin/perl
# Turns the canvas .dc.html pages into static pages for GitHub Pages.
# Usage: perl build-site.pl <canvas project dir> <asset dir> <repo dir>
use strict;
use warnings;
use File::Copy;

my ($src, $assets, $repo) = @ARGV;
my %pages = (
  'Beri-Premium' => 'index.html', 'Cliq' => 'cliq.html', 'Crush' => 'crush.html',
  'Cirql' => 'cirql.html', 'Authenticate' => 'authenticate.html', 'Wholesale' => 'wholesale.html',
);

# id -> file name with extension, from the downloaded assets
my %blob;
opendir(my $dh, $assets) or die "no asset dir";
for my $f (readdir $dh) { $blob{$1} = $f if $f =~ /^([0-9a-f]{32})\.\w+$/; }
closedir $dh;
mkdir "$repo/assets/blob";

my %used;
for my $name (sort keys %pages) {
  open(my $in, '<:raw', "$src/$name.dc.html") or die "missing $name";
  local $/; my $html = <$in>; close $in;

  my ($helmet) = $html =~ m{<helmet>(.*?)</helmet>}s or die "no helmet in $name";
  my ($dc) = $html =~ m{<x-dc>(.*?)</x-dc>}s or die "no x-dc in $name";
  $dc =~ s{<helmet>.*?</helmet>}{}s;

  my $head = qq{<meta name="viewport" content="width=device-width, initial-scale=1">\n} . $helmet;
  $html =~ s{<script src="\./support\.js"></script>}{$head} or die "no support.js line in $name";
  $html =~ s{<x-dc>.*?</x-dc>}{<div id="dc-root"></div>\n<template id="dc-template">$dc</template>}s;
  $html =~ s{</body>}{<script src="assets/js/beri-runtime.js"></script>\n</body>};

  $html =~ s{/_blob/([0-9a-f]{32})}{
    my $id = $1; die "asset $id not downloaded" unless $blob{$id};
    $used{$id} = 1; "assets/blob/$blob{$id}"
  }ge;

  open(my $out, '>:raw', "$repo/$pages{$name}") or die;
  print $out $html; close $out;
  print "$name -> $pages{$name}\n";
}
for my $id (keys %used) { next if -e "$repo/assets/blob/$blob{$id}"; copy("$assets/$blob{$id}", "$repo/assets/blob/$blob{$id}") or die "copy $id"; }
print scalar(keys %used), " assets copied\n";
