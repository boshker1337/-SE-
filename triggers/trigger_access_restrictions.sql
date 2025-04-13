create or replace trigger trg_access_restrictions_bi
before insert on access_restrictions
for each row
begin
    if :new.restriction_id is null then
        :new.restriction_id := access_restrictions_seq.nextval;
    end if;
    if :new.created_at is null then
        :new.created_at := systimestamp;
    end if;
end;
/
