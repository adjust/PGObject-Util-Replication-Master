use Test::More;
use PGObject::Util::Replication::Master;

plan skip_all => 'DB_TESTING not set' unless $ENV{DB_TESTING};
