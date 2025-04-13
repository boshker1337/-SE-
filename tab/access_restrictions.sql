-- таблица запретов доступа (если сотрудник запретил доступ конкретным людям)
create table access_restrictions (
    restriction_id number primary key,
    employee_id number not null references employees(employee_id),
    restricted_employee_id number not null references employees(employee_id),
    created_at timestamp default systimestamp
);

create index idx_access_restrictions_emp on access_restrictions(employee_id);
create index idx_access_restrictions_restricted on access_restrictions(restricted_employee_id);
create index idx_access_restrictions_composite on access_restrictions(employee_id, restricted_employee_id);
