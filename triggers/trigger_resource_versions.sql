create or replace trigger trg_resource_versions_bi
before insert on resource_versions
for each row
begin
    if :new.version_id is null then
        :new.version_id := resource_versions_seq.nextval;
    end if;
    if :new.created_at is null then
        :new.created_at := systimestamp;
    end if;
end;
/
