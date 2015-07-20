# OracleDBALite
Application: DBALite Oracle Database Performance Summary App  Application Purpose:  Provide Oracle host and database performance info suitable for non-dbas.  Target users are Non-dba performance engineers, testers, prod support staff and application team members who want to proactively and reactively monitor their databases.  Licensing: Because this App queries the dba_hist_sqlstat AWR data, a license must exist for the Oracle Diagnostic Pack.  Most facilities running Oracle databases have this license.  Application Basic Structure: Four stored procedures run in the Oracle database.  They read performance data tables and write it out to datafiles which are consumed by Splunk.  Oracle Scheduler jobs execute the stored procedures at configurable intervals.  The app also uses the Splunk Add-on for Unix and Linux to get host metrics.   Dependencies: Splunk Add-on for Unix and Linux  (http://docs.splunk.com/Documentation/UnixAddOn/latest/User/InstalltheSplunkAdd-onforUnixandLinux) Stored procedures and scheduler jobs running in Oracle Database 11.1 or higher (procedures scripts included in the setup files.)  Index creation: Splunk Add-on For Unix and Linux will create the 'unix_metrics' index. This DBALite app will create the 'database' index.  Sourcetypes: om:oracle:locks -- snapshot information about blocking locks om:oracle:memory -- Oracle sga and pga memory statistics om:oracle:osstat -- Operating System stats from v$osstat table om:oracle:sql -- top resource consuming sqls from dba_hist_sqlstat om:oracle:sqltext -- sqltext for the top resource consuming sqls om:oracle:sysevent -- wait event information om:oracle:sysstat -- performance statistics from v$sysstat table  Installation:  Oracle Setup:  Copy all the sql scripts from the Oracle_Performance_Summary_For_Splunk/bin directory to your database server or run them in SQL Developer or other tool. Connect to your database. As sysdba, create the splunk sch_spl user.  (Sysdba is required for this one script in order to grant privileges on DBMS_LOCK and UTL_FILE: @cr_sch_spl.sql  Create a unix directory where you want Oracle to write the output files.  Splunk will pick up the data from these output files created by the stored procedures.  If the owner of the directory is not the ORACLE user, then make the ORACLE user a member of the Unix group for the directory so that Oracle can write to the directory.  Make the permissions on the directory 774.  Note: For a RAC database, just create the directory on one node.  The app is not elaborate enough to provide failover capabilities, so in case of an outage of its node, the data would just not be written until the node came back online.    Create an Oracle Directory called 'DIR_SPLUNK' using the above unix directory. Example: CREATE DIRECTORY dir_splunk as '/u01/perf/dbdashboard/data'; grant read,write  on directory dir_splunk to sch_spl;  As the splunk user SCH_SPL, create the stored procedures and scheduler jobs that will run them: @cr_procs_and_jobs.sql  After 10 minutes, check the data files to confirm there is data being written to them.  These data files should exist: dbd_locks.txt dbd_memory.txt dbd_osstat.txt dbd_sysevents.txt dbd_sysstat.txt dbd_top_sql_text.txt dbd_top_sql.txt  To check the scheduler jobs, as SCH_SPL user, execute: 'SELECT job_name, actual_start_date, status, additional_info from user_scheduler_job_run_details order by actual_start_date;'        

# Application: DBALite Oracle Database Performance Summary App
Presenting the AWESOME “Oracle Database Performance Splunk App”
-This totally killer tool enables a unified snapshot view of database performance on all critical  parameters including CPU, Memory Utilization, Deadlock, IO Waits, SQL Statistics and more.
-In a single click: Pick an Environment, Select a timeframe, and voila.....all the information that previously took hours, using a myriad of DB tools, is readily available.
-Then use Splunk's capabilities to drill down and quickly identify the root cause of performance issues.


# Application Purpose: 
Provide Oracle host and database performance info suitable for non-dbas.  Target users are Non-dba performance engineers, testers, prod support staff and application team members who want to proactively and reactively monitor their databases.

# Licensing:
Because this App queries the dba_hist_sqlstat AWR data, a license must exist for the Oracle Diagnostic Pack.  Most facilities running Oracle databases have this license.

# Application Basic Structure:
Four stored procedures run in the Oracle database.  They read performance data tables and write it out to datafiles which are consumed by Splunk.  Oracle Scheduler jobs execute the stored procedures at configurable intervals.  The app also uses the Splunk Add-on for Unix and Linux to get host metrics. 

# Dependencies:
Splunk Add-on for Unix and Linux  (http://docs.splunk.com/Documentation/UnixAddOn/latest/User/InstalltheSplunkAdd-onforUnixandLinux)
Stored procedures and scheduler jobs running in Oracle Database 11.1 or higher (procedures scripts included in the setup files.)

# Index creation:
Splunk Add-on For Unix and Linux will create the 'unix_metrics' index.
This DBALite app will create the 'database' index.

# Sourcetypes:
om:oracle:locks -- snapshot information about blocking locks
om:oracle:memory -- Oracle sga and pga memory statistics
om:oracle:osstat -- Operating System stats from v$osstat table
om:oracle:sql -- top resource consuming sqls from dba_hist_sqlstat
om:oracle:sqltext -- sqltext for the top resource consuming sqls
om:oracle:sysevent -- wait event information
om:oracle:sysstat -- performance statistics from v$sysstat table

# Installation:

Get the Splunk Add-on for Unix and Linux from Splunkbase and install http://docs.splunk.com/Documentation/UnixAddOn/latest/User/InstalltheSplunkAdd-onforUnixandLinux. DBALite app uses data collected from the vmstat, iostat and cpu sourcetypes.

Get the DBALite app down from Github and unzip in the <SplunkHome>/etc/apps directory.

# Oracle Setup:

Copy all the sql scripts from the Oracle_Performance_Summary_For_Splunk/bin directory to your database server or run them in SQL Developer or other tool.
Connect to your database.
As sysdba, create the splunk sch_spl user.  (Sysdba is required for this one script in order to grant privileges on DBMS_LOCK and UTL_FILE:
@cr_sch_spl.sql

Create a unix directory where you want Oracle to write the output files.  Splunk will pick up the data from these output files created by the stored procedures.  If the owner of the directory is not the ORACLE user, then make the ORACLE user a member of the Unix group for the directory so that Oracle can write to the directory.  Make the permissions on the directory 774.  Note: For a RAC database, just create the directory on one node.  The app is not elaborate enough to provide failover capabilities, so in case of an outage of its node, the data would just not be written until the node came back online.  

Create an Oracle Directory called 'DIR_SPLUNK' using the above unix directory. Example:
CREATE DIRECTORY dir_splunk as '/u01/perf/dbdashboard/data';
grant read,write  on directory dir_splunk to sch_spl;

As the splunk user SCH_SPL, create the stored procedures and scheduler jobs that will run them:
@cr_procs_and_jobs.sql

After 10 minutes, check the data files to confirm there is data being written to them. 
These data files should exist:
dbd_locks.txt
dbd_memory.txt
dbd_osstat.txt
dbd_sysstat.txt
dbd_top_sql_text.txt
dbd_top_sql.txt

To check the scheduler jobs, as SCH_SPL user, execute:
'SELECT job_name, actual_start_date, status, additional_info from user_scheduler_job_run_details order by actual_start_date;'

# Splunk Setup:

DBALite uses lookup files to populate choices for dropdowns.  Open the lookup files at <SPLUNK_HOME>/lookups and edit each one, modifying server and database names.


In <Splunk_HOME>/ect/apps/default/data/ui/views  open dbqes_vw_investigate_cpu_and_mem.xml and modify the section at the top to reflect your environment.  For example, change the "<condition label="COM Lab A DD288"> to whatever you put in the lookup file 'dbqes_lkp_host_dbname.csv' lookup file and change the <set token="dbname_">DD288</set> to your your databse name.  Create a 'condition' section for each entry in the 'dbqes_lkp_host_dbname.csv' file.

example:
<fieldset submitButton="false" autoRun="true">
    
    <input type="dropdown" submitButton="false" token="host_" searchWhenChanged="true">
      <label>Select an environment</label>
      <default>Pick an Environment</default>
      <populatingSearch fieldForLabel="environment" fieldForValue="host">
        <![CDATA[| inputlookup dbqes_lkp_host_dbname.csv ]]>
      </populatingSearch>
     <change>
       <condition label="COM Lab A DD288">
         <set token="dbname_">DD288</set>
         <set token="p1_display">true</set>
         <set token="p2_display">true</set>
         <set token="p3_display">true</set>
         <set token="p4_display">true</set>
         <set token="p5_display">true</set>
         <set token="p6_display">true</set>
         <set token="p7_display">true</set>
         <set token="p8_display">true</set>
         <set token="p9_display">true</set>
         <set token="p10_display">true</set>
         <set token="p11_display">true</set>
         <set token="p13_display">true</set>        
       </condition>






 
