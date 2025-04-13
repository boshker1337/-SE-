create or replace trigger trg_resource_category_mapping_bi
before insert on resource_category_mapping
for each row
begin
    if :new.mapping_id is null then
        :new.mapping_id := resource_category_mapping_seq.nextval;
    end if;
    if :new.assigned_at is null then
        :new.assigned_at := systimestamp;
    end if;
end;
/
