#!/usr/bin/env perl

use 5.20.0;

use strict;
use warnings;

use Text::MultiMarkdown qw/ markdown /;
use Path::Tiny;
use Web::Query;

convert($_) for @ARGV;

sub convert {
    my $file = shift;

    my $html = markdown( path($file)->slurp );

    my $dest = path($file =~ s/\..*?$/.html/r);

    $dest->spew( html_page($html) );

    system '/usr/bin/prince', $dest;

    say $dest;

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

    my $style = my_style();

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

sub my_style { return <<'END';

@media print{
    @page {
        size: 5.5in 8.5in;
        margin: 1cm;
        margin-top: 0.75cm;
        margin-left: 0cm;
        margin-right: 0cm;
        padding: 0cm;
        padding-left: 0cm;
      //  @bottom { content: flow(footer) };
    }

    @page :first {
        margin-top: 0.25cm;
        @top-left { content: "" }
        @top-right { content: "" }
    }

    @page {
        @top-left {
            content: flow(header);
        }
        @top-right {
            content: flow(subheader,start);
        }
    }

    @page :right {
        @bottom-right {
            content: counter(page) "/" counter(pages)
        };
        padding-left: 2cm;
        padding-right: 1cm;
    }
    @page :left {
        @bottom-left {
            content: counter(page) "/" counter(pages)
        };
        padding-left: 1cm;
        padding-right: 2cm;
    }

}

div.footer { 
    text-align: right;
    border-top: solid 1px black;
   // flow: static(footer);
    font-style: italic;
}

div.header { flow: static(header); }
.subheader { flow: static(subheader); font-style: italic; text-align: right; }

.breaker { page-break-before: always; }

h1 {
    text-align: right;
    border-bottom: 1px black solid;
    font-size: large;
}

h2 {
    background-color: lightblue;
    font-size: larger;
}

h2:nth-of-type(1) {
    border-top: 0px;
}

body, table {
    font-family: sans-serif;
    font-size: 10pt;
//    column-count:2;
//    -moz-column-count:2; /* Firefox */
//    -webkit-column-count:2; /* Safari and Chrome */
}


tr {
    vertical-align: top;
}

th {
    border-bottom: solid 1px black;
    padding: 0em 1em;
    text-align: left;
}

td {
    padding: 0.25em 1em;
    vertical-align: top;
}

tbody:nth-child(even) {
//    background-color: lightgrey;
}

table {
    border-spacing: 0px;
//    margin: 0 2em;
}

td, th {
    border-left: 1px solid black;
}

td:nth-child(1), th:nth-child(1) {
    border-left: 0px;
}


END
}
