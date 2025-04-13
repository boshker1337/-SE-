create or replace trigger trg_resource_files_bi
before insert on resource_files
for each row
begin
    if :new.file_id is null then
        :new.file_id := resource_files_seq.nextval;
    end if;
    if :new.uploaded_at is null then
        :new.uploaded_at := systimestamp;
    end if;
end;
/
