#!/usr/bin/env perl
# Filter for the fzf Ctrl-R widget (key-bindings.zsh): drops duplicate
# commands from `fc -rl 1` output and colors each line on its own, in the
# catppuccin macchiato palette. Coloring per line means an unclosed quote
# can't bleed into the next entry. fzf runs with --ansi, so what it hands
# back is the plain line again.
use strict;
use warnings;

my $reset = "\e[0m";
sub rgb { "\e[38;2;$_[0]m" }
my $num_c  = rgb('110;115;141'); # overlay0: history number
my $cmd_c  = rgb('138;173;244'); # blue: command words
my $flag_c = rgb('238;153;160'); # maroon: -f / --flags
my $str_c  = rgb('166;218;149'); # green: 'strings' and "strings"
my $op_c   = rgb('139;213;202'); # teal: | || && ; &
my $var_c  = rgb('238;212;159'); # yellow: $vars

my %seen;
while (my $line = <STDIN>) {
  chomp $line;
  my ($num, $cmd) = $line =~ /^(\s*[0-9]+\**\s+)(.*)/;
  if (!defined $cmd) { print "$line\n"; next }
  next if $seen{$cmd}++;

  my $out = '';
  my $at_cmd = 1; # next word is in command position
  while ($cmd =~ /\G(\s+|'[^']*'?|"(?:\\.|[^"\\])*"?|\|\||&&|[|;&]|\$\{?\w+\}?|[^\s'"|;&\$]+|.)/gc) {
    my $t = $1;
    if ($t =~ /^\s/) { $out .= $t; next }
    if ($t =~ /^(?:\|\||&&|[|;&])$/) { $out .= "$op_c$t$reset"; $at_cmd = 1; next }
    if    ($t =~ /^['"]/) { $out .= "$str_c$t$reset" }
    elsif ($t =~ /^\$/)   { $out .= "$var_c$t$reset" }
    elsif ($at_cmd)       { $out .= "$cmd_c$t$reset" }
    elsif ($t =~ /^-/)    { $out .= "$flag_c$t$reset" }
    else                  { $out .= $t }
    $at_cmd = 0;
  }
  print "$num_c$num$reset$out\n";
}
