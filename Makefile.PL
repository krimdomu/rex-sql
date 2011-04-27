use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Rex-SQL',
   VERSION_FROM => 'lib/Rex/SQL.pm',
   PREREQ_PM => {'Rex' => '0.3.99.4', 'YAML' => 0},
   LICENSE => 'perl'
);

