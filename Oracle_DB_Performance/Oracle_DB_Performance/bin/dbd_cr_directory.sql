-- run as system user
-- &1 - db name (not instance_name) i.e. DD288 not DD2881
CREATE DIRECTORY dir_splunk as '/u01/perf/dbdashboard/data/&1';
grant read,write  on directory dir_splunk to sch_spl;
