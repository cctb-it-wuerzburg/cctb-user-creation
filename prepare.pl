#!/usr/bin/env perl
use strict;
use warnings;

#use utf8;

my %translate_table = (
    "Ä" => 'Ae',
    "ä" => 'ae',
    "Ö" => 'Oe',
    "ö" => 'oe',
    "Ü" => 'Ue',
    "ü" => 'ue',
    "ß" => 'ss'
    );

my $template_file = "template_account.tex";
my $account_out = "accounts.adr";
my $account_for = "Master Vorlesung Bioinformatik";
my $skel = "--skel /etc/skel";

my $template = "";
open(FH, "<", $template_file) || die "Unable to open template file '$template_file' which might be specified via --template option : $!";
while (<FH>)
{
    $template .= $_;
}
close(FH) || die "Unable to close template file '$template_file': $!";

open(FH, ">", $account_out) || die "Unable to open account output file '$account_out' which might be specified via --accounts option : $!";

while (<>)
{
    chomp;

    my ($vor, $nach, $email, $geschlecht, $group) = split(/\t/, $_);

    my ($anrede, $endung) = ("Frau/Herr", "");
    if ($geschlecht =~ /[FW]/i)
    {
	$anrede = "Frau";
	$endung = "";
    } elsif ($geschlecht =~ /[HM]/i)
    {
	$anrede = "Herr";
	$endung = "r";
    }

    my $additional_groups = "";
    if ($group)
    {
	$additional_groups="--groups epoptes,student";
    } else {
	$group = "student";
    }
    
    # lowercase email
    $email = lc($email);

    # substitute umlaute
    if ($nach =~ /([ÄäÖöÜüß])/)
    {
	print STDERR "Need to substitute: $1\n";
	$nach =~ s/([ÄäÖöÜüß])/$translate_table{"$1"}/g;
    }
    if ($vor =~ /([ÄäÖöÜüß])/)
    {
	print STDERR "Need to substitute: $1\n";
	$vor =~ s/([ÄäÖöÜüß])/$translate_table{"$1"}/g;
    }

    my $username=substr($vor, 0, 3).substr($nach, 0, 3);
    $username=lc($username);

    # get a password
    my $passwd = qx(pwgen -N 1 10);
    chomp($passwd);
    # hash it
    my $passwd_sha512 = qx(echo "$passwd" | mkpasswd -m sha-512 --stdin);
    chomp($passwd_sha512);

    printf 'useradd --create-home %s --password \'%s\' --shell /bin/bash --gid %s %s --comment "%s %s,%s,,," %s'."\n", $skel, $passwd_sha512, $group, $additional_groups, $vor, $nach, $email, $username;

    if ($email =~ /_/)
    {
       $email =~ s/_/\\_/g;
    }	

    printf FH '\adrentry{%s}{%s}{%s}{%s}{%s}{%s}{%s}{%s}', $nach, $vor, $email, $anrede, $endung, $username, $passwd, $account_for;
}

close(FH) || die "Unable to close account output file '$account_out': $!";

print "Run latex \n";
