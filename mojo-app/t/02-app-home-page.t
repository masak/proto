#!perl

use strict;
use warnings FATAL => 'all';
use Test::Most;
use Mojo::URL;
use Test::Mojo::WithRoles 'SubmitForm ElementCounter';
use t::Helper;

t::Helper::set_db_env;

my $t = Test::Mojo::WithRoles->new('ModulesPerl6');
my ( $dist1, $dist2 ) = t::Helper::dist_data;

$_->{travis_url} = Mojo::URL->new($_->{url})->host('travis-ci.org')
    for $dist1, $dist2;

{
    diag 'Have dists table with right data';
    $t->dive_reset->get_ok('/')->status_is(200)
        ->element_count_is('#dists tbody tr' => 2, 'we have just two dists')
        ->dive_in('#dists tbody tr:first-child ')
        ->dived_text_is('.name a[href^="/"]' => 'Dist1'     )
        ->dived_text_is('.desc'              => 'Test Dist1')
        ->dived_text_is('.kwalitee a'        => '100%'      )
        ->dived_text_is('.travis a'          => 'passing'   )
        ->dived_text_is('.stars a'           => '42'        )
        ->dived_text_is('.issues a'          => '12'        )
        ->dived_text_is('.updated'           => '2015-11-08')
        ->dived_text_is('.added'             => '2015-11-04')
        ->element_count_is(".name   a[href='$dist1->{url}']"           => 1)
        ->element_count_is('.name   a[href="/dist/Dist1"]'             => 1)
        ->element_count_is('.name   a i.sprite.s-dist1'                => 1)
        ->element_count_is(".travis a[href='$dist1->{travis_url}']"    => 1)
        ->element_count_is(".stars  a[href='$dist1->{url}stargazers']" => 1)
        ->element_count_is(".issues a[href='$dist1->{url}issues']}"    => 1)
    ;

    $t->dive_reset
        ->dive_in('#dists tbody tr:first-child + tr ')
        ->dived_text_is('.name a[href^="/"]' => 'Dist2'     )
        ->dived_text_is('.desc'              => 'Test Dist2')
        ->dived_text_is('.kwalitee a'        => '0'         )
        ->dived_text_is('.travis a'          => 'failing'   )
        ->dived_text_is('.stars a'           => '14'        )
        ->dived_text_is('.issues a'          => '6'         )
        ->dived_text_is('.updated'           => '2015-11-02')
        ->dived_text_is('.added'             => '2015-10-26')
        ->element_count_is(".name   a[href='$dist2->{url}']"           => 1)
        ->element_count_is('.name   a[href="/dist/Dist2"]'             => 1)
        ->element_count_is('.name   a i.sprite.s-dist2'                => 1)
        ->element_count_is(".travis a[href='$dist2->{travis_url}']"    => 1)
        ->element_count_is(".stars  a[href='$dist2->{url}stargazers']" => 1)
        ->element_count_is(".issues a[href='$dist2->{url}issues']}"    => 1)
    ;
}

{
    diag 'Misc elements';
    $t->dive_reset->get_ok('/')->status_is(200)
        ->text_is('.count' => 2, 'total distro count is displayed')
    ;

    $t->dive_reset->get_ok('/dist/Dist1')
        ->status_is(302)
        ->header_is(Location => 'https://github.com/perl6/modules.perl6.org/')
    ;
}

done_testing;
