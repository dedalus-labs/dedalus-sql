SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_machines_ssh.create(
  machine_id := 'dm-3', public_key := 'public_key'
);

SELECT *
FROM dedalus_machines_ssh.retrieve(
  machine_id := 'dm-3', session_id := 'session_id'
);

SELECT *
FROM dedalus_machines_ssh.list(machine_id := 'dm-3')
LIMIT 42;

SELECT *
FROM dedalus_machines_ssh.delete(
  machine_id := 'dm-3', session_id := 'session_id'
);