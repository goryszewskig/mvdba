select syn.synonym_name
     , syn.db_link
     , obj.object_type
     , obj.* 
  from user_synonyms syn
     , all_objects   obj
 where syn.table_owner = obj.owner (+)
   and syn.table_name  = obj.object_name (+)
 order by syn.synonym_name
        , obj.object_type
        , obj.object_name
     ;
