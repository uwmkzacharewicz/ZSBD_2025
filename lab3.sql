1. Utwórz widok v_wysokie_pensje, dla tabeli employees który pokaże wszystkich
pracowników zarabiających więcej niż 6000.

CREATE OR REPLACE VIEW v_wysokie_pensje AS
SELECT *
FROM employees
WHERE salary > 6000;

SELECT * FROM v_wysokie_pensje;


2. Zmień definicję widoku v_wysokie_pensje aby pokazywał tylko pracowników
zarabiających powyżej 12000.
CREATE OR REPLACE VIEW v_wysokie_pensje AS
SELECT *
FROM employees
WHERE salary > 12000;

SELECT * FROM v_wysokie_pensje;


3. Usuń widok v_wysokie_pensje.
DROP VIEW v_wysokie_pensje;


4. Stwórz widok dla tabeli employees zawierający: employee_id, last_name, first_name, dla
pracowników z departamentu o nazwie Finance
CREATE OR REPLACE VIEW v_finance_employees AS
SELECT e.employee_id, e.last_name, e.first_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = 'Finance';

SELECT * FROM v_finance_employees;


5. Stwórz widok dla tabeli employees zawierający: employee_id, last_name, first_name,
salary, job_id, email, hire_date dla pracowników mających zarobki pomiędzy 5000 a
12000.
CREATE OR REPLACE VIEW v_mid_salary_employees AS
SELECT employee_id, last_name, first_name, salary, job_id, email, hire_date
FROM employees
WHERE salary BETWEEN 5000 AND 12000;


SELECT * FROM v_mid_salary_employees;


6. Poprzez utworzone widoki sprawdź czy możesz:
a. dodać nowego pracownika
b. edytować pracownika
c. usunąć pracownika
INSERT INTO v_mid_salary_employees (employee_id, last_name, first_name, salary, job_id, email, hire_date)
VALUES (999, 'Test', 'User', 6000, 'DEV', 'test@gmail.com', SYSDATE);
 naruszono więzy spójności (INF2NS_ZACHAREWICZK.FK_EMPLOYEES_JOB) - nie znaleziono klucza nadrzędnego
 
7. Stwórz widok, który dla każdego działu który zatrudnia przynajmniej 4 pracowników
wyświetli: identyfikator działu, nazwę działu, liczbę pracowników w dziale, średnią
pensja w dziale i najwyższa pensja w dziale.
a. Sprawdź czy możesz dodać dane do tego widoku.

CREATE OR REPLACE VIEW v_department_summary AS
SELECT d.department_id,
       d.department_name,
       COUNT(e.employee_id) AS liczba_pracownikow,
       AVG(e.salary) AS srednia_pensja,
       MAX(e.salary) AS max_pensja
FROM departments d
JOIN employees e ON d.department_id = e.department_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(e.employee_id) >= 4;


8. Stwórz analogiczny widok zadania 3 z dodaniem warunku ‘WITH CHECK OPTION’.
a. Sprawdź czy możesz:
i. dodać pracownika z zarobkami pomiędzy 5000 a 12000.
ii. dodać pracownika z zarobkami powyżej 12000.
CREATE OR REPLACE VIEW v_mid_salary_employees_chk AS
SELECT employee_id, last_name, first_name, salary, job_id, email, hire_date
FROM employees
WHERE salary BETWEEN 5000 AND 12000
WITH CHECK OPTION;

INSERT INTO v_mid_salary_employees_chk (employee_id, last_name, first_name, salary, job_id, email, hire_date)
VALUES (1000, 'John', 'Smith', 6000, 'DEV', 'test@gmail.com', SYSDATE);

INSERT INTO v_mid_salary_employees_chk (employee_id, last_name, first_name, salary, job_id, email, hire_date)
VALUES (1001, 'Johny', 'Smithy', 13000, 'DEV', 'test1@gmail.com', SYSDATE);


9. Utwórz widok zmaterializowany v_managerowie, który pokaże tylko menedżerów w raz
z nazwami ich działów.

CREATE MATERIALIZED VIEW v_managerowie
BUILD IMMEDIATE
REFRESH COMPLETE
AS
SELECT m.employee_id, m.first_name, m.last_name, d.department_name
FROM employees m
JOIN departments d ON m.department_id = d.department_id
WHERE m.employee_id IN (
  SELECT DISTINCT manager_id FROM employees WHERE manager_id IS NOT NULL
);

SELECT * FROM v_managerowie;
10. Stwórz widok v_najlepiej_oplacani, który zawiera tylko 10 najlepiej opłacanych
pracowników

CREATE OR REPLACE VIEW v_najlepiej_oplacani AS
SELECT *
FROM (
    SELECT *
    FROM employees
    ORDER BY salary DESC
)
WHERE ROWNUM <= 10;


SELECT * FROM v_najlepiej_oplacani;