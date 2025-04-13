create or replace trigger trg_departments_bi
before insert on departments
for each row
begin
    if :new.department_id is null then
        :new.department_id := departments_seq.nextval;
    end if;
end;
/
