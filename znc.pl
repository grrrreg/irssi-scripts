#!/usr/bin/perl -w

#
# Please note: this is a proof of concept and should not be used for any purpose
# without first being completed! Submit a pull request if you want to add
# functionality.
#

use strict;
use Irssi;
use Data::Dumper;
use vars qw($VERSION %IRSSI);

$VERSION = "1.0";
%IRSSI = (
	authors => 'Mike Jones',
	contact => 'mike@netsplit.org.uk',
	name => 'BNCManager',
	description => 'ZNC Management Script',
	license => 'MIT',
	url => 'https://github.com/n7st/irssi-scripts',
);

# Users who may tamper with stuff - should be built into a config file
my @admins = (
	'znc@znc.in',
	'Mike@snoonet/admin/Netsplit'
);

# Matched commands to subroutines
my %actions = (
	"check" => \&find_user,
	"deluser" => \&del_user,
	"adduser" => \&add_user
);

# Users who may not be deleted - should be built into a config file
my @safe_users = ("Mike", "Manager");

# Channel to output to - should be built into a config file
my $operations_channel = '##mike-test';

# Collect public message input
sub handle_cmd {
	my ($server, $msg, $nick, $address, $target) = @_;

	# Commands must start with !, user must be administrator
	if ($msg !~ /^?!/ || !$address ~~ @admins) {
		return 0;
	}

	my @args = split(/\s+/, $msg);
	my $cmd = @args[0];
	shift @args;
	my $arg_string = join(" ", @args);

	$cmd =~ s/^.//s;
	if (exists $actions{$cmd}) {
		$actions{$cmd}->($server, $msg, $nick, $address, $target, $arg_string);
	} else {
		$server->command("msg $target No such command \"$cmd\"");
	}
}

# Collect PM input
sub handle_response {
	my ($server, $msg, $nick, $address, $target) = @_;

	if ($msg =~ /Error: User \[/) {
		my ($user) = $msg =~ /\[(.*)\]/;
		$server->command("msg $operations_channel $user not found.");
	}

	if ($msg =~ /Nick \=/) {
		my ($user) = $msg =~ m/=\ (\w+)/;
		$server->command(
			"msg $operations_channel $user found on $server->{'address'}:$server->{'port'}.");
		#$server->command("msg *status");
	}
}

# Collect notice input
sub handle_notice {
	my ($server, $msg, $nick, $address) = @_;
	# Borrowed from UNIBG-autoident
	my ($target, $text) = $msg =~ /^(\S*)\s:(.*)/;

	if (!$address ~~ @admins) {
		return 0;
	}

	if ($text =~ /.attached./) {
		$text =~ s/^....//s;
		$server->command("msg $operations_channel $text");
	}

	if ($text =~ /.detached./) {
		$text =~ s/^....//s;
		$server->command("msg $operations_channel $text");
	}
}

# Check if a user exists
sub find_user {
	my ($server, $msg, $nick, $address, $target, $arg) = @_;
	$server->command("msg *controlpanel get nick $arg");
}

# Add a ZNC user
sub add_user {
	my ($server, $msg, $nick, $address, $target, $arg) = @_;
	my @chars = ("A".."Z", "a".."z", "0".."9", "!", "@");
	my $password;
	$password .= $chars[rand @chars] for 1..8;

	$server->command("msg *controlpanel adduser $arg $password");
	$server->command("msg $operations_channel Added user $arg:$password");
}

# Remove a ZNC user
sub del_user {
	my ($server, $msg, $nick, $address, $target, $arg) = @_;

	if ($arg ~~ @safe_users) {
		return 0
	}

	$server->command("msg *controlpanel deluser $arg");
	$server->command("msg $operations_channel Deleted user $arg");
}

Irssi::signal_add('message public', 'handle_cmd');
Irssi::signal_add('message private', 'handle_response');
Irssi::signal_add('event notice', 'handle_notice');

