#!/usr/bin/perl -w
use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
use Data::Dumper;

$VERSION = "1.0";
%IRSSI = ( 
        authors => 'Mike Jones',
        contact => 'mike@snoonet.org',
        name => 'Pizza Counter',
        description => '#metal pizza counter incrementer',
        license => 'MIT',
        url => 'https://github.com/n7st/irssi-scripts',
);

my @admins = ( 
        'Mike@snoonet/admin/Netsplit',
        'qdwach@user/Qdwach',
        'brutal_n00d@user/BrutalN00dle'
);

my $running = 0;

sub check_channel ($$) {
        my ($channel, $target_channel) = @_; 

        if ($channel->{name} eq $target_channel) {
                return $channel->{topic};
        }   

        return 0;
}

sub set_new_topic ($$$) {
        my ($channel, $topic, $server) = @_; 
        my ($count) = $topic =~ /:\ (\d+)/;
        my $new_count = $count + 1;
        $topic =~ s/$count/$new_count/;

        $server->command("topic $channel $topic");
}

sub handle_cmd ($$$$$) {
        my ($server, $msg, $nick, $address, $target) = @_; 
        my $current_topic;

        if ($msg ne "pizza++" || $running == 1) {
                return 0;
        }   

        $running = 1;

        if ($address ~~ @admins) {
                foreach (Irssi::channels()) {
                        if ($current_topic = check_channel($_, $target)) {
                            last;
                        }   
                }   
        }   

        if ($current_topic) {
                set_new_topic($target, $current_topic, $server);
        }   

        $running = 0;
}

Irssi::signal_add('message public', 'handle_cmd');

