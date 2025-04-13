--Небольшой тест "приложения"

-- 1. Создаем иерархию отделов
declare
    vDeptId1 number;
    vDeptId2 number;
    vEmpId number;
    vEmpId2 number;
begin
    -- создаем главный отдел
    department_pkg.add_department('главный офис', vEmpId, vDeptId1);
    commit;
    employee_pkg.add_employee('алексей', 'сидоров', vDeptId1, vEmpId);
    update employees set department_id = vDeptId1 where employee_id = vEmpId;
    commit;
    -- создаем подчиненный отдел
    department_pkg.add_child_department('it отдел', vEmpId2, vDeptId1, vDeptId2);
    commit;
    employee_pkg.add_employee('мария', 'петрова', vDeptId2, vEmpId2);
    commit;
end;

-- 2. Создаем категории и теги
declare
    vCatId number;
    vTagId number;
begin
    category_pkg.create_category('техническая документация', 'документы по продуктам', vCatId);
    category_pkg.create_category('внутренние регламенты', 'правила компании', vCatId);
    
    resource_pkg.create_tag('важно', vTagId);
    resource_pkg.create_tag('черновик', vTagId);
end;

-- 3. Работа с версиями ресурса
declare
    vResId number;
    vEmpId number;
    vCatId number;
    vTagId number;
begin
    select employee_id into vEmpId from employees where rownum = 1;
    
    -- создаем ресурс
    resource_pkg.add_resource('руководство пользователя', vEmpId, vResId);
    
    -- добавляем версию
    resource_pkg.create_resource_version(vResId, 'руководство пользователя v1', 'полное руководство для новых пользователей...', vEmpId);
    
    --Создаём категорию и тег
    category_pkg.create_category('техническая документация', 'документы по продуктам', vCatId);
    resource_pkg.create_tag('важно', vTagId);
    
    -- добавляем категорию и тег
    resource_pkg.add_resource_category(vResId, vCatId, vEmpId);
    resource_pkg.add_tag_to_resource(vResId, vTagId, vEmpId);
end;

-- 4. Поиск ресурсов
declare
    vCursor sys_refcursor;
    vResId number;
    vTitle varchar2(255);
    vOwner varchar2(200);
    vCreated timestamp;
begin
    vCursor := resource_pkg.search_resources(pSearchText => 'руководство', pCategoryId => 13);
    
    loop
        fetch vCursor into vResId, vTitle, vOwner, vCreated;
        exit when vCursor%notfound;
        dbms_output.put_line('найдено: '||vTitle||', владелец: '||vOwner);
    end loop;
    
    close vCursor;
end;
