package ModulesPerl6::Model::ResultClass;

use Import::Into;
sub import {
    strictures->import::into(1);
    DBIx::Class::Candy->import::into(1, -autotable => v1);
}

1;
