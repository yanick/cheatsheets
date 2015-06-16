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
    is => 'ro',
    isa => 'Bool',
    default => 0,
    documentation => 'generate pdf file',
);

sub run {
    my $self = shift;

    my $file = $self->src;

    my $html = markdown( path($file)->slurp );

    my $dest = path( path($file =~ s/\..*?$/.html/r)->basename );

    $dest->spew( html_page($html) );

    return unless $self->pdf;

    system '/usr/bin/prince', $dest;

    exec 'pdfbooklet', path( $dest =~ s/\.html$/.pdf/r );
}

sub html_page {
    my $content = shift;

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

    my $title = $content->find('h1')->html;

    $content = $content->as_html;

    my $style = path('style/style.css')->slurp;

    return <<"END";
<html>
<head>
    <style>$style</style>
    <title>$title</title>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
</head>
<body>
    $content 
</body>
</html>
END

}

__PACKAGE__->new_with_options->run unless caller;
