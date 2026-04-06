CREATE TABLE secret_data (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50),
  credit_card VARCHAR(20),
  salary INTEGER
);

INSERT INTO secret_data VALUES
  (1, 'alice',   '4111-1111-1111-1111', 95000),
  (2, 'bob',     '5500-0000-0000-0004', 87000),
  (3, 'charlie', '3782-8224-6310-005',  110000);
