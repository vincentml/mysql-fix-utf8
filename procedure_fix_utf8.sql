/* 
This fix_utf8 procedure runs the MySQl steps described in this article on all tables and columns in the specified database:
"Getting out of MySQL Character Set Hell"
http://www.bluebox.net/about/blog/2009/07/mysql_encoding/

call fix_utf8('database');
*/

set names utf8mb4;
drop procedure if exists fix_utf8;
delimiter @@

create procedure fix_utf8 (in schema_name varchar(64))
begin
declare tbl_name, col_name, col_type varchar(64);
declare no_more_tables boolean default false;
declare tbl_cur cursor for select table_name from information_schema.tables where table_schema = schema_name;
declare continue handler for not found set no_more_tables := true;
open tbl_cur;
loopt: loop
  fetch tbl_cur into tbl_name;
  if no_more_tables then
    close tbl_cur;
    leave loopt;
  end if;
  blockc: begin
    declare no_more_columns boolean default false;
    declare col_cur cursor for select column_name, column_type from information_schema.columns
      where table_name = tbl_name
      and table_schema = schema_name
      and ( column_type like 'varchar%' or column_type like '%text%')
      -- and not column_name like '%id'
      -- and not (column_name = 'password' and table_name = 'people')
      ;
      -- if needed, the above query can be modified to exclude specific columns
    declare continue handler for not found set no_more_columns := true;
    open col_cur;
    loopc: loop
      fetch col_cur into col_name, col_type;
      if no_more_columns then
        close col_cur;
        leave loopc;
      end if;
      -- select tbl_name, col_name, col_type;
      
      set @dyn = concat('create table temp_fixutf8 (select * from `', tbl_name, '` where length(`', col_name, '`) != char_length(`', col_name, '`));');
      prepare stmt from @dyn;
      execute stmt;
      deallocate prepare stmt;
      
      set @dyn = concat('alter table temp_fixutf8 modify `', col_name, '` ', col_type, ' character set latin1;');
      prepare stmt from @dyn;
      execute stmt;
      deallocate prepare stmt;
      
      set @dyn = concat('alter table temp_fixutf8 modify `', col_name, '` blob;');
      prepare stmt from @dyn;
      execute stmt;
      deallocate prepare stmt;
      
      set @dyn = concat('alter table temp_fixutf8 modify `', col_name, '` ', col_type, ' character set utf8mb4;');
      prepare stmt from @dyn;
      execute stmt;
      deallocate prepare stmt;
      
      set @dyn = concat('delete from temp_fixutf8 where length(`', col_name, '`) = char_length(`', col_name, '`);');
      prepare stmt from @dyn;
      execute stmt;
      deallocate prepare stmt;
      
      set @dyn = concat('replace into `', tbl_name, '` (select * from temp_fixutf8);');
      prepare stmt from @dyn;
      execute stmt;
      deallocate prepare stmt;
      
      set @dyn = concat('drop table temp_fixutf8;');
      prepare stmt from @dyn;
      execute stmt;
      deallocate prepare stmt;
      
      
    end loop loopc;
  end blockc;
end loop loopt;
end;
@@
delimiter ;

