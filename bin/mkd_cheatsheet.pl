#!/usr/bin/env perl

package MkdCheatsheet;

use 5.20.0;

use strict;
use warnings;

use Text::MultiMarkdown qw/ markdown /;
use Path::Tiny;
use Web::Query;

use MooseX::App::Simple;

parameter 'src' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => 'markdown file to convert',
);

option pdf => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'generate pdf file',
);

option booklet => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    trigger => sub { $_[0]->pdf(1) },
    documentation => 're-arrange the pages to be booklet-printable',
);

sub run {
    my $self = shift;

    my $file = $self->src;

    my $html = markdown( path($file)->slurp );

    my $dest = path( path($file =~ s/\..*?$/.html/r)->basename );

    $dest->spew( $self->html_page($html) );

    return unless $self->pdf;

    system '/usr/bin/prince', $dest;

    $self->make_booklet;
}

sub make_booklet {
    my $self = shift;

    return unless $self->booklet;

    my $file = path($self->src)->basename;
    $file =~ s/\.mkd/\.pdf/;
    my $bf = $file =~ s/(?=\.pdf)/_booklet/r;

    `pdftk $file dump_data` =~ /NumberOfPages:\s*(\d+)/ or die;

    my $pages = $1;

    my @pages = 1..4*int($pages/4);

    my @new;

    while( @pages >= 4) {
        push @new, pop @pages, shift @pages, shift @pages, pop @pages;
    }

    my $temp = Path::Tiny->tempfile . '.pdf';

    system 'pdftk', $file, 'cat', @new, "output", $temp;

    system 'pdfnup', $temp, '--paper', 'letter', '--outfile', $bf;
}

sub html_page {
    my( $self, $content ) = @_;

    $content = Web::Query->new("<div>$content</div>", { indent => "  " });

    $content->add_class('content');

    $content->find('h1')->each(sub{
            $_->after( '<div class="header">' . $_->html . '</div>' );
    });
    $content->find('h2')->each(sub{
            $_->after( '<div class="subheader">' . $_->html . '</div>' );
    });
    $content->find('h2,h3')->filter(sub{
            $_->html =~ /^\s*\*/ 
    } )->each(sub{
        $_->add_class('breaker');
        $_->html( $_->html =~ s/^\s*\*//r );
    });

    $content->find('tr')->filter(sub{
        my $sumfin = 0;
        $_->find('td')->each(sub{
                $sumfin = 1 if $_->html and $_->html !~ /^\s*-+\s*$/;
        });
        return not $sumfin;
    })->remove;

    my $title = $content->find('h1')->html;

    $content = $content->as_html;

    my $style = path('style/style.css')->slurp;

    my $trailing_pages = 
        '<div style="page-break-after: always"></div>' x (3 * $self->booklet);

    return <<"END";
<html>
<head>
    <style>$style</style>
    <title>$title</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
    $content 
    $trailing_pages
</body>
</html>
END

}

__PACKAGE__->new_with_options->run unless caller;
