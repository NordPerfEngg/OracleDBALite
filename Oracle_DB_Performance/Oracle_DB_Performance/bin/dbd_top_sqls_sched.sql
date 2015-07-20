BEGIN
DBMS_SCHEDULER.create_program (
    program_name        => 'sch_spl.dbd_top_sqls_pgm',
    program_type        => 'STORED_PROCEDURE',
    program_action      => 'sch_spl.nrd_sp_top_sqls',
    number_of_arguments => 0,
    enabled             => FALSE,
    comments            => 'QES splunk dashboard job - top_sqls');



DBMS_SCHEDULER.ENABLE('sch_spl.dbd_top_sqls_pgm');


-- Job defined by existing program and inline schedule.
  DBMS_SCHEDULER.create_job (
    job_name        => 'sch_spl.dbd_top_sqls_job',
    program_name    => 'sch_spl.dbd_top_sqls_pgm',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=30',
    end_date        => NULL,
    enabled         => FALSE,
    comments        => 'Splunk QES Dashboard job - top_sqls');

dbms_scheduler.set_attribute( name => 'DBD_TOP_SQLS_JOB', attribute => 'restartable', value => TRUE);

dbms_scheduler.enable(name=>'sch_spl.dbd_top_sqls_job');
END;
/
