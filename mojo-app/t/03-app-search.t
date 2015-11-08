#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most;
use Mojo::URL;
use Test::Mojo::WithRoles 'SubmitForm ElementCounter';
use t::Helper;

t::Helper::set_db_env;

my $t = Test::Mojo::WithRoles->new('ModulesPerl6');

{
    $t->dive_reset->get_ok('/')->status_is(200)
        ->element_exists('#search [action="/"]',       'search form'        )
        ->element_exists('#search [name="q"]',         'search box is there')
        ->element_exists('#search [type="submit"]',    'with submit button' )

        ->click_ok('#search' => {q => 'Test'})->status_is(200)
            ->element_exists('#search [name="q"][value="Test"]')
            ->element_count_is('#dists tbody tr' => 2, 'we have two results')
            ->element_text_is(
                '#dists tbody tr:first-child td:first-child'      => 'Dist1')
            ->element_text_is(
                '#dists tbody tr:first-child + tr td:first-child' => 'Dist2')

        ->click_ok('#search' => {q => 'Dist2'})->status_is(200)
            ->element_count_is('#dists tbody tr:not(.hidden)' => 1,
                'we have one result')
            ->element_exists('#dists tbody tr:first-child.hidden')
            ->element_text_is(
                '#dists tbody tr:first-child + tr td:first-child' => 'Dist2')

        ->click_ok('#search' => {q => 'Dist42'})->status_is(200)
            ->element_count_is('#dists tobdy tr' => 3,
                'dists table has three rows (2 dists, hidden, '
                . 'and 1 message saying there are no results')
            ->element_count_is('#dists tbody tr:not(.hidden)' => 1,
                'we have no results and showing the error message')
            ->element_text_is('#dists tbody tr:not(.hidden)'  =>
                'No results were found')
    ;
}

done_testing;
