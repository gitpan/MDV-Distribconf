package MDV::Distribconf::Build;

=head1 NAME

MDV::Distribconf::Build - Subclass to MDV::Distribconf to build configuration

=head1 METHODS

=over 4

=cut

use strict;
use warnings;
use MDV::Distribconf;

use base qw(MDV::Distribconf MDV::Distribconf::Checks);
our $VERSION = (qq$Revision: 57920 $ =~ /(\d+)/)[0];

=item MDV::Distribconf::Build->new($root_of_distrib)

Returns a new MDV::Distribconf::Build object.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
}

=item $distrib->setvalue($media, $var, $val)

Sets or adds $var parameter from $media to $val. If $media doesn't exist,
it is implicitly created. If $var is C<undef>, a new media is created with
no defined parameters.

=cut

sub setvalue {
    my ($distrib, $media, $var, $val) = @_;
    $media ||= 'media_info';
    if ($var) {
        $var =~ /^(?:media|info)dir\z/ and do {
            $distrib->{$var} = $val;
            return;
        };
        $distrib->{cfg}->newval($media, $var, $val)
	    or warn "Can't set value [$var=$val] for $media\n";
    } else {
        $distrib->{cfg}->AddSection($media);
    }
}

=item $distrib->delvalue($media, $var)

Delete $var parameter from $media. If $var is not specified, the media is
is deleted. If $media is not specified, $var is remove from global settings.

=cut

sub delvalue {
    my ($distrib, $media, $var) = @_;
    if ($var) {
        $distrib->{cfg}->delval($media, $var);
    } else {
        $distrib->{cfg}->DeleteSection($media);
    }
}

=item $distrib->write_hdlists($hdlists)

Writes the F<hdlists> file to C<$hdlists>, or if no parameter is given, in
the media information directory. C<$hdlists> can be a file path or a file
handle. Returns 1 on success, 0 on error.

=cut

sub write_hdlists {
    my ($distrib, $hdlists) = @_;
    my $h_hdlists;
    if (ref $hdlists eq 'GLOB') {
        $h_hdlists = $hdlists;
    } else {
        $hdlists ||= "$distrib->{root}/$distrib->{infodir}/hdlists";
        open $h_hdlists, ">", $hdlists
	    or return 0;
    }
    foreach my $media ($distrib->listmedia) {
        printf($h_hdlists "%s%s\t%s\t%s\t%s\n",
            join('', map { "$_:" } grep { $distrib->getvalue($media, $_) } qw/askmedia suppl noauto/) || "",
            $distrib->getvalue($media, 'hdlist'),
            $distrib->getpath($media, 'path'),
            $distrib->getvalue($media, 'name'),
            $distrib->getvalue($media, 'size') ? '('.$distrib->getvalue($media, 'size'). ')' : "",
        ) or return 0;
    }
    return 1;
}

=item $distrib->write_mediacfg($mediacfg)

Write the media.cfg file into the media information directory, or into the
$mediacfg given as argument. $mediacfg can be a file path, or a glob reference
(\*STDOUT for example).

Returns 1 on success, 0 on error.

=cut

sub write_mediacfg {
    my ($distrib, $hdlistscfg) = @_;
    $hdlistscfg ||= "$distrib->{root}/$distrib->{infodir}/media.cfg";
    $distrib->{cfg}->WriteConfig($hdlistscfg);
}

=item $distrib->write_version($version)

Write the VERSION file. Returns 0 on error, 1 on success.

=cut

sub write_version {
    my ($distrib, $version) = @_;
    my $h_version;
    if (ref($version) eq 'GLOB') {
        $h_version = $version;
    } else {
        $version ||= $distrib->getfullpath(undef, 'VERSION');
        open($h_version, ">", $version) or return 0;
    }

    my @gmt = gmtime(time);

    printf($h_version "Mandriva Linux %s %s-%s-%s%s %s\n",
        $distrib->getvalue(undef, 'version') || 'cooker',
        $distrib->getvalue(undef, 'branch') || 'cooker',
        $distrib->getvalue(undef, 'arch') || 'noarch',
        $distrib->getvalue(undef, 'product'),
        $distrib->getvalue(undef, 'tag') ? '-' . $distrib->getvalue(undef, 'tag') : '',
        sprintf("%04d%02d%02d %02d:%02d", $gmt[5] + 1900, $gmt[4]+1, $gmt[3], $gmt[2], $gmt[1])
    );

    if (ref($version) ne 'GLOB') {
        close($h_version);
    }
    return 1;
}


1;

__END__

=back

=head1 SEE ALSO

L<MDV::Distribconf>

=cut
