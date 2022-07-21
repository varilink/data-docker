#!/usr/bin/env perl

use strict ;
use warnings ;

use CGI::Application::Dispatch::PSGI ;
use Config::Context ;
use YAML qw / LoadFile / ;

sub {

  my $env = shift ;

  my $conf = Config::Context -> new (

    file => '/usr/local/etc/data/site.cfg' ,

    driver => 'ConfigGeneral' ,

    match_sections => [

      {
        name => 'Location' ,
        match_type => 'path' ,
      } ,
      {
        name => 'LocationMatch' ,
        match_type => 'regex' ,
      } ,

    ] ,

    driver_options => {

      ConfigGeneral => {
        -AllowMultiOptions => 'yes' ,
        -IncludeDirectories => 'yes' ,
        -MergeDuplicateOptions => 'no' ,
        -UseApacheInclude => 'yes' ,
      } ,

    } ,

  ) ;

  my $rules = LoadFile "/usr/local/etc/data/table.yml" ;

  my $table = [ ] ;

  foreach my $rule ( @{ $rules } ) {

    my @keys = keys %{ $rule } ;

    my $path = $keys[0] ;
    my $app = $conf -> context ( $path ) -> { app } ;

    my $rm = $rule -> { $path } ;

    push @{ $table } , $path => { app => $app , rm => $rm } ;

  }

  # Dispatch the request
  my $app = CGI::Application::Dispatch::PSGI -> as_psgi (

    prefix => 'DATA' ,

    args_to_new => {

      PARAMS => {
        home => '/usr/local/src/data'
      } ,

    } ,

    table => $table ,

  ) ;

  return $app -> ( $env ) ;

}