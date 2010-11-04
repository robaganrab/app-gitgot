package App::GitGot::Command::status;
use Moose;
extends 'App::GitGot::BaseCommand';

use 5.010;

use Capture::Tiny qw/ capture /;

sub command_names { qw/ status st / }

sub execute {
  my ( $self, $opt, $args ) = @_;

  $self->args( $args );         ### FIXME this is stupid

 REPO: for my $repo ( $self->active_repos ) {
    my $msg = sprintf "%3d) %-25s : ", $repo->number, $repo->name;

    unless ( -d $repo->path ) {
      my $name = $repo->name;
      say "${msg}ERROR: repo '$name' does not exist"
        unless $self->quiet;
      next REPO;
    }

    my ( $status, $fxn );

    given ( $repo->type ) {
      when ('git') { $fxn = 'git_status' }
      ### FIXME      when( 'svn' ) { $fxn = 'svn_status' }
      default { $status = "ERROR: repo type '$_' not supported" }
    }

    $status = $self->$fxn($repo) if ($fxn);

    next REPO if $self->quiet and !$status;

    say "$msg$status";
  }
}

sub git_status {
  my ( $self, $entry ) = @_
    or die "Need entry";

  my $path = $entry->{path};

  my $msg = '';

  if ( -d "$path/.git" ) {
    my ( $o, $e ) = capture { system("cd $path && git status") };

    if ( $o =~ /^nothing to commit/m and !$e ) {
      if ( $o =~ /Your branch is ahead .*? by (\d+) / ) {
        $msg .= "Ahead by $1";
      }
      else { $msg .= 'OK' unless $self->quiet }
    }
    elsif ($e) { $msg .= 'ERROR' }
    else       { $msg .= 'Dirty' }

    return ( $self->verbose ) ? "$msg\n$o$e" : $msg;
  }
}

1;

__END__

=head1 NAME

App::GitGot::Command::status - print status info about repos
