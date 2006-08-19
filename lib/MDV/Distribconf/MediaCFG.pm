package MDV::Distribconf::MediaCFG;

use strict;
use warnings;

our $VERSION = (qq$Revision: 56853 $ =~ /(\d+)/)[0];

=head1 NAME

MDV::Distribconf::MediaCFG

=head1 DESCRIPTION

This module provide documenation of know value in media.cfg

=head1 VALUE

=cut

my $value = {};

=head2 GLOBAL VALUES

This value can only be set into 'media_info' section.

=cut

$value->{mediacfg_version} = { 
    validation => sub {
        my ($val) = @_;
        if ($val !~ /^(\d|.)+$/) {
            return ("should be a number");
        }
        return ();
    },
};

=head3 mediacfg_version

The version of the media_cfg

See L<MDV::Distribconf> for more detail about it

=cut

$value->{version} = { section => 'media_info' };

=head3 version

The version of distrib

=cut

$value->{arch} = { section => 'media_info' };

=head3 arch

The arcitecture of the distribution

=cut

$value->{branch} = { section => 'media_info' };

=head3 branch

The branch of the distribution.

=cut

=head2 MEDIA VALUES

=cut

foreach (qw(hdlist name synthesis pubkey)) {
    $value->{$_} = { };
}

=head3 name

The name of the media. If unset, the section is the name.

=head3 hdlist

The hdlist file holding rpm infos for the media

=head3 synthesis

The synthesis file holding rpm infos for the media

=head3 pubkey

The file holding public gpg key used to sign rpms in this media.

=cut

$value->{srpms} = { deny => 'rpms' };

=head3 srpms

If the media hold binaries rpms, this parameter contains
the list of medias holding corresponding sources rpms.

=cut

$value->{rpms} = { deny => 'srpms' };

=head3 rpms

If the media hold sources rpms, this parameter contains
the list of media holding binaries rpms build by srpms from this media.

=cut

$value->{debug_for} = {};

=head3 debugfor

If the media contain debug rpms, it contain the list of media for which
rpms are debug rpms.

=cut

$value->{noauto} = {};

=head3 noauto

This value is used by tools to assume if the media should automatically
added to the config (urpmi).

=cut

$value->{size} = {
    validation => sub {
        my ($v) = @_;
        if ($v =~ /^(\d+)(\w)?$/) {
            if ($2) {
                if (! grep { lc($2) eq $_ } qw(k m g t p)) {
                    return("wrong unit");
                }
            }
            return;
        } else {
            return ("malformed value");
        }
    },
};

=head3 size

The size of the media. The value is suffixed by the unit.

=cut

# valid_param($media, $var, $val)
#
# Return a list of errors (if any) about having such value in the config

sub _valid_param {
    my ($media, $var, $val) = @_[-3..-1];
    if (!exists($value->{$var})) {
        return ("unknow var");
    }
    $media ||= 'media_info'; # assume default
    my @errors;
    if ($value->{$var}{section} && $value->{$var}{section} ne $media) {
        push(@errors, "wrong section: should be in $value->{$var}{section}");
    }
    if ($value->{$var}{validation}) {
        push(@errors, $value->{$var}{validation}->($val));
    }
    return @errors;
}

# Retun a hash containing information about $var

sub _value_info {
    my ($var) = $_[-1];
    if (exists($value->{$var})) {
        return $value->{$var}
    }
    return;
}

1;
