##- Nanar <nanardon@mandriva.org>
##- (c) 2005 Olivier Thauvin
##- (c) 2005 Mandriva Linux
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# $Id: Checks.pm 57001 2006-08-21 14:34:00Z nanardon $

package MDV::Distribconf::Checks;

=head1 NAME

MDV::Distribconf::Checks - A Subclass to MDV::Distribconf::Build to check
distribution tree

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
# use Module::Pluggable;
use MDV::Distribconf::MediaCFG;
use MDV::Distribconf::Build;
use MDV::Packdrakeng;
use Digest::MD5;

sub new {
    bless({}, $_[0]);
}

sub _report_err {
    my ($out, $err_code, $fmt, @args) = @_;
    my %errs = (
        'UNSYNC_HDLIST' => 'E',
        'UNSYNC_MD5' => 'E',
        'WRONG_CONFIG' => 'W',
        'MISSING_MEDIA' => 'W',
        'MISSING_MEDIADIR' => 'E',
        'SAME_INDEX' => 'E',
        'NOMEDIA' => 'E',
        'MISSING_INDEX' => 'E',
        'MISSING_INFO' => 'W',
    );
    my $message = sprintf($fmt, @args);

    if (ref $out eq 'CODE') {
        $out->(
            errcode => $err_code || '?',
            level => $errs{$err_code} || '?',
            message => $message,
        );
    } else {
        printf $out "%s: %s\n", $errs{$err_code} || '?', $message;
    }
    return($errs{$err_code} || '?' eq 'E' ? 1 : 0)
}

=item $distrib->check_config

=cut

sub check_config {
    my ($self, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = 0;

    foreach my $var ($self->{cfg}->Parameters('media_info')) {
        $self->{cfg}->val('media_info', $var) or next;
        my @er = MDV::Distribconf::MediaCFG::_valid_param(
            'media_info',
            $var,
            $self->{cfg}->val('media_info', $var),
        );
        foreach (@er) {
            $error += _report_err(
                $fhout,
                'WRONG_CONFIG',
                "%s %s: %s", 'media_info', $var, $_
            );
        }
    }
    foreach my $media ($self->listmedia()) {
        foreach my $var ($self->{cfg}->Parameters($media)) {
            $self->{cfg}->val($media, $var) or next;
            my @er = MDV::Distribconf::MediaCFG::_valid_param(
                'media_info',
                $var,
                $self->{cfg}->val($media, $var),
            );
            foreach (@er) {
                $error += _report_err(
                    $fhout,
                    'WRONG_CONFIG',
                    "%s %s: %s", $media, $var, $_
                );
            }
        }

        # checking inter media reference
        my %cross_value = (
            srpms => 'rpms',
            rpms => 'srpms',
        );
        foreach my $linkmedia (qw(srpms rpms debug_for)) {
            foreach my $sndmedia (split(/ /, $self->getvalue($media, $linkmedia, ''))) {
                if (!$self->mediaexists($sndmedia)) {
                    $error += _report_err(
                        $fhout,
                        'MISSING_MEDIA',
                         "`%s' refer as %s to non existant `%s'",
                        $media,
                        $linkmedia,
                        $sndmedia,
                    );
                } elsif($cross_value{$linkmedia}) {
                    if(!grep { $media eq $_ } 
                        split(/ /, 
                            $self->getvalue($sndmedia, $cross_value{$linkmedia})
                        )) {
                        $error += _report_err(
                            $fhout,
                            'WRONG_CONFIG',
                            "`%s' has not `%s' as %s",
                            $sndmedia, $media, $cross_value{$linkmedia},
                        );
                    }
                }
            }
        }
    }
    {
        my %foundname;
        push(@{$foundname{$self->getvalue($_, 'name')}}, $_) 
            foreach($self->listmedia());

        foreach (keys %foundname) {
            if (@{$foundname{$_}} > 1) {
                $error += _report_err(
                    $fhout,
                    'WRONG_CONFIG',
                    "`%s' have same name (%s)",
                    join(', ', @{$foundname{$_}}),
                    $_,
                );
            }
        }
    }

    $error
}
=item $distrib->check_media_coherency($fhout)

Performs basic checks on the distribution and prints to $fhout (STDERR by
default) warnings and errors found. Returns the number of errors reported.

=cut

sub check_media_coherency {
    my ($distrib, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = 0;

    $distrib->listmedia or $error += _report_err(
        'NOMEDIA', "No media found in this config"
    );

    # Checking no overlap
    foreach my $var (qw/hdlist synthesis path/) {
        my %e;
        foreach ($distrib->listmedia) {
            my $v = $distrib->getpath($_, $var);
            push @{$e{$v}}, $_;
        }

        foreach my $key (keys %e) {
            if (@{$e{$key}} > 1) {
                $error += _report_err(
                    $fhout,
                    'SAME_INDEX', 
                    "media `%s' have same %s (%s)",
                    join (", ", @{$e{$key}}),
                    $var,
                    $key
                );
            }
        }
    }

    foreach my $media ($distrib->listmedia) {
	-d $distrib->getfullpath($media, 'path') or $error += _report_err(
	    $fhout,
		'MISSING_MEDIADIR', "dir %s does't exist for media `%s'",
	    $distrib->getpath($media, 'path'),
	    $media
	);
	foreach (qw/hdlist synthesis/) {
	    -f $distrib->getfullpath($media, $_) or $error += _report_err(
        $fhout,
		'MISSING_INDEX', "$_ %s doesn't exist for media `%s'",
		$distrib->getpath($media, $_),
		$media
	    );
	}
    foreach (qw/pubkey/) {
	    -f $distrib->getfullpath($media, $_) or $error += _report_err(
        $fhout,
		'MISSING_INFO', "$_ %s doesn't exist for media `%s'",
		$distrib->getpath($media, $_),
		$media
	    );
	}

    }
    return $error;
}

=item $distrib->check_index_sync($media)

Check the synchronisation between rpms contained by media $media
and its hdlist:

  - all rpms should be in the hdlist
  - the hdlist should not contains rpms that does not exists

Return 1 if no problem were found

=cut

sub check_index_sync {
    my ($self, $media) = @_;
    my $hdlist = $self->getfullpath($media, 'hdlist');
    my $rpmspath = $self->getfullpath($media, 'path');
    my @rpms = sort map { m:.*/+(.*): ; $1 } glob("$rpmspath/*.rpm");
    -f $hdlist or return 0; # avoid warnings
    if (my $pack = MDV::Packdrakeng->open(archive => $hdlist)) {
        my (undef, $files, undef) = $pack->getcontent();
        my @hdrs = sort @{$files || []};
        while (@rpms || @hdrs) {
            my $r = shift(@rpms) || "";
            my $h = shift(@hdrs) || "";
            if ($r ne "$h.rpm") {
                return 0;
            }
        }
    } else {
        return 0;
    }
    return 1;
}

=item $distrib->check_media_md5($media)

Check md5sum for hdlist and synthesis for the media $media are the same
than value contains in the existing MD5SUM file.

The function return an error also if the value is missing

Return 1 if no error were found.

=cut

sub check_media_md5 {
    my ($self, $media) = @_;
    my $md5file = $self->getfullpath($media, 'path') . "/media_info/MD5SUM";
    my %md5;
    open(my $hmd5, "< $md5file") or return 0;
    while (<$hmd5>) {
        chomp;
        s/#.*//;
        /^(.{32})  (.*)/ or next;
        $md5{$2} = $1;
    }
    close($hmd5);
    foreach my $file (qw(hdlist.cz synthesis.hdlist.cz)) {
        my $filelocation = $self->getfullpath($media, 'path') . "/media_info/$file";
        open(my $hfile, "< $filelocation") or return 0;
        my $ctx = Digest::MD5->new;
        $ctx->addfile($hfile);
        close($hfile);
        
        my ($basename) = $filelocation =~ m:.*/+([^/]*)$:; #: vi syntax coloring
        if (($md5{$basename} || "") ne $ctx->hexdigest) {
            return 0;
        }
    }
    return 1;
}

=item $distrib->checkdistrib($fhout)

Performs all light checks on the distribution and prints to $fhout (STDERR by
default) warnings and errors found. Returns the number of errors reported.

=cut

sub checkdistrib {
    my ($self, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = 0;

    $error += $self->check_config($fhout);
    $error += $self->check_media_coherency($fhout);

    foreach my $media ($self->listmedia) {
        if(!$self->check_index_sync($media)) {
            $error += _report_err(
                $fhout,
                'UNSYNC_HDLIST',
                "hdlist for media `%s' is not sync with its rpms",
                $media,
            );
        }

        if(!$self->check_media_md5($media)) {
            $error += _report_err(
                $fhout,
                'UNSYNC_MD5',
                "md5sum for media `%s' is not ok",
                $media,
            );
        }
    }
    
    $error
}

=item $distrib->check($fhout)

=cut

sub check {
    my ($self, $fhout) = @_;
    $fhout ||= \*STDERR;

    my $error = $self->check_config($fhout);
    $error += $self->check_media_coherency($fhout);

    $error
}

1;

__END__

=back

=head1 AUTHOR

Olivier Thauvin <nanardon@mandriva.org>

=head1 SEE ALSO

L<MDV::Distribconf>

=cut
