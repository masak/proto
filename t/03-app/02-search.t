#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most;
use Mojo::URL;
use Test::Mojo::WithRoles qw/SubmitForm ElementCounter/;
use t::Helper;

my $db_file = t::Helper::setup_db_file;
END { unlink $db_file }

my $t = Test::Mojo::WithRoles->new('ModulesPerl6');

{
    $t->dive_reset->get_ok('/')->status_is(200)
        ->element_exists('#search[action="/"]',        'search form'        )
        ->element_exists('#search [name="q"]',         'search box is there')
        ->element_exists('#search [type="submit"]',    'with submit button' );

    $t->click_ok('#search' => {q => 'Test'})->status_is(200)
            ->element_exists('#search [name="q"][value="Test"]')
            ->element_count_is('#dists tbody tr:not(.hidden)' => 2,
                'we have two results')
            ->text_like( '#dists tbody tr:first-child td:first-child a + a'
                => qr/^\s*Dist1\s*$/)
            ->text_like( '#dists tbody tr:first-child + tr td:first-child a + a'
                => qr/^\s*Dist2\s*$/);

    $t->click_ok('#search' => {q => 'Dist2'})->status_is(200)
            ->element_count_is('#dists tbody tr:not(.hidden)' => 1,
                'we have one result')
            ->element_exists('#dists tbody tr:first-child.hidden')
            ->text_like('#dists tbody tr:first-child + tr td:first-child a + a'
                => qr/^\s*Dist2\s*$/);

    $t->click_ok('#search' => {q => 'Dist42'})->status_is(200)
            ->element_count_is('#dists tbody tr' => 3,
                'dists table has three rows (2 dists, hidden, '
                . 'and 1 message saying there are no results')
            ->element_count_is('#dists tbody tr:not(.hidden)' => 1,
                'we have no results and showing the error message')
            ->text_like('#dists tbody tr:not(.hidden) .error'  =>
                qr/^\s*No results were found\s*$/)
    ;
}

done_testing;
