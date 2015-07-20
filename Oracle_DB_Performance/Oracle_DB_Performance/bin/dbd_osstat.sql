CREATE OR REPLACE PROCEDURE nrd_sp_osstat (sleep_interval number)
is

l_sleep_interval number;
l_inst_id        number;
l_inst_id_t2     number;
l_inst_id_out    number;
l_db_unique_name varchar2(4000);
l_stat_name      varchar2(64);
l_stat_name_t2   varchar2(64);
l_value          number;
l_value_t2       number;
l_osstat_id      number;
l_osstat_id_t2   number;
l_comments       varchar2(4000);
l_comments_t2    varchar2(4000);
l_cumulative     varchar2(3);
l_cumulative_t2   varchar2(3);
l_dbid           number;
l_dbname         varchar2(128);
i_inst_id        number := 999;
l_ora_directory  varchar2(128);


metric_date      varchar2(24);
f                utl_file.file_type;
str_osstat       varchar2(4000);
str_osstat2      varchar2(4000);
str_osstat3      varchar2(4000);
str_osstat4      varchar2(4000);
str_osstat0      varchar2(4000);
i number;

-- data pre wait interval
CURSOR cur_osstat IS
   SELECT 
     INST_ID,
     STAT_NAME,
     VALUE,
     OSSTAT_ID,
     COMMENTS, 
     CUMULATIVE
   FROM gv$osstat
     order by inst_id, stat_name;

-- data post wait interval
 CURSOR cur_osstat_t2 IS
   SELECT 
     INST_ID,
     STAT_NAME,
     VALUE,
     OSSTAT_ID,
     COMMENTS, 
     CUMULATIVE
   FROM gv$osstat
   order by inst_id, stat_name;

BEGIN

-- init
EXECUTE IMMEDIATE 'alter session set nls_date_format=''mm/dd/yyyy hh24:mi:ss''';

l_sleep_interval := sleep_interval;

select dbid, name into l_dbid, l_dbname from v$database;

select value into l_db_unique_name from v$parameter where name='db_unique_name';

CASE l_db_unique_name
  WHEN 'DD547B_Y0319T1332' THEN
    l_ora_directory := 'DIR_SPLUNK1';
  WHEN 'DD547B_Y0319T333' THEN
    l_ora_directory := 'DIR_SPLUNK2';
  ELSE
    l_ora_directory := 'DIR_SPLUNK';
END CASE;

f := utl_file.fopen(l_ora_directory,'dbd_osstat.txt','a',32767);



-- open cursors and fetch first record
IF NOT cur_osstat%ISOPEN THEN OPEN cur_osstat;
END IF;

dbms_lock.sleep(l_sleep_interval);

IF NOT cur_osstat_t2%ISOPEN THEN
   OPEN cur_osstat_t2;
END IF;

SELECT sysdate into metric_date from dual;

FETCH cur_osstat into
     l_inst_id, l_stat_name, l_value, l_osstat_id, l_comments, l_cumulative;
FETCH cur_osstat_t2 into
     l_inst_id_t2, l_stat_name_t2, l_value_t2, l_osstat_id_t2,  l_comments_t2, l_cumulative_t2;

i:=0;
i_inst_id:=l_inst_id;
-- write a row in the text file for selected gv$osstat columns for each instance
WHILE NOT  cur_osstat%NOTFOUND
   LOOP
       -- each time the instance_id changes
       -- print the previous lines and write beginning of new first line string
       IF l_inst_id <> i_inst_id and i <> 0 THEN
         utl_file.put_line(f, '"line_1"' || str_osstat);
         utl_file.put_line(f, '"line_2"' || str_osstat2);
         utl_file.put_line(f, '"line_3"' || str_osstat3);
         utl_file.put_line(f, '"line_4"' || str_osstat4);

         i_inst_id := l_inst_id;
         i:=0;

       END IF;

       CASE l_db_unique_name
         WHEN 'DD547B_Y0319T1332' THEN
           l_ora_directory := 'DIR_SPLUNK1';
       WHEN 'DD547B_Y0319T333' THEN
           l_ora_directory := 'DIR_SPLUNK2';
       ELSE
           l_ora_directory := 'DIR_SPLUNK';
       END CASE;

       IF i=0 THEN
                  str_osstat := 'metric_date="' || metric_date || '"' ||
              ',  instance_id=' || to_char(l_inst_id) ||
              ',  dbid=' || l_dbid ||
              ',  dbname=' || l_dbname;

                  str_osstat2 := 'metric_date="' || metric_date || '"' ||
              ',  instance_id=' || to_char(l_inst_id) ||
              ',  dbid=' || l_dbid ||
              ',  dbname=' || l_dbname;

                  str_osstat3 := 'metric_date="' || metric_date || '"' ||
              ',  instance_id=' || to_char(l_inst_id) ||
              ',  dbid=' || l_dbid ||
              ',  dbname=' || l_dbname;

                  str_osstat4 := 'metric_date="' || metric_date || '"' ||
              ',  instance_id=' || to_char(l_inst_id) ||
              ',  dbid=' || l_dbid ||
              ',  dbname=' || l_dbname;
       END IF;

       i := i + 1;

       IF l_cumulative = 'YES' THEN

          l_value := l_value_t2 - l_value;

       END IF;

       str_osstat0 :=
                ', ' || l_stat_name ||  '=' || to_char(l_value) ||
                ', osstat_id_' ||  l_stat_name ||  '=' || to_char(l_osstat_id) ||
                ', cumulative_' || l_stat_name ||  '=' || to_char(l_cumulative) ;
       CASE
          WHEN i<=6 THEN  str_osstat := str_osstat || str_osstat0;
          WHEN i<=11 THEN str_osstat2 := str_osstat2 || str_osstat0;
          WHEN i<=17 THEN str_osstat3 := str_osstat3 || str_osstat0;
          ELSE str_osstat4 := str_osstat4 || str_osstat0;
       END CASE;


       FETCH cur_osstat into
           l_inst_id, l_stat_name, l_value, l_osstat_id,  l_comments, l_cumulative;
       FETCH cur_osstat_t2 into
           l_inst_id_t2, l_stat_name_t2, l_value_t2, l_osstat_id_t2, l_comments_t2, l_cumulative_t2;

    END LOOP;

    -- print last line
    utl_file.put_line(f, 'line 1 ' || str_osstat );
    utl_file.put_line(f, 'line 2 ' || str_osstat2 );
    utl_file.put_line(f, 'line 3 ' || str_osstat3 );
    utl_file.put_line(f, 'line 4 ' || str_osstat4 );

    -- close all
    utl_file.fclose(f);
    CLOSE cur_osstat;
    CLOSE cur_osstat_t2;
END;
/

