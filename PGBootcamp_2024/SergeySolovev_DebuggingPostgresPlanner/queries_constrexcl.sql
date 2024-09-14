-- Schema `schema_constrexpr.sql`

EXPLAIN ANALYZE 
SELECT * FROM tbl1 
WHERE value > 0 
      AND 
      value <= 0;


EXPLAIN ANALYZE 
SELECT * FROM tbl1 t1 
JOIN tbl2 t2 
   ON t1.value > 0 
WHERE t1.value <= 0;


EXPLAIN ANALYZE
SELECT * FROM generate_series(1, 100) g(value)
WHERE value > 0
      AND
      value <= 0;
