create or replace trigger trg_resource_access_bi
before insert on resource_access
for each row
begin
    if :new.access_id is null then
        :new.access_id := resource_access_seq.nextval;
    end if;
    if :new.granted_at is null then
        :new.granted_at := systimestamp;
    end if;
end;
/
