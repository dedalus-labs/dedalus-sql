SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_machines_artifacts.retrieve(
  machine_id := 'dm-3', artifact_id := 'artifact_id'
);

SELECT *
FROM dedalus_machines_artifacts.list(machine_id := 'dm-3')
LIMIT 42;

SELECT *
FROM dedalus_machines_artifacts.delete(
  machine_id := 'dm-3', artifact_id := 'artifact_id'
);