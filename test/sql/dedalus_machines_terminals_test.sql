SET datestyle = 'ISO';
SET dedalus.api_key = 'My API Key';

SELECT *
FROM dedalus_machines_terminals.create(
  machine_id := 'dm-3', height := 0, width := 0
);

SELECT *
FROM dedalus_machines_terminals.retrieve(
  machine_id := 'dm-3', terminal_id := 'terminal_id'
);

SELECT *
FROM dedalus_machines_terminals.list(machine_id := 'dm-3')
LIMIT 42;

SELECT *
FROM dedalus_machines_terminals.delete(
  machine_id := 'dm-3', terminal_id := 'terminal_id'
);