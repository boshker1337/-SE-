create or replace trigger trg_resource_categories_bi
before insert on resource_categories
for each row
begin
    if :new.category_id is null then
        :new.category_id := resource_categories_seq.nextval;
    end if;
end;
/
