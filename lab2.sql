-- Usuń wszystkie tabele ze swojej bazy
DECLARE
  CURSOR c_tables IS
    SELECT table_name FROM user_tables; -- Pobiera wszystkie tabele użytkownika
  v_sql VARCHAR2(1000);
BEGIN
  FOR rec IN c_tables LOOP
    v_sql := 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS PURGE'; 
    EXECUTE IMMEDIATE v_sql;
  END LOOP;
END;
/

-- Przekopiuj wszystkie tabele wraz z danymi od użytkownika HR.
-- Poustawiaj klucze główne i obce

DECLARE
  CURSOR c_tables IS
    SELECT table_name FROM all_tables WHERE owner = 'HR';
  v_sql VARCHAR2(1000);
BEGIN
  FOR rec IN c_tables LOOP
    v_sql := 'CREATE TABLE ' || rec.table_name || ' AS SELECT * FROM HR.' || rec.table_name;
    EXECUTE IMMEDIATE v_sql;
  END LOOP;
END;
/



ALTER TABLE REGIONS ADD CONSTRAINT regions_pk PRIMARY KEY (region_id);
ALTER TABLE COUNTRIES ADD CONSTRAINT countries_pk PRIMARY KEY (country_id);
ALTER TABLE LOCATIONS ADD CONSTRAINT locations_pk PRIMARY KEY (location_id);
ALTER TABLE DEPARTMENTS ADD CONSTRAINT departments_pk PRIMARY KEY (department_id);
ALTER TABLE JOB_HISTORY ADD CONSTRAINT job_history_pk PRIMARY KEY (employee_id, start_date);
ALTER TABLE JOBS ADD CONSTRAINT jobs_pk PRIMARY KEY (job_id);
ALTER TABLE EMPLOYEES ADD CONSTRAINT employees_pk PRIMARY KEY (employee_id);



ALTER TABLE COUNTRIES
ADD CONSTRAINT fk_coutries_regions
FOREIGN KEY (region_id)
REFERENCES REGIONS(region_id)
ON DELETE SET NULL;  -- przy usunieciu region, w coutries ustawi sie null

ALTER TABLE LOCATIONS 
ADD CONSTRAINT fk_locations_country 
FOREIGN KEY (country_id) 
REFERENCES COUNTRIES(country_id) 
ON DELETE SET NULL;

-- DEPARTMENTS -> LOCATIONS 
ALTER TABLE DEPARTMENTS 
ADD CONSTRAINT fk_departments_location 
FOREIGN KEY (location_id) 
REFERENCES LOCATIONS(location_id) 
ON DELETE SET NULL;


-- EMPLOYEES -> JOBS
ALTER TABLE EMPLOYEES 
ADD CONSTRAINT fk_employees_job 
FOREIGN KEY (job_id) 
REFERENCES JOBS(job_id) 
ON DELETE CASCADE;

-- EMPLYEES -> EMPLOYEES, rekurencyjna
ALTER TABLE EMPLOYEES 
ADD CONSTRAINT fk_employees_manager 
FOREIGN KEY (manager_id) 
REFERENCES EMPLOYEES(employee_id) 
ON DELETE SET NULL;

-- EMPLOYEES -> DEPARTMENTS
ALTER TABLE EMPLOYEES 
ADD CONSTRAINT fk_employees_department 
FOREIGN KEY (department_id) 
REFERENCES DEPARTMENTS(department_id) 
ON DELETE SET NULL;


-- JOB_HISTORY -> EMPLOYEES (employee_id)  
ALTER TABLE JOB_HISTORY
ADD CONSTRAINT fk_jobhistory_employee
FOREIGN KEY (employee_id)
REFERENCES EMPLOYEES(employee_id)
ON DELETE CASCADE;  -- po usunieciu praciownika, cały ślad po nim zostanie usunięcty

-- JOB_HISTORY -> JOBS (job_id)
ALTER TABLE JOB_HISTORY 
ADD CONSTRAINT fk_jobhistory_job 
FOREIGN KEY (job_id) 
REFERENCES JOBS(job_id) 
ON DELETE CASCADE;

-- JOB_HISTORY -> DEPARTMENTS (department_id)
ALTER TABLE JOB_HISTORY 
ADD CONSTRAINT fk_jobhistory_department 
FOREIGN KEY (department_id) 
REFERENCES DEPARTMENTS(department_id) 
ON DELETE CASCADE;


--  Z tabeli EMPLOYEES – nazwisko i zarobki w jednej kolumnie (alias „wynagrodzenie”) dla departamentów 20 i 50, zarobki między 2000 a 7000, posortowane według nazwiska
SELECT last_name || ' ' || salary AS wynagrodzenie
FROM EMPLOYEES
WHERE department_id IN (20, 50)
  AND salary BETWEEN 2000 AND 7000
ORDER BY last_name;

-- Z tabeli EMPLOYEES – data zatrudnienia, nazwisko oraz kolumna podana przez użytkownika, dla osób z menedżerem zatrudnionych w 2005, uporządkowane według kolumny podanej przez użytkownika
SELECT hire_date, last_name, &kolumna
FROM EMPLOYEES
WHERE manager_id IS NOT NULL
  AND EXTRACT(YEAR FROM hire_date) = 2005
ORDER BY &kolumna;

-- Imiona i nazwiska (połączone w jedną kolumnę), zarobki oraz numer telefonu – uporządkowane według pierwszej kolumny malejąco i drugiej rosnąco – dla osób, u których trzecia litera nazwiska to 'e' oraz imię zawiera fragment podany przez użytkownika
SELECT first_name || ' ' || last_name AS full_name,
       salary,
       phone_number
FROM EMPLOYEES
WHERE SUBSTR(last_name, 3, 1) = 'e'
  AND first_name LIKE '%' || '&fragment_imienia' || '%'
ORDER BY 1 DESC, 2 ASC;

-- Imię, nazwisko, liczba miesięcy przepracowanych (przy użyciu MONTHS_BETWEEN i ROUND) oraz kolumna wysokość_dodatku, wyliczana według
-- 10% wynagrodzenia dla liczby miesięcy < 150
-- 20% wynagrodzenia dla miesięcy od 150 do 200
-- 30% wynagrodzenia dla miesięcy ≥ 200
Uporządkowane według liczby miesięcy
SELECT first_name,
       last_name,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) AS miesiace_pracy,
       CASE 
         WHEN ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) < 150 THEN salary * 0.10
         WHEN ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) BETWEEN 150 AND 200 THEN salary * 0.20
         ELSE salary * 0.30
       END AS wysokosc_dodatku
FROM EMPLOYEES
ORDER BY miesiace_pracy;

-- Dla każdego działu, w którym minimalna płaca > 5000 – wypisz sumę i średnią zarobków (średnia zaokrąglona do całości)
SELECT department_id,
       SUM(salary) AS suma_zarobkow,
       ROUND(AVG(salary)) AS srednia_zarobkow
FROM EMPLOYEES
GROUP BY department_id
HAVING MIN(salary) > 5000;

-- Dla każdego działu, w którym minimalna płaca > 5000 – wypisz sumę i średnią zarobków (średnia zaokrąglona do całości)
SELECT department_id,
       SUM(salary) AS suma_zarobkow,
       ROUND(AVG(salary)) AS srednia_zarobkow
FROM EMPLOYEES
GROUP BY department_id
HAVING MIN(salary) > 5000;

-- Nazwisko, numer departamentu, nazwę departamentu oraz id pracy – dla osób pracujących w Toronto
SELECT e.last_name,
       e.department_id,
       d.department_name,
       e.job_id
FROM EMPLOYEES e
JOIN DEPARTMENTS d ON e.department_id = d.department_id
JOIN LOCATIONS l ON d.location_id = l.location_id
WHERE l.city = 'Toronto';

--  Dla pracowników o imieniu „Jennifer” – wypisz imię i nazwisko tego pracownika oraz osoby, które z nim współpracują (tzn. pracują w tym samym dziale)
SELECT e1.first_name || ' ' || e1.last_name AS jennifer,
       e2.first_name || ' ' || e2.last_name AS wspolpracownik
FROM EMPLOYEES e1
JOIN EMPLOYEES e2 ON e1.department_id = e2.department_id
WHERE e1.first_name = 'Jennifer'
  AND e2.employee_id <> e1.employee_id;

-- Wypisz wszystkie departamenty, w których nie ma pracowników
SELECT d.department_name
FROM DEPARTMENTS d
LEFT JOIN EMPLOYEES e ON d.department_id = e.department_id
WHERE e.employee_id IS NULL;

-- Dla każdego pracownika – imię, nazwisko, id pracy, nazwę departamentu, zarobki oraz odpowiedni grade (np. przydzielony za pomocą CASE)
SELECT e.first_name,
       e.last_name,
       e.job_id,
       d.department_name,
       e.salary,
       CASE 
         WHEN e.salary < 3000 THEN 'Grade C'
         WHEN e.salary BETWEEN 3000 AND 6000 THEN 'Grade B'
         ELSE 'Grade A'
       END AS grade
FROM EMPLOYEES e
LEFT JOIN DEPARTMENTS d ON e.department_id = d.department_id;


-- Imię, nazwisko i zarobki dla osób zarabiających więcej niż średnia wszystkich – uporządkowane malejąco według zarobków
SELECT first_name, last_name, salary
FROM EMPLOYEES
WHERE salary > (SELECT AVG(salary) FROM EMPLOYEES)
ORDER BY salary DESC;

-- Wypisz id, imię i nazwisko osób pracujących w departamencie, w którym występuje osoba mająca w nazwisku literę „u”
SELECT employee_id, first_name, last_name
FROM EMPLOYEES
WHERE department_id IN (
    SELECT department_id
    FROM EMPLOYEES
    WHERE last_name LIKE '%u%'
);

-- Znajdź pracowników, którzy pracują dłużej niż średnia długość zatrudnienia w firmie
SELECT first_name, last_name, hire_date,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) AS miesiace_pracy
FROM EMPLOYEES
WHERE ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) > (
    SELECT AVG(ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)))
    FROM EMPLOYEES
);

-- Znajdź pracowników, którzy pracują dłużej niż średnia długość zatrudnienia w firmie
SELECT first_name, last_name, hire_date,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) AS miesiace_pracy
FROM EMPLOYEES
WHERE ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) > (
    SELECT AVG(ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)))
    FROM EMPLOYEES
);

-- Dla każdego departamentu – nazwę departamentu, liczbę pracowników oraz średnie wynagrodzenie, uporządkowane według liczby pracowników malejąco
SELECT d.department_name,
       COUNT(e.employee_id) AS liczba_pracownikow,
       AVG(e.salary) AS srednie_wynagrodzenie
FROM DEPARTMENTS d
LEFT JOIN EMPLOYEES e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY liczba_pracownikow DESC;


-- Wypisz imiona i nazwiska pracowników, którzy zarabiają mniej niż każdy pracownik w departamencie „IT”
SELECT first_name, last_name, salary
FROM EMPLOYEES
WHERE salary < (SELECT MIN(salary) 
                FROM EMPLOYEES 
                WHERE department_id = (SELECT department_id 
                                         FROM DEPARTMENTS 
                                         WHERE department_name = 'IT'));
-- Znajdź departamenty, w których pracuje co najmniej jeden pracownik zarabiający więcej niż średnia pensja w całej firmie

-- Wypisz pięć najlepiej opłacanych stanowisk pracy wraz ze średnimi zarobkami
SELECT job_id, AVG(salary) AS srednia_zarobkow
FROM EMPLOYEES
GROUP BY job_id
ORDER BY srednia_zarobkow DESC
FETCH FIRST 5 ROWS ONLY;

-- Dla każdego regionu – wypisz nazwę regionu, liczbę krajów oraz liczbę pracowników pracujących w tym regionie
-- Podaj imiona i nazwiska pracowników, którzy zarabiają więcej niż ich menedżerowie
-- Policz, ilu pracowników zaczęło pracę w każdym miesiącu (bez względu na rok)
SELECT TO_CHAR(hire_date, 'MM') AS miesiac,
       COUNT(*) AS liczba_pracownikow
FROM EMPLOYEES
GROUP BY TO_CHAR(hire_date, 'MM')
ORDER BY miesiac;

-- Znajdź trzy departamenty z najwyższą średnią pensją i wypisz ich nazwę oraz średnie wynagrodzenie
SELECT d.department_name, AVG(e.salary) AS srednia_wynagrodzenie
FROM DEPARTMENTS d
JOIN EMPLOYEES e ON d.department_id = e.department_id
GROUP BY d.department_name
ORDER BY srednia_wynagrodzenie DESC
FETCH FIRST 3 ROWS ONLY;