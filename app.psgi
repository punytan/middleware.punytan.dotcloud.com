use strict;
use warnings;

package App::ListMiddleware::Favicon;
use parent 'Lanky::Handler';
sub get { shift->redirect('http://search.cpan.org/favicon.ico'); }

package App::ListMiddleware::Pod;
use parent 'Lanky::Handler';
use JSON;
use LWP::UserAgent;
sub get {
    my ($c, $module) = @_;
    my $data = JSON::decode_json(LWP::UserAgent->new->get("http://api.metacpan.org/pod/$module")->content);
    $c->write_json($data);
}

package main;
use Lanky;
use Plack::Builder;
use FindBin;
use File::Spec;
use lib "$FindBin::Bin/lib";

my $app = Lanky->new->application(
    '/' => 'App::ListMiddleware',
    '/pod/(Plack::[\w|:]+)' => 'App::ListMiddleware::Pod',
    '/favicon\.ico' => 'App::ListMiddleware::Favicon',
)->template(
    path  => ["$FindBin::Bin/template"],
    cache => 1,
    syntax    => 'Metakolon',
    cache_dir => File::Spec->tmpdir,
)->master_connect(
    'dbi:SQLite:dbname=:memory:', '', ''
)->errordoc("$FindBin::Bin/errordoc")->to_app;

builder {
    $app;
};

