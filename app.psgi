use strict;
use warnings;

package App::ListMiddleware::Favicon;
use parent 'Lanky::Handler';
sub get {
    shift->redirect('http://search.cpan.org/favicon.ico');
}

package App::ListMiddleware::Pod;
use parent 'Lanky::Handler';
use LWP::UserAgent;

sub get {
    my ($c, $module) = @_;
    my $url  = "http://api.metacpan.org/pod/$module?content-type=text/plain";
    my $data = LWP::UserAgent->new->get($url)->content;
    $c->write($data);
}

package main;
use Lanky;
use Plack::Builder;
use FindBin;
use File::Spec;
use lib "$FindBin::Bin/lib";

my $app = Lanky->new->application(
    '/' => 'App::ListMiddleware',
    '/pod/(Plack::[\w|:]+)'
        => 'App::ListMiddleware::Pod',
    '/favicon\.ico'
        => 'App::ListMiddleware::Favicon',
)->template(
    path  => ["$FindBin::Bin/template"],
    cache => 1,
    syntax    => 'Metakolon',
    cache_dir => File::Spec->tmpdir,
)->dbi_connect(
    'dbi:SQLite:dbname=:memory:', '', ''
)->errordoc("$FindBin::Bin/errordoc")->to_app;

builder {
    $app;
};

