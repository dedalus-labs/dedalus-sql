SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_machines_previews.create(machine_id := 'dm-3', port := 0);

SELECT *
FROM dedalus_machines_previews.retrieve(
  machine_id := 'dm-3', preview_id := 'preview_id'
);

SELECT *
FROM dedalus_machines_previews.list(machine_id := 'dm-3')
LIMIT 42;

SELECT *
FROM dedalus_machines_previews.delete(
  machine_id := 'dm-3', preview_id := 'preview_id'
);