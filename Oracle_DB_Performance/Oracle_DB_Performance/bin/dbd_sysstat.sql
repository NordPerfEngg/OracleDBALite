CREATE OR REPLACE PROCEDURE nrd_sp_sysstat (sleep_interval number)
is

l_sleep_interval    number;
l_dbid              number;
l_dbname            varchar2(128);
l_db_block_size     number;
l_db_unique_name    varchar2(4000);
l_inst_id           number;
l_inst_id_t2        number;
l_inst_id_out       number;
l_name              varchar2(64);
l_name_t2           varchar2(64);
l_name_for_str      varchar2(64);
l_event             varchar2(128);
l_event_t2          varchar2(128);
l_total_waits       number;
l_total_waits_t2    number;
l_total_waits_for_str number;
l_time_waited_micro  number;
l_time_waited_micro_t2  number;
l_time_waited_micro_for_str  number;
l_value             number;
l_value_t2          number;
l_value_for_str     number;
l_lock_sql_id       varchar2(128);
l_lock_prev_sql_id       varchar2(128);
l_lock_event        varchar2(4000);
l_lock_clientinfo   varchar2(4000);
l_lock_UserName     varchar2(128);
l_lock_Seq          number;
l_lock_InstSid      varchar2(16);
l_lock_BlkInstSid   varchar2(16);
l_lock_SidSerial#   varchar2(16);
l_lock_OsUser       varchar2(128);
l_lock_Box          varchar2(32);
l_lock_SecInWait    number;
l_lock_WaitClass    varchar2(128);
l_lock_Program      varchar2(4000);
l_lock_Module       varchar2(4000);
l_lock_LogonTime    varchar2(32);
l_lock_ObjName      varchar2(128);
l_lock_RowWaitRowID urowid;
l_lock_RowWaitLookup varchar2(4000);
l_lock_SqlStart     varchar2(32);
l_lock_SqlVerCnt    varchar2(32);
l_lock_SqlTotExecutions number;
l_lock_SqlExecSec   varchar2(32);
l_lock_SqlAvgExecSec varchar2(32);
l_lock_SqlPlanHash  varchar2(32);
l_lock_SqlPlanBaseline varchar2(4000);
l_lock_SqlText      varchar2(4000);
l_tablespace_name          dba_tablespaces.tablespace_name%type;
l_tablespace_capacity_gb   number;
l_tablespace_capacity_gb   number;
l_tablespace_file_sp_gb    number;
l_tablespace_seg_sp_gb     number;
l_undo_block_size          number;
l_undo_used_gb             number;
i_inst_id           number := 0;
l_ora_directory     varchar2(128);
i                   number :=0;
metric_date         varchar2(24);
f                   utl_file.file_type;
f3                  utl_file.file_type;
str_sysstat0        varchar2(4000) := '';
str_sysstat         varchar2(4000) := '';
str_sysstat2        varchar2(4000) := '';
str_sysstat3        varchar2(4000) := '';
str_sysstat4        varchar2(4000) := '';
str_sysstat5        varchar2(4000) := '';
str_sysstat6        varchar2(4000) := '';
str_sysstat7        varchar2(4000) := '';
str_sysstat8        varchar2(4000) := '';
str_sysstat9        varchar2(4000) := '';
str_sysstat10       varchar2(4000) := '';
str_sysstat11       varchar2(4000) := '';
str_sysevent        varchar2(4000) :='';
str_sysevent0       varchar2(4000) :='';
str_lock            varchar2(4000) :='';
str_undo            varchar2(4000) :='';

-- data pre wait interval
CURSOR cur_sysstat IS
   SELECT regexp_replace(name,'( |:|/|-|\*|\(|\))','_') namex, sum(value) value
   FROM gv$sysstat
   WHERE name in
    ('consistent changes','consistent gets','db block gets','enqueue deadlocks','leaf node splits',
     'OS User level CPU time','OS Wait-cpu (latency) time','physical reads',
     'physical write total bytes','physical read IO requests','session logical reads','sorts (disk)',
     'sorts (memory)','SQL*Net roundtrips to/from client','SQL*Net roundtrips to/from dblink',
     'table fetch continued row','transaction rollbacks','user commits','user rollbacks',
     'branch node splits','global cache cr blocks served','global cache cr block receive time',
     'global cache cr block send time','global cache cr blocks served',
     'global cache cr block serve time','logons current','OS Input blocks','OS Output blocks',
     'recursive calls','OS System call CPU time','OS User level CPU time',
     'OS Wait-cpu (latency) time','queries parallelized','Parallel operations downgraded 1 to 25 pct',
     'Parallel operations downgraded 25 to 50 pct','Parallel operations downgraded 50 to 75 pct',
     'Parallel operations downgraded 75 to 99 pct','Parallel operations downgraded to serial',
     'Parallel operations not downgraded','parse count (hard)','parse count (total)',
     'physical read bytes','physical read total bytes','physical reads','physical reads cache',
     'physical reads direct','physical write bytes','physical write total bytes',
     'physical writes','physical writes direct','physical writes from cache',
     'OS Involuntary context switches','OS Major page faults' )
    GROUP BY name

   UNION ALL

   SELECT  regexp_replace(stat_name,'( |:|/|-|\*|\(|\))','_') namex, sum(value) value
   FROM gv$sys_time_model
   WHERE stat_name in 
     ('DB CPU','background cpu time')
   GROUP BY stat_name

   ORDER BY namex;

-- data post wait interval
CURSOR cur_sysstat_t2 IS
   SELECT regexp_replace(name,'( |:|/|\*|\(|\))','_') namex, sum(value) value
   FROM gv$sysstat
   WHERE name in
    ('consistent changes','consistent gets','db block gets','enqueue deadlocks','leaf node splits',
     'OS User level CPU time','OS Wait-cpu (latency) time','physical reads',
     'physical write total bytes','physical read IO requests','session logical reads','sorts (disk)',
     'sorts (memory)','SQL*Net roundtrips to/from client','SQL*Net roundtrips to/from dblink',
     'table fetch continued row','transaction rollbacks','user commits','user rollbacks',
     'branch node splits','global cache cr blocks served','global cache cr block receive time',
     'global cache cr block send time','global cache cr blocks served',
     'global cache cr block serve time','logons current','OS Input blocks','OS Output blocks',
     'recursive calls','OS System call CPU time','OS User level CPU time',
     'OS Wait-cpu (latency) time','queries parallelized','Parallel operations downgraded 1 to 25 pct',
     'Parallel operations downgraded 25 to 50 pct','Parallel operations downgraded 50 to 75 pct',
     'Parallel operations downgraded 75 to 99 pct','Parallel operations downgraded to serial',
     'Parallel operations not downgraded','parse count (hard)','parse count (total)',
     'physical read bytes','physical read total bytes','physical reads','physical reads cache',
     'physical reads direct','physical write bytes','physical write total bytes',
     'physical writes','physical writes direct','physical writes from cache',
     'OS Involuntary context switches','OS Major page faults' )
   GROUP BY name
   
   UNION ALL

   SELECT  regexp_replace(stat_name,'( |:|/|/|-|\*|\(|\))','_') namex, sum(value) value
   FROM gv$sys_time_model
   WHERE stat_name in
     ('DB CPU','background cpu time')
   GROUP BY stat_name

   ORDER BY  namex;


CURSOR cur_sysevent IS
   SELECT regexp_replace(event,'( |-|/|:|\*|\(|\))','_') eventx, sum(total_waits), sum(time_waited_micro)
   FROM gv$system_event
   WHERE wait_class in ('User I/O','Application','Concurrency','Cluster','Commit','Network','Configuration')
   --WHERE wait_class in ('User I/O','Application','Concurrency','Cluster','Other','Commit','Network')
     OR event in ('SQL*Net message from client')
   GROUP BY event
   ORDER by eventx;


CURSOR cur_sysevent_t2 IS
   SELECT regexp_replace(event,'( |-|/|:|\*|\(|\))','_') eventx, sum(total_waits), sum(time_waited_micro)
   FROM gv$system_event
   --WHERE wait_class  in ('User I/O','Application','Concurrency','Cluster','Other','Commit')
   WHERE wait_class in ('User I/O','Application','Concurrency','Cluster','Commit','Network','Configuration')
     OR event in ('SQL*Net message from client')
   GROUP BY event
   ORDER by eventx;


CURSOR cur_lock_blockers IS
   select
       sb2_SeqNum                 ,
       max(sb2_InstSid)           ,
       max(sb2_BlkInstSid)        ,
       max(sb2_SidSerial#)        ,
       max(sb2_OsUser)            ,
       max(sb2_Box)               ,
       max(sb2_SecInWait)         ,
       max(sb2_WaitClass)         ,
       max(sb2_Program)           ,
       max(sb2_Module)            ,
       max(sb2_ClientInfo)        ,
       max(sb2_UsrName)           ,
       max(sb2_LogOnTime)         ,
       max(sb2_Event)             ,
       max(sb2_ObjName)           ,
       max(sb2_RowWaitRowID)      ,
       max(sb2_RowWaitLookup)     ,
       max(sb2_SqlId)             ,
       max(sb2_SqlPrevSqlId)      ,
       max(sb2_SqlExecStart)      ,
       max(sb2_SqlVersionCount)   ,
       max(sb2_SqlTotExecutions)  ,
       round(((sysdate - max(sb2_SqlExecStart)) *1*24*60*60)) ,
       max(sb2_SqlAvrExecSec)     ,
       max(sb2_SqlPlanHash)       ,
       max(sb2_SqlPlanBaseline)   ,
       max(sb2_SqlText)           
   from
      ( select e.SeqNum1                      sb2_SeqNum,
           e.InstSid                          sb2_InstSid,
           e.SidSerial#                   sb2_SidSerial#,
           e.BlockInstSid                 sb2_BlkInstSid,
           e.OsUser                       sb2_OsUser,
           substr(e.Machine,1,9) || '  '  sb2_Box,
           e.Program                      sb2_Program,
           e.Module                       sb2_Module,
           e.ClientInfo                   sb2_ClientInfo,
           e.UserName                     sb2_UsrName,
           e.LogonTime  || ' '            sb2_LogOnTime,
           e.WaitClass                    sb2_WaitClass,
           e.Event                        sb2_Event,
           e.SecInWait                    sb2_SecInWait,
           e.RowWaitObj                   sb2_RowWaitObj,
           e.RowWaitFile                  sb2_RowWaitFile,
           e.RowWaitBlock                 sb2_RowWaitBlock,
           e.RowWaitRow                   sb2_RowWaitRow,
           e.ObjName                      sb2_ObjName,
           case when e.RowWaitObj > 0
                  then ROWIDTOCHAR(dbms_rowid.rowid_create(1, e.RowWaitObj, e.RowWaitFile, e.RowWaitBlock, e.RowWaitRow))
                  else 'AAAAAAAAAAAAAAAAAA'
           end  sb2_RowWaitRowID,
           case when  ((e.RowWaitObj > 0) and (e.Event = 'enq: TX - row lock contention')) then
                  'select * from ' || e.ObjOwner || '.' || e.ObjName || ' where rowid = '''
                  || ROWIDTOCHAR(dbms_rowid.rowid_create(1, e.RowWaitObj, e.RowWaitfile, e.RowWaitBlock, e.RowWaitRow)) || ''''
                  else 'AAAAAAAAAAAAAAAAAA'
           end sb2_RowWaitLookup,
           e.SqlId                        sb2_SqlId,
           e.PrevSqlId                    sb2_SqlPrevSqlId,
           e.SqlVersionCount              sb2_SqlVersionCount,
           e.SqlExecStart                 sb2_SqlExecStart,
           e.SqlTotExecutions             sb2_SqlTotExecutions,
           e.SqlTotElapsedTime            sb2_SqlTotElapsedTime,
           e.SqlFirstLoadTime             sb2_SqlFistLoadTime,
           e.SqlPlanHash                  sb2_SqlPlanHash,
           e.SqlPlanBaseline              sb2_SqlPlanBaseline,
           case when e.SqlTotExecutions > 0 then round(((e.SqlTotElapsedTime / 1000000) / e.SqlTotExecutions),2)  else 0 end sb2_SqlAvrExecSec,
           e.SqlText                      sb2_SqlText
       from
          (select rownum SeqNum1,
                 level,
                 d.InstSid InstSid,
                 d.SidSerial#,
                 d.BlockInstSid,
                 d.UserName,
                 d.LogonTime,
                 d.Machine,
                 d.Program,
                 d.Module,
                 d.ClientInfo,
                 d.Event,
                 d.WaitClass,
                 d.SecInWait,
                 d.ObjName,
                 d.ObjOwner,
                 d.SqlId,
                 d.PrevSqlId,
                 d.SqlExecStart,
                 d.SqlText,
                 d.SqlVersionCount,
                 d.OsUser,
                 d.RowWaitObj,
                 d.RowWaitFile,
                 d.RowWaitBlock,
                 d.RowWaitRow,
                 d.SqlTotExecutions,
                 d.SqlTotElapsedTime,
                 d.SqlFirstLoadTime,
                 d.SqlPlanHash,
                 d.SqlPlanBaseline
            from tmp_lock_info d
-----
        where ((InstSid in (select BlockInstSid from tmp_lock_info) or BlockInstSid <> '-')
        AND SecInWait > 0)
        OR (InstSid in (select BlockInstSid from tmp_lock_info) AND BlockInstSid = '-'
             AND SecInWait = 0)
        connect by nocycle prior InstSid = BlockInstSid
        start with BlkSes is null) e
   where e.UserName not in
('APEX_030200','APEX_PUBLIC_USER','APPQOSSYS','CTXSYS','DBSNMP','DIP','DMSYS','EXFSYS','MDDATA','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS''ORDSYS','OUTLN','SI_INFORMTN_SCHEMA','OWBSYS','OWBSYS_AUDIT','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','SQLTXADMIN','SQLTXPLAIN','SYS','TRCADMIN','TRCANLZR','TSMSYS')
      order by e.SeqNum1, e.SecInWait)
  group by sb2_SeqNum
  order by sb2_SeqNum
;

BEGIN

-- init
   EXECUTE IMMEDIATE 'alter session set nls_date_format=''mm/dd/yyyy hh24:mi:ss''';

   SELECT dbid, name into l_dbid, l_dbname from v$database;

   SELECT value into l_db_unique_name from v$parameter where name='db_unique_name';
   SELECT value into l_db_block_size from v$parameter where name='db_block_size';

   CASE l_db_unique_name
     WHEN 'DD547B_Y0319T1332' THEN
           l_ora_directory := 'DIR_SPLUNK1';
     WHEN 'DD547B_Y0319T1333' THEN
           l_ora_directory := 'DIR_SPLUNK2';
     ELSE
           l_ora_directory := 'DIR_SPLUNK';
    END CASE;


   l_sleep_interval := sleep_interval;

   f:= utl_file.fopen(l_ora_directory,'dbd_sysstat.txt','a',32767);
   f3:= utl_file.fopen(l_ora_directory,'dbd_locks.txt','a',32767);

   -- open cursors and fetch first record
   IF NOT cur_sysstat%ISOPEN THEN
      OPEN cur_sysstat;
   END IF;

   IF NOT cur_sysevent%ISOPEN THEN
      OPEN cur_sysevent;
   END IF;

   dbms_lock.sleep(l_sleep_interval);

   IF NOT cur_sysstat_t2%ISOPEN THEN
      OPEN cur_sysstat_t2;
   END IF;

   IF NOT cur_sysevent_t2%ISOPEN THEN
      OPEN cur_sysevent_t2;
   END IF;

   SELECT sysdate into metric_date from dual;

   ----- 
   ----- process sysstat data
   ----- 

   FETCH cur_sysstat into
      l_name, l_value;

   FETCH cur_sysstat_t2 into
     l_name_t2, l_value_t2;

   CASE l_db_unique_name
   WHEN 'DD547B_Y0319T1332' THEN
      l_inst_id_out := 1;
   WHEN 'DD547B_Y0319T1333' THEN
      l_inst_id_out := 2;
   ELSE
      l_inst_id_out := l_inst_id;
   END CASE;

   i:=0;

   str_sysstat := 'metric_date="' || metric_date || '"' ||
      ',  dbid=' || l_dbid ||
      ',  dbname=' || l_dbname ||
      ',  interval_seconds=' || l_sleep_interval;

   str_sysstat2 := 'metric_date="' || metric_date || '"' ||
      ',  dbid=' || l_dbid ||
      ',  dbname=' || l_dbname ||
      ',  interval_seconds=' || l_sleep_interval;

   str_sysstat3 := 'metric_date="' || metric_date || '"' ||
      ',  dbid=' || l_dbid ||
      ',  dbname=' || l_dbname ||
      ',  interval_seconds=' || l_sleep_interval;



    -- write a row in the text file for selected gv$sysstat columns for each instance
    WHILE NOT  cur_sysstat%NOTFOUND OR NOT cur_sysstat_t2%NOTFOUND
    LOOP

       i := i+1;
       l_name_for_str:='';
       l_value_for_str:=0;
          IF  cur_sysstat_t2%NOTFOUND THEN
            l_name_for_str := l_name;
            l_value_for_str := 0;
            FETCH cur_sysstat into
            l_name, l_value;

          ELSIF  cur_sysstat%NOTFOUND THEN
             l_value_for_str := l_value_t2;
             l_name_for_str := l_name_t2;
             FETCH cur_sysstat_t2 into
               l_name_t2, l_value_t2;

          ELSIF l_name < l_name_t2 THEN
            l_value_for_str := 0;
            l_name_for_str := l_name;
            FETCH cur_sysstat into
              l_name, l_value;

          ELSIF l_name = l_name_t2 THEN
            l_value_for_str := l_value_t2 - l_value;
            l_name_for_str :=  l_name;
            FETCH cur_sysstat into
                l_name, l_value;
            FETCH cur_sysstat_t2 into
                l_name_t2, l_value_t2 ;
          ELSE
             -- name t1 > name t2 so take t2 value as the value
            IF l_name > l_name_t2 THEN
              l_value_for_str := l_value_t2;
              l_name_for_str := l_name_t2;
              FETCH cur_sysstat_t2 into
                 l_name_t2, l_value_t2;
            END IF;
          END IF;

          str_sysstat0 :=   l_name_for_str ||  '=' || to_char(l_value_for_str);

          IF i < 20 THEN
             str_sysstat := str_sysstat || ', ' || str_sysstat0;
          ELSIF i < 40 THEN
              str_sysstat2 :=  str_sysstat2 || ', ' || str_sysstat0;
          ELSE
              str_sysstat3 :=  str_sysstat3 || ', ' || str_sysstat0;
          END IF;

    END LOOP;

    -- print line
    utl_file.put_line(f, 'line_1 ' || str_sysstat );
    utl_file.put_line(f, 'line_2 ' || str_sysstat2 );
    utl_file.put_line(f, 'line_3 ' || str_sysstat3 );

    -- close all
    CLOSE cur_sysstat;
    CLOSE cur_sysstat_t2;

--------------------
-- process sysevent data
-------------------

   FETCH cur_sysevent into
     l_event, l_total_waits, l_time_waited_micro;
   FETCH cur_sysevent_t2 into
     l_event_t2, l_total_waits_t2, l_time_waited_micro_t2;

   i:=0;

   str_sysstat4 := 'line 4  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;

   str_sysstat5 := 'line 5  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;

   str_sysstat6 := 'line 6  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;

   str_sysstat7 := 'line 7  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;

   str_sysstat8 := 'line 8  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;

   str_sysstat9 := 'line 9  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;

   str_sysstat10 := 'line 10  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;

   str_sysstat11 := 'line 11  metric_date="' || metric_date || '"' ||
    ',  dbid=' || l_dbid ||
    ',  dbname=' || l_dbname ||
    ',  db_block_size=' || l_db_block_size ;


   -- write a row in the text file for selected gv$sysevent columns for each instance
   WHILE NOT  cur_sysevent%NOTFOUND OR NOT cur_sysevent_t2%NOTFOUND
   LOOP
   -- When event t2 name is greater than event t1 name then discard t1 event 
   -- as it means t1 is invalid (it should be rare, as these are cumulative
   -- between startups so there should normally be a matching t1 name if there's a t2 name).

          l_total_waits_for_str:=0;
          l_time_waited_micro_for_str:=0;
          l_name_for_str:=0;

          IF  cur_sysevent_t2%NOTFOUND THEN
            l_total_waits_for_str := 0;
            l_time_waited_micro_for_str :=0;
            l_name_for_str := l_event;
            FETCH cur_sysevent into
            l_event, l_total_waits, l_time_waited_micro;
  
          ELSIF  cur_sysevent%NOTFOUND THEN
             l_total_waits_for_str := l_total_waits_t2;
             l_time_waited_micro_for_str := l_time_waited_micro_t2;
             l_name_for_str := l_event_t2;
             FETCH cur_sysevent_t2 into
               l_event_t2, l_total_waits_t2, l_time_waited_micro_t2;

          ELSIF l_event < l_event_t2 THEN
            l_total_waits_for_str := 0;
            l_time_waited_micro_for_str :=0;
            l_name_for_str := l_event;
            FETCH cur_sysevent into
              l_event, l_total_waits, l_time_waited_micro;    

          ELSIF
            l_event = l_event_t2 THEN
            l_total_waits_for_str := l_total_waits_t2 - l_total_waits;
            l_time_waited_micro_for_str := l_time_waited_micro_t2 - l_time_waited_micro;
            l_name_for_str := l_event;
            FETCH cur_sysevent into
                l_event, l_total_waits, l_time_waited_micro;    
            FETCH cur_sysevent_t2 into
                l_event_t2, l_total_waits_t2, l_time_waited_micro_t2;

          ELSE
             -- event name t1 > event name t2 so take t2 value as the value
            IF l_event > l_event_t2 THEN
              l_total_waits_for_str := l_total_waits_t2;
              l_time_waited_micro_for_str := l_time_waited_micro_t2;
              l_name_for_str := l_event_t2;
              FETCH cur_sysevent_t2 into
                 l_event_t2, l_total_waits_t2, l_time_waited_micro_t2;   
            END IF; 
          END IF;
          
          str_sysevent0 :=  ' ' || l_name_for_str || '_total_waits=' || l_total_waits_for_str ||
                         ' ' || l_name_for_str || '_time_waited_micro=' || l_time_waited_micro_for_str;

          IF i < 10 THEN
              str_sysstat4 := str_sysstat4 || ', ' || str_sysevent0;
          ELSIF i < 20 THEN
              str_sysstat5 := str_sysstat5 || ', ' || str_sysevent0;
          ELSIF i < 30 THEN
              str_sysstat6 := str_sysstat6 || ', ' || str_sysevent0;
          ELSIF i < 40 THEN
              str_sysstat7 := str_sysstat7 || ', ' || str_sysevent0;
          ELSIF i < 50 THEN
               str_sysstat8 := str_sysstat8 || ', ' || str_sysevent0;
          ELSIF i < 60 THEN
               str_sysstat9 := str_sysstat9 || ', ' || str_sysevent0;
          ELSIF i < 70 THEN
               str_sysstat10 := str_sysstat10 || ', ' || str_sysevent0;
          ELSE 
               str_sysstat11 := str_sysstat11 || ', ' || str_sysevent0;
          END IF;

          i := i+1;

   END LOOP;

   -- print lines
   utl_file.put_line(f, str_sysstat4 );
   utl_file.put_line(f, str_sysstat5 );
   utl_file.put_line(f, str_sysstat6 );
   utl_file.put_line(f, str_sysstat7 );
   utl_file.put_line(f, str_sysstat8 );
   utl_file.put_line(f, str_sysstat9 );
   utl_file.put_line(f, str_sysstat10 );
   utl_file.put_line(f, str_sysstat11 );


    -- close all
    utl_file.fclose(f);
    CLOSE cur_sysevent;
    CLOSE cur_sysevent_t2;

   -------------------
   -- Process Lock Info
   -------------------

-- Write the blocking locks rows

   Insert into tmp_lock_info
   select
                    x.inst_id                       InstId,
                    x.sid                           Sid,
                    max(x.serial#) || ' '           SidSerial#,
                    max(x.blocking_instance)        BlkInst,
                    max(x.blocking_session)         BlkSes,
                    max(x.event)                    Event,
                    max(x.wait_class)               WaitClass,
                    max(x.seconds_in_wait)          SecInWait,
                    max(x.inst_id) || '-' || max(x.sid)  InstSid   ,
                    max(x.blocking_instance) || '-' || max(x.blocking_session)  BlockInstSid,
                    max(c.object_name)              ObjName,
                    max(c.owner)                    ObjOwner,
                    max(x.sql_id)                   SqlId,
                    max(x.prev_sql_id)              PrevSqlId,
                    max(x.sql_exec_start)           SqlExecStart,
                    max(b.sql_text)                 SqlText,
                    max(x.machine)                  Machine,
                    max(x.program)                  Program,
                    max(x.module)                   Module,
                    max(x.client_info)              ClientInfo,
                    max(x.logon_time)               LogonTime,
                    max(x.username)                 UserName,
                    max(x.osuser)                   OsUser,
                    max(c.data_object_id)           RowWaitObj,
                    max(x.row_wait_file#)           RowWaitFile,
                    max(x.row_wait_block#)          RowWaitBlock,
                    max(x.row_wait_row#)            RowWaitRow,
                    sum(b.executions)               SqlTotExecutions,
                    sum(b.elapsed_time)             SqlTotElapsedTime,
                    sum(b.version_count)            SqlVersionCount,
                    min(b.first_load_time)          SqlFirstLoadTime,
                    max(d.plan_hash_value)          SqlPlanHash,
                    max(d.sql_plan_baseline)        SqlPlanBaseline

              from
                 ( select
                       a.inst_id,
                       a.sid,
                       a.serial#,
                       a.blocking_instance,
                       a.blocking_session,
                       a.event,
                       a.wait_class,
                       a.seconds_in_wait,
                       a.sql_id,
                       a.prev_sql_id,
                       a.sql_child_number,
                       a.sql_exec_start,
                       a.machine,
                       a.program,
                       a.module,
                       a.client_info,
                       a.logon_time,
                       a.username,
                       a.osuser,
                       a.row_wait_obj#,
                       a.row_wait_file#,
                       a.row_wait_block#,
                       a.row_wait_row#
                  from gv$session a
                  where a.username not in 
('APEX_030200','APEX_PUBLIC_USER','APPQOSSYS','CTXSYS','DBSNMP','DIP','DMSYS','EXFSYS','MDDATA','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS''ORDSYS','OUTLN','SI_INFORMTN_SCHEMA','OWBSYS','OWBSYS_AUDIT','SPATIAL_CSW_ADMIN_USR','SPATIAL_WFS_ADMIN_USR','SQLTXADMIN','SQLTXPLAIN','SYS','TRCADMIN','TRCANLZR','TSMSYS')) x,
                gv$sqlarea b,
                dba_objects c,
                gv$sql d
            where x.sql_id = b.sql_id(+)
            and x.row_wait_obj# = c.object_id(+)
            and x.sql_id = d.sql_id(+)
            and x.sql_child_number = d.child_number(+)
            and x.inst_id = d.inst_id(+)

            group by x.inst_id, x.sid;


-----
-- Write the cur_lock_blockers row

   IF NOT cur_lock_blockers%ISOPEN THEN
      OPEN cur_lock_blockers;
   END IF;

   FETCH cur_lock_blockers into 
       l_lock_Seq, 
       l_lock_InstSid, 
       l_lock_BlkInstSid,
       l_lock_SidSerial#, 
       l_lock_OsUser, 
       l_lock_Box,
       l_lock_SecInWait, 
       l_lock_WaitClass, 
       l_lock_Program,
       l_lock_module, 
       l_lock_ClientInfo, 
       l_lock_UserName,
       l_lock_LogonTime,
       l_lock_Event, 
       l_lock_ObjName, 
       l_lock_RowWaitRowID,
       l_lock_RowWaitLookup, 
       l_lock_Sql_Id,
       l_lock_prev_sql_Id,
       l_lock_SqlStart, 
       l_lock_SqlVerCnt,
       l_lock_SqlTotExecutions,
       l_lock_SqlExecSec,
       l_lock_SqlAvgExecSec,
       l_lock_SqlPlanHash,
       l_lock_SqlPlanBaseline,
       l_lock_SqlText;
    
       
    WHILE NOT cur_lock_blockers%NOTFOUND
    LOOP
       str_lock := 'metric_date=''' || metric_date ||'''' ||
              ',  dbid=' || l_dbid ||
              ',  dbname=' || l_dbname ||
              ',  lock_Seq=' || l_lock_Seq ||
              ',  InstSid='  || l_lock_InstSid || 
              ',  BlkInstSid='|| l_lock_BlkInstSid ||
              ',  SidSerial#=' || l_lock_SidSerial# || 
              ',  OsUser='     || l_lock_OsUser  ||
              ',  Box='   || l_lock_Box ||
              ',  SecInWait=' || l_lock_SecInWait   ||
              ',  WaitClass='  || l_lock_WaitClass  ||
              ',  Program='''  || l_lock_Program ||'''' ||
              ',  Module='''  ||  l_lock_module  ||'''' ||
              ',  ClientInfo='''  || l_lock_ClientInfo ||'''' ||
              ',  UserName='  || l_lock_UserName ||
              ',  LogonTime='''  || l_lock_LogonTime  ||'''' ||
              ',  Event='''  ||  l_lock_Event   ||'''' ||
              ',  ObjName='  || l_lock_ObjName   ||
              ',  RowWaitRowID=' || l_lock_RowWaitRowID  ||
              ',  RowWaitLookup="' || l_lock_RowWaitLookup  ||'"' ||
              ',  SqlId='  || l_lock_Sql_Id  ||
              ',  PrevSqlId='  || l_lock_prev_sql_Id  ||
              ',  SqlStart='''|| l_lock_SqlStart  ||'''' ||
              ',  SqlVerCnt='  || l_lock_SqlVerCnt  ||
              ',  SqlTotExecutions=' || l_lock_SqlTotExecutions ||
              ',  SqlExecSec='     || l_lock_SqlExecSec  ||
              ',  SqlAvgExecSec='  || l_lock_SqlAvgExecSec ||
              ',  SqlPlanHash='  || l_lock_SqlPlanHash  ||
              ',  SqlPlanBaseline=' || l_lock_SqlPlanBaseline  ||
              ',  SqlText='''|| l_lock_SqlText ||'''';


       utl_file.put_line(f3, str_lock);

       
       FETCH cur_lock_blockers into
          l_lock_Seq,
          l_lock_InstSid,
          l_lock_BlkInstSid,
          l_lock_SidSerial#,
          l_lock_OsUser,
          l_lock_Box,
          l_lock_SecInWait,
          l_lock_WaitClass,
          l_lock_Program,
          l_lock_module,
          l_lock_ClientInfo,
          l_lock_UserName,
          l_lock_LogonTime,
          l_lock_Event,
          l_lock_ObjName,
          l_lock_RowWaitRowID,
          l_lock_RowWaitLookup,
          l_lock_Sql_Id,
          l_lock_Prev_Sql_Id,
          l_lock_SqlStart,
          l_lock_SqlVerCnt,
          l_lock_SqlTotExecutions,
          l_lock_SqlExecSec,
          l_lock_SqlAvgExecSec,
          l_lock_SqlPlanHash,
          l_lock_SqlPlanBaseline,
          l_lock_SqlText;
    END LOOP; 
    CLOSE cur_lock_blockers;
    utl_file.fclose(f3);


----------------
    -- Write the undo info


    f := utl_file.fopen('DIR_SPLUNK','dbd_sysstat.txt','a',32767);

    str_undo := 'metric_date="' || metric_date || '"' ||
              ',  dbid=' || l_dbid ||
              ',  dbname=' || l_dbname;

    FOR t in (SELECT tablespace_name from dba_tablespaces where contents='UNDO')
    LOOP
      SELECT sum(bytes)/1024/1024/1024 into  l_tablespace_file_sp_gb
      from dba_data_files where tablespace_name = t.tablespace_name ;

      SELECT  sum(bytes)/1024/1024/1024 into  l_tablespace_seg_sp_gb
      from dba_segments where tablespace_name = t.tablespace_name ;

      str_undo := str_undo
             || ', undotbs_' ||t.tablespace_name|| '_file_sp_gb=' || l_tablespace_file_sp_gb  || ' '
             || ', undotbs_' ||t.tablespace_name || '_seg_sp_gb=' ||  l_tablespace_seg_sp_gb ;

    END LOOP;

    -- undo tbs block sizes should all be the same if not this miscalculates
    SELECT max(block_size) into l_undo_block_size
    FROM dba_tablespaces where contents='UNDO';

    SELECT (sum(used_ublk) * l_undo_block_size)/1024/1024/1024  into l_undo_used_gb from gv$transaction;

    str_undo := str_undo
             || ', undo_total_used_gb=' || l_undo_used_gb  || ' ';

    utl_file.put_line(f, str_undo);

    utl_file.fclose(f);

END;
/

