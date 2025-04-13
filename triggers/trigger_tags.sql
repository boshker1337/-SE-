create or replace trigger trg_tags_bi
before insert on tags
for each row
begin
    if :new.tag_id is null then
        :new.tag_id := tags_seq.nextval;
    end if;
end;
/
