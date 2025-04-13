-- таблица отделов
create table departments (
    department_id number primary key,
    name varchar2(100) not null,
    manager_id number, -- начальник отдела (ссылка на сотрудника)
    parent_id number references departments(department_id)
);

create index idx_departments_manager on departments(manager_id);
create index idx_departments_parent on departments(parent_id);
