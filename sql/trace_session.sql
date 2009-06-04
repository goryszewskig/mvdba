-- ALTER SESSION SET optimizer_index_cost_adj=1
-- ALTER SESSION SET "_push_join_predicate_" = TRUE

SELECT /*+ choose */ s.status   "Status"
     , si.sid
     , s.serial#                "Serial#"
     , si.physical_reads        "Physical Reads"
     , si.consistent_gets       "Consistent Gets"
     , si.block_gets            "Block Gets"
     , s.module                 "Module"
     , s.logon_time             "Connect Time"
     , w.event
     , area.sql_text
     , p.pid                           -- oracle internal pid (v$process)
     , p.spid                          -- server os pid
     , s.action
     , si.block_changes         "Block Changes"
     , si.consistent_changes    "Consistent Changes"
     , s.process                "CPID" -- client os pid
      ,s.username               "DB User"
     , s.osuser                 "Client User"
     , s.sql_address            "Address"
     , s.sql_hash_value         "Sql Hash"
     , lockwait                 "Lock Wait"
     , s.audsid
     , s.program                "Client Program"
     , p.program                "Server Program"
     , s.machine                "Machine"
--   , s.terminal               "Terminal"
--   , s.client_info            "Client Info"
  FROM v$session        s
     , v$process        p
     , sys.v_$sess_io   si
     , v$sqlarea        area
     , v$session_wait   w
 WHERE s.paddr   = p.addr(+)
   AND si.sid(+) = s.sid
   AND w.sid(+)  = s.sid
   AND (s.sql_address    = area.address AND
        s.sql_hash_value = area.hash_value)
-- AND s.status = 'ACTIVE'
   AND s.audsid <> USERENV('SESSIONID')
-- and (area.sql_text like '%delete%' or area.sql_text like '%DELETE%')
 ORDER BY s.status
        , si.physical_reads DESC 
     -- , area.sql_TEXT --
     ;

