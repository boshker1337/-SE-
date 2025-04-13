-- 1. представление для просмотра предоставленных доступов по сотрудникам
create or replace view employee_access_view as
  select e.employee_id,
         e.first_name || ' ' || e.last_name as employee_name,
         d.name as department,
         count(ra.access_id) as access_count,
         sum(case when ra.is_manager_granted = 1 then 1 else 0 end) as manager_granted_count
    from employees e
    join departments d on e.department_id = d.department_id
    left join resource_access ra on e.employee_id = ra.employee_id
   group by e.employee_id, e.first_name, e.last_name, d.name
   order by access_count desc;

-- 2. представление для просмотра предоставленных доступов по ресурсам
create or replace view resource_access_view as
  select r.resource_id,
         r.title as resource_title,
         e.first_name || ' ' || e.last_name as owner_name,
         d.name as owner_department,
         count(ra.access_id) as access_count,
         sum(case when ra.is_manager_granted = 1 then 1 else 0 end) as manager_granted_count
    from resources r
    join employees e on r.owner_id = e.employee_id
    join departments d on e.department_id = d.department_id
    left join resource_access ra on r.resource_id = ra.resource_id
   group by r.resource_id, r.title, e.first_name, e.last_name, d.name
   order by access_count desc;

-- 3. сколько доступов раздал каждый сотрудник отдела (параметр: department_id)
select e.employee_id,
       e.first_name || ' ' || e.last_name as employee_name,
       count(ra.access_id) as granted_access_count
  from employees e
  left join resource_access ra on e.employee_id = ra.granted_by
 where e.department_id = :department_id
 group by e.employee_id, e.first_name, e.last_name
 order by granted_access_count desc;

-- 4. количество разданных доступов на другие отделы с названиями отделов (параметр: department_id)
select d.name as target_department,
       count(ra.access_id) as access_count
  from resource_access ra
  join employees e on ra.employee_id = e.employee_id
  join departments d on e.department_id = d.department_id
 where ra.granted_by in (select employee_id from employees where department_id = :department_id)
   and e.department_id != :department_id
 group by d.name
 order by access_count desc;

-- 5. сотрудники которым выдано более 3х доступов к ресурсам (параметр: department_id)
select e.employee_id,
       e.first_name || ' ' || e.last_name as employee_name,
       count(ra.access_id) as access_count
  from employees e
  join resource_access ra on e.employee_id = ra.employee_id
 where e.department_id = :department_id
 group by e.employee_id, e.first_name, e.last_name
having count(ra.access_id) > 3
 order by access_count desc;

-- 6. сотрудники отделов запретившие предоставлять им доступ с группировкой по отделам
select d.name as department,
       count(e.employee_id) as restricted_employees_count,
       listagg(e.first_name || ' ' || e.last_name, ', ') within group (order by e.last_name) as employees_list
  from employees e
  join departments d on e.department_id = d.department_id
 where e.allow_access = 0
 group by d.name
 order by restricted_employees_count desc;

-- 7. начальники отделов с названием отдела и их сотрудники и сколько доступов выдано каждому сотруднику
select d.name as department,
       m.first_name || ' ' || m.last_name as manager_name,
       e.first_name || ' ' || e.last_name as employee_name,
       count(ra.access_id) as access_count
  from departments d
  join employees m on d.manager_id = m.employee_id
  join employees e on d.department_id = e.department_id
  left join resource_access ra on e.employee_id = ra.employee_id
 group by d.name, m.first_name, m.last_name, e.first_name, e.last_name
 order by d.name, access_count desc;