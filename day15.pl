#!/usr/bin/perl

use strict;
use Perl6::Slurp;

my $dataset = slurp "dataset.txt";

my @rows = split( /\n/, $dataset );
my $grid;
my $x=0;
foreach my $r (@rows){
        my @cols = split(//, $r);
        my $y=0;
        foreach my $c (@cols){
                $grid->[$x]->[$y] = $c;
                $y++;
        }
        $x++;
}

use Data::Dumper;

# can i find the correct path first time, or do
# i try all possible paths

my $optimalpath; # if any path beats this score, it becomes new optimum
   $optimalpath->{score} = 1121;
   $optimalpath->{steps} = ['+x', '+y', '+x', '+y'];

my $pathhistory; # i never want to walk the same exact path
my $maxsteps = 250;     # going always down and right, shortest path is 200 steps 
                        # we can play with this variable to explore more options

use JSON;
use Digest::xxHash qw[xxhash64_hex]; # an extremely fast hashing algorithm
my $json = JSON->new->allow_nonref;
   $json->canonical(1);

my $tries = 100000; # sanity check
my $endx = scalar @{$grid};
my $endy = scalar @{$grid->[0]};
my $startx = 0;
my $starty = 0;

NEXTTRY:
while ( $tries > 0 ){
        $tries--;
               my @steps; # were to record the path i am walking
        my $stepcnt;
        my $score;
        my @path;
        my $posx = 0;
        my $posy = 0;
        foreach (1...1000){
                if($stepcnt > $maxsteps){ next NEXTTRY; }
                # I want to bias down and right
                my @nextsteps = ('+x', '+y', '+x', '+y', '+x', '+y', '+x', '+y');
                # 100000 runs found NOTHING better than a 'direct' down and right path, removing
                # -x and -y from the mix
                my $nextstep = $nextsteps[ rand @nextsteps ];
                my $prevstep = $path[-1] eq '-x' ? '+x' :
                               $path[-1] eq '-y' ? '+y' :
                               $path[-1] eq '+x' ? '-x' :
                               $path[-1] eq '+y' ? '-y' :
                               '';
                if($posx == 100){ $nextstep = '+y'; $prevstep='+x';}
                if($posy == 100){ $nextstep = '+x'; $prevstep='+y';}

                if($nextstep eq $prevstep){
                        #print "$nextstep $path[-1] nob\n"; 
                        next; } # don't go back!
                my $newx = $nextstep eq '+x' ? ($posx + 1) :
                           $nextstep eq '-x' ? ($posx - 1) :
                           $posx;
                my $newy = $nextstep eq '+y' ? ($posy + 1) :
                           $nextstep eq '-y' ? ($posy - 1) :
                           $posy;

                if($newx > 100){ $newx=100; }
                if($newy > 100){ $newy=100; }
                # a valid step
                $posx = $newx;
                $posy = $newy;

                if($posx == 100 && $posy == 100){
                        my $stringed = $json->encode(\@steps);
                        my $hex_64  = xxhash64_hex( $stringed, '1234' );
                        if($pathhistory->{$hex_64} eq 1){ next NEXTTRY; } # already found this one
                        $pathhistory->{$hex_64}=1;
                        if($score < $optimalpath->{score}){ # we have a new winner!
                                $optimalpath->{score} = $score;
                                $optimalpath->{steps} = \@steps;
                                print "\n";
                                next NEXTTRY;
                        }
                        print "\n";
                        next NEXTTRY;
                }

     $stepcnt++;
                push(@steps, qq($newx,$newy));
                if($stepcnt > $maxsteps){ print " final position $posx,$posy score is $score too many steps\n"; next NEXTTRY; }

                $score = $score + $grid->[$posx - 1]->[$posy - 1];
                print "."; #Current pos $posx,$posy value $grid->[$posx - 1]->[$posy - 1] score = $score\n";
                push(@path, $nextstep);

                }
        print "tries $tries\n";
}
print Dumper($optimalpath);
exit;
