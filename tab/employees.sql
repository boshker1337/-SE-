-- таблица сотрудников
create table employees (
    employee_id number primary key,
    first_name varchar2(50) not null,
    last_name varchar2(50) not null,
    department_id number references departments(department_id),
    allow_access number(1) default 1, -- 1 - разрешает доступ, 0 - запрещает
    created_at timestamp default systimestamp,
    updated_at timestamp
);

create index idx_employees_department on employees(department_id);
create index idx_employees_name on employees(last_name, first_name);
create index idx_employees_access on employees(allow_access);
