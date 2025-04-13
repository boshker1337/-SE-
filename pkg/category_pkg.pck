create or replace package category_pkg as
/*****************************************/
/*Пакет для работы с категориями ресурсов*/
/*****************************************/
  -- создание категории
  procedure create_category(pName in varchar2, pDescription in varchar2 default null, pCategoryId out number);
    
  -- обновление категории
  procedure update_category(pCategoryId in number, pName in varchar2, pDescription in varchar2 default null);
    
  -- удаление категории
  procedure delete_category(pCategoryId in number);
    
  -- получение списка категорий
  function get_categories_list return sys_refcursor;
    
  -- получение ресурсов в категории
  function get_category_resources(pCategoryId in number) return sys_refcursor;
end;

/
create or replace package body category_pkg as
/*****************************************/
/*Пакет для работы с категориями ресурсов*/
/*****************************************/
  procedure create_category(pName in varchar2, pDescription in varchar2 default null, pCategoryId out number) is
  begin
    pCategoryId := resource_categories_seq.nextval;
    insert into resource_categories (category_id, name, description)
                             values (pCategoryId, pName, pDescription);
        
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'create', 'category', pCategoryId, null, 'created new category: '||pName);
  end;
    
  procedure update_category(pCategoryId in number, pName in varchar2, pDescription in varchar2 default null) is
  begin
    update resource_categories
       set name = pName,
           description = pDescription
     where category_id = pCategoryId;
        
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'update', 'category', pCategoryId, null, 'category updated');
  end;
    
  procedure delete_category(pCategoryId in number) is
    vCount number;
  begin
    -- проверяем, используется ли категория
    select count(*) into vCount
      from resource_category_mapping
     where category_id = pCategoryId;
        
    if vCount > 0 then
      raise_application_error(-20022, 'category is in use and cannot be deleted');
    end if;
        
    -- удаляем категорию
    delete from resource_categories
     where category_id = pCategoryId;
        
    -- логирование
    insert into logs (log_id, action_type, entity_type, entity_id, performed_by, details)
              values (app_logs_seq.nextval, 'delete', 'category', pCategoryId, null, 'category deleted');
  end;
    
  function get_categories_list return sys_refcursor is
    vCursor sys_refcursor;
  begin
    open vCursor for
      select c.category_id, c.name, c.description,
             (select count(*) 
                from resource_category_mapping cm 
               where cm.category_id = c.category_id) as resources_count
        from resource_categories c
       order by c.name;
        
    return vCursor;
  end;
    
  function get_category_resources(pCategoryId in number) return sys_refcursor is
    vCursor sys_refcursor;
  begin
    open vCursor for
      select r.resource_id, r.title, 
             e.first_name||' '||e.last_name as owner_name,
             r.created_at
        from resources r
        join employees e on r.owner_id = e.employee_id
        join resource_category_mapping cm on r.resource_id = cm.resource_id
       where cm.category_id = pCategoryId
      order by r.created_at desc;
        
    return vCursor;
  end;

begin
  null;
end;
/
