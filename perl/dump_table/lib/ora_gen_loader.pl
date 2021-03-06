# $Id: ora_gen_loader.pl 6 2006-09-10 15:35:16Z marcus $
#
# My generated files for ORACLE
#

require 'lib/ora_code_util.pl';

sub make_ctl
{
    #### Control file
    my $tab     = shift;
    my @columns = @_ ;

    my $list = join ( "\n, ", @columns );

    my $code = <<"    CTL" ;
    CODE -- Generated by:
    CODE --    $0
    CODE --
    CODE -- Errors: 1.000.000.000 -- 1 billion, i.e., all rows in the file
    CODE --   Rows:     1.000.000
    CODE -- Bind/ReadSize : 20M (Solaris8 32bit, Oracle 8.1.7)
    CODE --                  2M
    CODE --
    CODE OPTIONS ( ERRORS=999999999
    CODE         ,   ROWS=100000
    CODE         , DIRECT=FALSE
    CODE      -- , BINDSIZE=20971520
    CODE      -- , READSIZE=20971520
    CODE         , BINDSIZE=2097152
    CODE         , READSIZE=2097152
    CODE         )
    CODE LOAD DATA
    CODE INFILE $tab.csv
    CODE     INTO TABLE $tab
    CODE     APPEND
    CODE     FIELDS TERMINATED BY ';' OPTIONALLY ENCLOSED BY '"'
    CODE ( $list
    CODE )
    CODE
    CTL

    put_file ("${tab}.ctl", $code);
    return 1;
}

sub make_ins_sel
{
    #### SELECT/INSERT script
    my $tab     = shift;
    my @columns = @_ ;
    my $list = join ( "\n     , "     , @columns );
    my $code = <<"    SQL" ;
    CODE --
    CODE -- Generated by: $0
    CODE --
    CODE INSERT INTO $tab --\@dblink
    CODE      ( $list
    CODE      )
    CODE SELECT $list
    CODE   FROM $tab --\@dblink
    CODE  WHERE 1=1
    CODE /
    CODE
    SQL

    put_file("${tab}_ins.sql", $code);
    return 1;
}

sub make_ins_sel_pl
{
    #### SELECT/INSERT in PL/SQL block, with commit control
    my $tab     = shift;
    my @columns = @_ ;
    my $list1 =         join ( "\n         , "                 , @columns );
    my $list2 =         join ( "\n                      , "    , @columns );
    my $list3 = "r1." . join ( "\n                      , r1." , @columns );
    my $code = <<"    PLSQL" ;
    CODE --
    CODE -- Generated by: $0
    CODE --
    CODE DECLARE
    CODE     CURSOR c1 IS
    CODE     SELECT $list1
    CODE       FROM $tab -- \@FED.F00000000000001
    CODE      WHERE 1=1
    CODE          ;
    CODE     c   NUMBER := 0;
    CODE     k   NUMBER := 0;
    CODE     kt  NUMBER := 0;
    CODE BEGIN
    CODE     --
    CODE     -- DBMS_REPUTIL.REPLICATION_OFF;
    CODE     --
    CODE     SELECT count(1)
    CODE       INTO kt
    CODE       FROM $tab  -- \@FED.F00000000000001
    CODE      WHERE 1=1
    CODE          ;
    CODE     --
    CODE     DBMS_APPLICATION_INFO.SET_MODULE
    CODE         ( 'Balance: [$tab]' , 'START');
    CODE     --
    CODE     FOR r1 IN c1
    CODE     LOOP
    CODE         --
    CODE         BEGIN
    CODE             INSERT INTO $tab
    CODE                       ( $list2
    CODE                       )
    CODE                 VALUES( $list3
    CODE                       );
    CODE             --
    CODE             c := c + 1;
    CODE             IF c >= 5000
    CODE             THEN
    CODE                 c := 0;
    CODE                 COMMIT;
    CODE             END IF;
    CODE             --
    CODE         EXCEPTION
    CODE             WHEN DUP_VAL_ON_INDEX THEN NULL;
    CODE         END;
    CODE         --
    CODE         k := k + 1;
    CODE         DBMS_APPLICATION_INFO.SET_ACTION
    CODE             ( 'Progress: '||TO_CHAR(k ,'999g999g999g990')||'/'
    CODE                           ||TO_CHAR(kt,'999g999g999g990') );
    CODE         --
    CODE     END LOOP;
    CODE     --
    CODE     -- COMMIT;
    CODE     -- DBMS_REPUTIL.REPLICATION_ON;
    CODE     --
    CODE     DBMS_APPLICATION_INFO.SET_ACTION
    CODE         ( 'Final: '||TO_CHAR(k ,'999g999g999g990')||'/'
    CODE                    ||TO_CHAR(kt,'999g999g999g990') );
    CODE END;
    CODE /
    CODE
    PLSQL

    put_file ("${tab}_ins_pl.sql", $code);
    return 1;
}

sub make_pl
{
    #### Spool Generator
    my $usr     = shift;
    my $psw     = shift;
    my $sid     = shift;
    my $tab     = shift;
    my @columns = @_ ;

    my $list = join ( "\n         , " , @columns );

    my $code = <<"    TEMPLATE";
    CODE #!perl
    CODE #
    CODE # Generated by: $0
    CODE #
    CODE # dump_results
    CODE
    CODE use DBI;
    CODE
    CODE my \$sep = ";"; # separator
    CODE my \$enc = "^"; # enclosed by
    CODE
    CODE # Params
    CODE my \$user = "$usr";
    CODE my \$psw  = "$psw";
    CODE my \$sid  = "$sid";
    CODE my \$arq  = "$tab.csv";
    CODE my \$sql  = <<"SQL";
    CODE     /* \$0 */
    CODE     SELECT $list
    CODE       FROM $tab
    CODE
    CODE SQL
    CODE
    CODE # error Checking
    CODE my \%attr =  (   PrintError => 1
    CODE             ,   RaiseError => 1
    CODE             );
    CODE # Connect
    CODE my \$dbh = DBI->connect ("dbi:Oracle:\$sid"
    CODE                        ,"\$user"
    CODE                        ,"\$psw"
    CODE                        ,\\\%attr
    CODE                        )
    CODE             or die "Cannot connect : ", \$DBI::errstr, "\\n" ;
    CODE
    CODE my \$sth = \$dbh->do("alter session set nls_date_format='dd/mm/yyyy hh24:mi:ss'");
    CODE    \$sth = \$dbh->prepare( \$sql );
    CODE    \$sth->execute;
    CODE
    CODE # dump file
    CODE open FILE, ">\$arq"
    CODE     or die "Cannot open csv file: \$!\\n";
    CODE
    CODE while ( \@rows = \$sth->fetchrow_array )
    CODE {
    CODE     print FILE \$enc
    CODE              , join( "\$enc"."\$sep"."\$enc", \@rows)
    CODE              , \$enc
    CODE              , "\\n";
    CODE }
    CODE
    CODE close FILE
    CODE     or die "Cannot close result file: \$! \\n";
    CODE
    CODE # end
    CODE \$dbh->disconnect;
    CODE
    TEMPLATE

    put_file ("${tab}.pl", $code);
    return 1;
}

return 1;
