create or replace trigger trg_resources_bi
before insert on resources
for each row
begin
    if :new.resource_id is null then
        :new.resource_id := resources_seq.nextval;
    end if;
    :new.created_at := systimestamp;
end;
/

create or replace trigger trg_resources_bu
before update on resources
for each row
begin
    :new.updated_at := systimestamp;
end;
/
