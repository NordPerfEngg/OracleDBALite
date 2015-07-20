BEGIN
DBMS_SCHEDULER.create_program (
    program_name        => 'sch_spl.dbd_osstat_pgm',
    program_type        => 'STORED_PROCEDURE',
    program_action      => 'sch_spl.nrd_sp_osstat',
    number_of_arguments => 1,
    enabled             => FALSE,
    comments            => 'QES splunk dashboard job - osstat');


DBMS_SCHEDULER.define_program_argument (
                                       program_name      => 'sch_spl.dbd_osstat_pgm',
                                       argument_name     => 'sleep_interval',
                                       argument_position => 1,
                                       argument_type     => 'NUMBER',
                                       default_value     => 300);

DBMS_SCHEDULER.ENABLE('sch_spl.dbd_osstat_pgm');

-- Job defined by existing program and inline schedule.
  DBMS_SCHEDULER.create_job (
    job_name        => 'sch_spl.dbd_osstat_job',
    program_name    => 'sch_spl.dbd_osstat_pgm',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY; INTERVAL=5',
    end_date        => NULL,
    enabled         => FALSE,
    comments        => 'Splunk QES Dashboard job - osstat');

dbms_scheduler.set_attribute( name => 'DBD_OSSTAT_JOB', attribute => 'restartable', value => TRUE);

dbms_scheduler.set_job_argument_value(job_name => 'sch_spl.dbd_osstat_job',
                                      argument_position => 1,
                                      argument_value    => 300);
dbms_scheduler.enable(name=>'sch_spl.dbd_osstat_job');
END;
/
