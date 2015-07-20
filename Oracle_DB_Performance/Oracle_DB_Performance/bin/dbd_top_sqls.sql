CREATE OR REPLACE PROCEDURE nrd_sp_top_sqls
is

l_dbid number;
l_dbname varchar(128);
l_snap_id number;
l_inst_id number;
l_num_rows number :=20;
metric_date varchar2(24);
f utl_file.file_type;
f3 utl_file.file_type;
str_event varchar2(4000);
str_sql   varchar2(4000);
l_almost_uq_key varchar(24);
l_ora_directory varchar2(128);
l_db_unique_name varchar2(128);

CURSOR cur_snap_id IS
 (SELECT instance_number, max(snap_id)
  FROM dba_hist_snapshot
  WHERE dbid=l_dbid
  GROUP by instance_number);

BEGIN

  execute immediate 'truncate table tmp_top_sqlstats';

  SELECT dbid, name INTO l_dbid, l_dbname
     FROM v$database;
  SELECT value into l_db_unique_name from v$parameter where name='db_unique_name';
  CASE l_db_unique_name
     WHEN 'DD547B_Y0319T1332' THEN
      l_ora_directory := 'DIR_SPLUNK1';
     WHEN 'DD547B_Y0319T1333' THEN
      l_ora_directory := 'DIR_SPLUNK2';
     ELSE
      l_ora_directory := 'DIR_SPLUNK';
   END CASE;

  execute immediate 'alter session set nls_date_format=''mm/dd/yyyy hh24:mi:ss''';

  SELECT sysdate into metric_date from dual;

  SELECT dbms_random.string('L', 10) into l_almost_uq_key from dual;

  f  := utl_file.fopen(l_ora_directory,'dbd_top_sql.txt','a',32767);
  f3 := utl_file.fopen(l_ora_directory,'dbd_top_sql_text.txt','a',32767);


OPEN cur_snap_id;
LOOP
  FETCH cur_snap_id into l_inst_id, l_snap_id;
  EXIT WHEN cur_snap_id%NOTFOUND;
    insert into tmp_top_sqlstats
     SELECT
            l_dbid dbid,
            l_dbname DBNAME,
            a.snap_id  SNAP_ID,
            a.instance_number inst_id,
            a.sql_id SQL_ID,
            a.plan_hash_value SQL_PLAN_HASH_VALUE,
            0 ,
            0 ,
            0 ,
            0 ,
            sum(PARSE_CALLS_DELTA) PARSE_CALLS,
            sum(DISK_READS_DELTA) DISK_READS,
            sum(DIRECT_WRITES_DELTA) DIRECT_WRITES,
            sum(BUFFER_GETS_DELTA) BUFFER_GETS,
            sum (ROWS_PROCESSED_DELTA) ROWS_PROCESSED,
            SUM( FETCHES_DELTA) FETCHES, 
            SUM (EXECUTIONS_DELTA) EXECUTIONS,
            SUM( LOADS_DELTA) LOADS,
            sum( INVALIDATIONS_DELTA) INVALIDATIONS,
            sum( PX_SERVERS_EXECS_DELTA) PX_SERVERS_EXECUTIONS,
            sum( CPU_TIME_DELTA) CPU_TIME,
            sum( ELAPSED_TIME_DELTA) ELAPSED_TIME,
            sum( APWAIT_DELTA) APPLICATION_WAIT_TIME,
            sum(CCWAIT_DELTA) CONCURRENCY_WAIT_TIME,
            sum (CLWAIT_DELTA) CLUSTER_WAIT_TIME,
            sum(IOWAIT_DELTA) USER_IO_WAIT_TIME,
            sum(PLSEXEC_TIME_DELTA) PLSQL_EXEC_TIME,
            sum(JAVEXEC_TIME_DELTA) JAVA_EXEC_TIME,
            sum(SORTS_DELTA) SORTS,
            sum( SHARABLE_MEM) SHARABLE_MEM,
            sum( IO_INTERCONNECT_BYTES_DELTA) IO_INTERCONNECT_BYTES,
            sum (PHYSICAL_READ_REQUESTS_DELTA) PHYSICAL_READ_REQUESTS,
            sum( PHYSICAL_READ_BYTES_DELTA) PHYSICAL_READ_BYTES,
            sum( PHYSICAL_WRITE_REQUESTS_DELTA) PHYSICAL_WRITE_REQUESTS,
            sum(PHYSICAL_WRITE_BYTES_DELTA) PHYSICAL_WRITE_BYTES 
      FROM  dba_hist_sqlstat a
      WHERE a.dbid = l_dbid and
            a.snap_id = l_snap_id and
            a.instance_number = l_inst_id
      GROUP BY a.instance_number, a.snap_id, a.sql_id, a.plan_hash_value;

   commit;

   FOR rec in (SELECT * FROM tmp_top_sqlstats where inst_id=l_inst_id and snap_id = l_snap_id)
   LOOP
         str_sql :=  'metric_date="' || metric_date ||
          '", almost_uq_key=' || l_almost_uq_key ||
          ', dbid=' || l_dbid ||
          ', dbname=' || l_dbname ||
          ', instance_id='  || rec.inst_id ||
          ', snap_id=' ||  rec.snap_id ||
          ', sql_id=' || rec.sql_id ||',' ||
          ' plan_hash_value=' || rec.sql_plan_hash_value || ', ' ||
          'sql_time_waited=' || rec.time_waited ||
          ', sql_count=' || rec.count_sql ||
          ', sql_avg_time_waited=' || rec.avg_time_waited ||
          ', sql_max_time_waited=' || rec.max_time_waited ||
          ', parse_calls=' || rec.parse_calls ||
          ', disk_reads=' || rec.disk_reads ||
          ', direct_writes=' || rec.direct_writes ||
          ', buffer_gets=' || rec.buffer_gets ||
          ', rows_processed=' || rec.rows_processed ||
          ', fetches=' || rec.fetches ||
          ', executions=' || rec.executions ||
          ', loads=' || rec.loads ||
          ', invalidations=' || rec.invalidations ;
             -- write part 1 of the sql record  (necessary due to Splunk linesize limit of 1000 ch
               utl_file.put_line(f, str_sql);

          str_sql :=  'metric_date="' || metric_date ||
          '", almost_uq_key=' || l_almost_uq_key ||
          ', dbid=' || l_dbid ||
          ', dbname=' || l_dbname ||
          ', instance_id='  || rec.inst_id ||
          ', snap_id='  || rec.snap_id ||
          ', sql_id=' || rec.sql_id ||',' ||
          '  plan_hash_value=' || rec.sql_plan_hash_value || ', ' ||
          ', px_servers_executions=' || rec.px_servers_executions ||
          ', cpu_time=' || rec.cpu_time ||
          ', elapsed_time=' || rec.elapsed_time ||
          ', application_wait_time=' || rec.application_wait_time ||
          ', concurrency_wait_time=' || rec.concurrency_wait_time||
          ', cluster_wait_time=' || rec.cluster_wait_time ||
          ', user_io_wait_time=' || rec.user_io_wait_time ||
          ', plsql_exec_time=' || rec.plsql_exec_time ||
          ', java_exec_time=' || rec.java_exec_time ||
          ', sorts=' || rec.sorts ||
          ', sharable_mem=' || rec.sharable_mem ||
          ', io_interconnect_bytes=' || rec.io_interconnect_bytes ||
          ', physical_read_requests=' || rec.physical_read_requests ||
          ', physical_read_bytes=' || rec.physical_read_bytes ||
          ', physical_write_requests=' || rec.physical_write_requests ||
          ', physical_write_bytes=' || rec.physical_write_bytes;

           -- Write part 2 of the sql record
               utl_file.put_line(f, str_sql);

   END LOOP;


   FOR rec_sqltext in
    (SELECT distinct a.sql_id, replace( dbms_lob.substr(b.sql_text,950,1) ,'"') as sql_text_short
     FROM tmp_top_sqlstats a, dba_hist_sqltext b
     WHERE a.sql_id  = b.sql_id (+))
   LOOP
     str_sql := ' metric_date="' || metric_date || '" ' ||
            ' dbname=' || l_dbname || ' ' ||
            ' dbid=' || l_dbid || ' ' ||
            ' snap_id=' || l_snap_id || ' ' ||
            ' instance_id=' || l_inst_id || ' ' ||
            ' sql_id=' ||  rec_sqltext.sql_id || ' ' ||
            ' sqltext="' ||  rec_sqltext.sql_text_short || '"' ;
    utl_file.put_line(f3, str_sql);
    END LOOP;
END LOOP;
utl_file.fclose(f);
utl_file.fclose(f3);
execute immediate 'truncate table tmp_top_sqlstats';
END;
/

