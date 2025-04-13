create or replace trigger trg_resource_tags_bi
before insert on resource_tags
for each row
begin
    if :new.resource_tag_id is null then
        :new.resource_tag_id := resource_tags_seq.nextval;
    end if;
    if :new.assigned_at is null then
        :new.assigned_at := systimestamp;
    end if;
end;
/
