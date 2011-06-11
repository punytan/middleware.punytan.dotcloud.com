package App::ListMiddleware;
use strict;
use warnings;
our $VERSION = '0.04';
use parent 'Lanky::Handler';

use JSON;
use Web::Scraper;
use LWP::UserAgent;

sub get {
    my $c = shift;

    $c->dbh->do("CREATE TABLE IF NOT EXISTS data (json_text TEXT, ts INT)");

    my $sth = $c->dbh->prepare("SELECT * FROM data ORDER BY ts DESC");
    $sth->execute;
    my $rv = $sth->fetchrow_hashref;

    my $json_text;
    if ($rv && time - $rv->{ts} < 60 * 60) { # use cached data if it doesn't elapse more than an hour
        print "From cache\n";
        $json_text = $rv->{json_text};
    } else {
        print "Fresh Data\n";
        $c->update;

        my $sth = $c->dbh->prepare("SELECT * FROM data ORDER BY ts DESC");
        $sth->execute;
        my $rv = $sth->fetchrow_hashref;

        $json_text = $rv->{json_text};
    }

    my $result = JSON::decode_json $json_text;
    my $body = $c->render("index.html", {result => $result});
    $c->write($body);
}

sub update {
    my $c = shift;

    my $rv  = $c->scrape;
    my $sth = $c->dbh->prepare("INSERT INTO data (json_text, ts) values (?, ?)");
    $sth->execute(JSON::encode_json($rv), time);
}

sub scrape {
    my $c = shift;

    my $m = scraper { process 'body > .sr',   'module[]' => 'TEXT'; };
    my $d = scraper { process 'body > small', 'desc[]'   => 'TEXT'; };

    my $rv = {};

    for my $s (qw/1 101/) {
        my $url = "http://search.cpan.org/search?m=all&q=plack+middleware&s=$s&n=100";
        my $res = LWP::UserAgent->new->get($url);

        my $mod  = $m->scrape($res->decoded_content);
        my $desc = $d->scrape($res->decoded_content);

        for my $module (@{ $mod->{module} }) {
            my $description = shift @{ $desc->{desc} };
            my $author      = shift @{ $desc->{desc} };

            unless ($author =~ /.+ - .+ - .+/) {
                unshift @{ $desc->{desc} }, $author;
                $description = "none";
            }

            if ($module =~ /^Plack::Middleware/) {
                $rv->{$module} = {
                    description => $description,
                    author => $author,
                };
            }
        }
    }

    return $rv;
}

1;
__END__

=head1 NAME

App::ListMiddleware -

=head1 SYNOPSIS

  use App::ListMiddleware;

=head1 DESCRIPTION

App::ListMiddleware is

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
