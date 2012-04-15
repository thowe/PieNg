# command used to autoload database
script/pieng_create.pl model PieDB DBIC::Schema PieDB::Schema create=static components=PassphraseColumn use_moose=0 dbi:Pg:dbname=pie_ng dbuser dbpassword
