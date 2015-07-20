CREATE OR REPLACE PROCEDURE nrd_sp_memory_out (sleep_interval number)
is

l_os_ram_kb            number(16);
l_db_unique_name       varchar2(4000);
l_ora_directory        varchar2(4000);
l_sga_total_bytes      number(16);
l_sleep_interval       number;
l_dbid                 number;
l_dbname               varchar2(128);
l_inst_id_pga          number;
l_inst_id_pga_t2       number;
l_name_pga             varchar2(64);
l_name_pga_t2          varchar2(64);
l_name_pga_wk          varchar2(64);
l_workareaOpTypePGA    gv$sql_workarea_active.operation_type%type;
l_planLinePGA          number;
l_activeSecondsPGA     number;
l_actualMemUsedKBPGA   number;
l_maxMemUsedKBPGA      number;
l_workAreaSizeKBPGA    number;
l_numberPassesPGA      number;
l_tempsegSizeBytesPGA  number;
l_sql_id               gv$sql.sql_id%type;
l_sqltext              varchar2(4000);
l_value_pga            number;
l_value_pga_t2         number;
l_unit_pga             varchar2(12);
l_unit_pga_t2          varchar2(12);
l_inst_id_sga          number;
l_name_sga             varchar2(64);
l_bytes_sga            number;
l_interval             number;
i_inst_id              number;
l_inst_id_pga_out      number;

metric_date            varchar2(24);
f                      utl_file.file_type;
str_pga                varchar2(1000);
str_pga2               varchar2(1000);
str_pga3               varchar2(1000);
str_sga                varchar2(1000);


CURSOR cur_pga IS select inst_id instance, replace(name,' ','_') name , value, unit from gv$pgastat where name in ('aggregate PGA auto target','total PGA allocated','extra bytes read/written','global memory bound','over allocation count','process count','total PGA used for auto workareas','total PGA used for manual workareas') order by inst_id, name;

CURSOR cur_pga_t2 IS select inst_id instance, replace(name,' ','_') as name , value, unit from gv$pgastat where name in ('aggregate PGA auto target','total PGA allocated','extra bytes read/written','global memory bound','over allocation count','process count','total PGA used for auto workareas','total PGA used for manual workareas') order by inst_id, name;

CURSOR cur_pga_top_sqls IS
SELECT * from(
 SELECT
   swa.sql_id
  , swa.inst_id
  , swa.operation_type workareaOpType
  , swa.operation_id planLine
  , sum(ROUND(swa.active_time/1000000,1)) activeSeconds
  , sum(swa.actual_mem_used) actualMemUsed
  , max(swa.max_mem_used)  maxMemUsed
  , sum(swa.work_area_size) workAreaSize
  , sum(swa.number_passes) number_passes
  , sum(swa.tempseg_size) tempsegSize
  ,  replace( dbms_lob.substr(s.sql_fulltext,700,1) ,'"') sqltext
FROM
    gv$sql_workarea_active swa, gv$sql s
WHERE swa.sql_id = s.sql_id
      and swa.inst_id = s.inst_id
GROUP BY swa.sql_id, swa.inst_id, swa.operation_type, swa.operation_id,   replace( dbms_lob.substr(s.sql_fulltext,700,1) ,'"')
ORDER BY
  sum(work_area_size),
  max(max_mem_used))
where rownum < 20;

CURSOR cur_sga IS select inst_id, replace(name,' ','_') as name, bytes from gv$sgainfo where name in ('Buffer Cache Size','Shared Pool Size','Large Pool Size','Java Pool Size','Streams Pool Size','Free SGA Memory Available')  order by inst_id, name ;

BEGIN

-- init
EXECUTE IMMEDIATE 'alter session set nls_date_format=''mm/dd/yyyy hh24:mi:ss''';

l_os_ram_kb := 1;

l_sleep_interval := sleep_interval;

SELECT dbid, name into l_dbid, l_dbname from v$database;

SELECT value into l_db_unique_name from v$parameter where name='db_unique_name';

CASE l_db_unique_name
  WHEN 'DD547B_Y0319T1332' THEN
    l_ora_directory := 'DIR_SPLUNK1';
  WHEN 'DD547B_Y0319T1333' THEN
    l_ora_directory := 'DIR_SPLUNK2';
  ELSE
    l_ora_directory := 'DIR_SPLUNK';
END CASE;

f:=utl_file.fopen(l_ora_directory,'dbd_memory.txt','a',32767);

-- write a row in the text file for sga and pga stats for each instance

IF NOT cur_pga%ISOPEN THEN
   OPEN cur_pga;
END IF;

dbms_lock.sleep(l_sleep_interval);


SELECT sysdate into metric_date from dual;

IF NOT cur_pga_t2%ISOPEN THEN
   OPEN cur_pga_t2;
END IF;

IF NOT cur_pga_top_sqls%ISOPEN THEN
   OPEN cur_pga_top_sqls;
END IF;

IF NOT cur_sga%ISOPEN THEN
   OPEN cur_sga;
END IF;


i_inst_id:=0;

FETCH cur_pga into l_inst_id_pga, l_name_pga, l_value_pga, l_unit_pga;
FETCH cur_pga_t2 into l_inst_id_pga_t2, l_name_pga_t2, l_value_pga_t2, l_unit_pga_t2;
FETCH cur_sga into l_inst_id_sga, l_name_sga, l_bytes_sga;
   WHILE NOT  cur_pga%NOTFOUND
   LOOP
         -- if new instance print previous line and build the first part of the pga string
         IF l_inst_id_pga <> i_inst_id THEN
            IF i_inst_id > 0 THEN
              utl_file.put_line(f, str_pga || str_pga2 );
              utl_file.put_line(f, str_sga);
            END IF;

            str_pga := '';
            str_pga2 := '';
            str_sga := '';
         END IF;

         i_inst_id := l_inst_id_pga;

         CASE l_db_unique_name
         WHEN 'DD547B_Y0319T1332' THEN
            l_inst_id_pga_out := 1;
         WHEN 'DD547B_Y0319T1333' THEN
            l_inst_id_pga_out := 2;
         ELSE
            l_inst_id_pga_out := l_inst_id_pga;
         END CASE;

         SELECT sum(value) into l_sga_total_bytes from gv$sga where inst_id=l_inst_id_pga;

          -- build the first part of the string
          str_pga := 'metric_date="' || metric_date ||
                '", instance_id=' || to_char(l_inst_id_pga) ||
                ', dbid=' || l_dbid ||
                ', dbname=' || l_dbname ||
                ', host_ram_kb=' || l_os_ram_kb ||
                ', sga_total_bytes=' || l_sga_total_bytes ||
                ', ' || l_name_pga || '_' || l_unit_pga || '=' || to_char(l_value_pga) ;

          str_sga := 'metric_date="' || metric_date ||
                '", instance_id=' || to_char(l_inst_id_pga) ||
                ', dbid=' || l_dbid ||
                ', dbname=' || l_dbname ||
                ', host_ram_kb=' || l_os_ram_kb ||
                ', sga_total_bytes=' || l_sga_total_bytes || ' ';

        -- if same instance then add to the rest of the pga string and fetch next row
        WHILE l_inst_id_pga  = i_inst_id AND NOT  cur_pga%NOTFOUND
        LOOP
           IF l_name_pga = 'over_allocation_count' THEN
              l_value_pga := (l_value_pga_t2 - l_value_pga);
           END IF;

           IF l_name_pga = 'extra_bytes_read/written' THEN
              l_name_pga_wk := replace(l_name_pga,'/','_');
              l_name_pga := l_name_pga_wk;
              l_value_pga := (l_value_pga_t2 - l_value_pga);
           END IF;

           IF l_value_pga='' THEN
               l_value_pga := 0;
           END IF;

           str_pga2 :=  str_pga2 || ' ,' || l_name_pga || '_' || l_unit_pga || '=' || to_char(l_value_pga) ;

           FETCH cur_pga into l_inst_id_pga, l_name_pga, l_value_pga, l_unit_pga;
           FETCH cur_pga_t2 into l_inst_id_pga_t2, l_name_pga_t2, l_value_pga_t2, l_unit_pga_t2;
        END LOOP;

        -- Get the SGA info for the same instance

        LOOP
           IF l_inst_id_sga = i_inst_id THEN
           -- build the sga string
              str_sga := str_sga || ', ' || l_name_sga || '_bytes=' ||  to_char(l_bytes_sga);
           END IF;
           FETCH cur_sga into l_inst_id_sga, l_name_sga, l_bytes_sga;
           EXIT WHEN cur_sga%NOTFOUND OR l_inst_id_sga > i_inst_id;
        END LOOP;
      END LOOP;

    -- Print last line and close all
    utl_file.put_line(f, str_pga || str_pga2 );
    utl_file.put_line(f, str_sga);
    CLOSE cur_pga;
    CLOSE cur_sga;

    --  Get the high pga usage sqls
    FETCH cur_pga_top_sqls into l_sql_id, i_inst_id, l_workareaOpTypePGA, l_planLinePGA, l_activeSecondsPGA ,
          l_actualMemUsedKBPGA, l_maxMemUsedKBPGA, l_workAreaSizeKBPGA, 
          l_numberPassesPGA, l_tempsegSizeBytesPGA, l_sqltext;
    WHILE NOT cur_pga_top_sqls%NOTFOUND
    LOOP 
          str_pga3 := 'metric_date="' || metric_date ||
                '", instance_id=' || to_char(i_inst_id) ||
                ', dbid=' || l_dbid ||
                ', dbname=' || l_dbname ||
                ', workareaOpType="' || l_workareaOpTypePGA || '"' ||
                ', execPlanLine=' || l_planLinePGA ||
                ', activeSeconds=' || l_activeSecondsPGA ||
                ', actualMemUsedKB=' || l_actualMemUsedKBPGA ||
                ', maxMemUsedKB=' || l_maxMemUsedKBPGA ||
                ', workAreaSizeKB=' || l_workAreaSizeKBPGA ||
                ', numberPasses=' || l_numberPassesPGA ||
                ', tempsegSizeBytes=' || l_tempsegSizeBytesPGA ||
                ', sql_id=' || l_sql_id ||
                ', sqltext="' || l_sqltext || '"';
         utl_file.put_line(f, str_pga3); 
                
         FETCH cur_pga_top_sqls into l_sql_id, i_inst_id, l_workareaOpTypePGA, l_planLinePGA, l_activeSecondsPGA ,
             l_actualMemUsedKBPGA, l_maxMemUsedKBPGA, l_workAreaSizeKBPGA, 
             l_numberPassesPGA, l_tempsegSizeBytesPGA, l_sqltext ;
    END LOOP;

    utl_file.fclose(f);
    CLOSE cur_pga_top_sqls;
     
END;
/
