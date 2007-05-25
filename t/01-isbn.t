#!perl -T
use lib qw(t/lib);
use DBICTest;
use Test::More tests => 19;
use Business::ISBN;

my $schema = DBICTest->init_schema();
my $rs     = $schema->resultset('Library');

my $code = '0321430840';

my $book = $rs->find(1);
isa_ok($book->isbn, 'Business::ISBN', 'data inflated to right class');
is($book->isbn->isbn, $code, 'data correctly inflated');

my $book = $rs->find(2);
isa_ok($book->isbn, 'Business::ISBN', 'data inflated to right class');
isa_ok(\$book->book, 'SCALAR', 'other field not inflated');
is($book->isbn->isbn, '190351133X', 'data with X correctly inflated');

TODO: {
    local $TODO = "DBIx::Class doesn't support find by object yet";
    my $book2 = $rs->find( Business::ISBN->new($code),
                          { key => 'isbn' } );
    ok($book2, 'find by object returned a row');
}
SKIP: {
    skip 'no find object to check' => 1 unless $book2;
    is($book2->isbn->isbn, $code, 'find by object returned the right row');
}

my $book1 = $rs->search( isbn => Business::ISBN->new($code) );
ok($book1, 'search by object returned a row');
$book1 = $book1->first;
SKIP: {
    skip 'no search object to check' => 1 unless $book1;
    is($book1->isbn, $code, 'search by object returned the right row');
}

my $isbn = Business::ISBN->new('0374292795');
my $host = $rs->create({ book => 'foo', isbn => $isbn });
isa_ok($host, 'DBICTest::Library', 'create with object');
is($host->get_column('isbn'), $isbn->isbn, 'numeric code correctly deflated');

$isbn = Business::ISBN->new('071351700X');
my $host = $rs->create({ book => 'Elementary Mechanics', isbn => $isbn });
isa_ok($host, 'DBICTest::Library', 'create with object');
is($host->get_column('isbn'), $isbn->isbn, 'code with X correctly deflated');
ok($host->isbn->is_valid, 'validation checked');

$isbn = Business::ISBN->new('0713517001');
my $host = $rs->create({ book => 'Elementary Mechanics', isbn => $isbn });
isa_ok($host, 'DBICTest::Library', 'create with object');
is($host->get_column('isbn'), $isbn->isbn, 'code with X correctly deflated');
is($host->isbn->is_valid_checksum, Business::ISBN::BAD_CHECKSUM, 'validation error checked');

#$isbn = Business::ISBN->new('foobar');
#eval { $book = $rs->create({ book => 'foobar', isbn => $isbn }); };
#ok($@, 'check for error with invalid data');

my $isbn = Business::ISBN->new('978-0-596-52724-2');
SKIP: {
    skip 'ISBN13 not supported' => 2 unless $isbn;
    my $host = $rs->create({ book => 'baz', isbn => $isbn->isbn });
    isa_ok($host, 'DBICTest::Library', 'create with object');
    is($host->get_column('isbn'), $isbn->isbn, 'numeric code correctly deflated');
}
