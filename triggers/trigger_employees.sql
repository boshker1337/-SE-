create or replace trigger trg_employees_bi
before insert on employees
for each row
begin
    if :new.employee_id is null then
        :new.employee_id := employees_seq.nextval;
    end if;
    :new.created_at := systimestamp;
end;
/

create or replace trigger trg_employees_bu
before update on employees
for each row
begin
    :new.updated_at := systimestamp;
end;
/
