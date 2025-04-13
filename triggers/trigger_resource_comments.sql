create or replace trigger trg_resource_comments_bi
before insert on resource_comments
for each row
begin
    if :new.comment_id is null then
        :new.comment_id := resource_comments_seq.nextval;
    end if;
    :new.created_at := systimestamp;
end;
/

create or replace trigger trg_resource_comments_bu
before update on resource_comments
for each row
begin
    :new.updated_at := systimestamp;
end;
/
