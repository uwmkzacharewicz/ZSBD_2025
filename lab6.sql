Stwórz funkcje:
1. Zwracającą nazwę pracy dla podanego parametru id, dodaj wyjątek, jeśli taka praca nie
istnieje
CREATE OR REPLACE FUNCTION fn_get_job_title(
  p_job_id IN jobs.job_id%TYPE
) RETURN VARCHAR2 IS
  v_title jobs.job_title%TYPE;
  e_not_found EXCEPTION;
BEGIN
  SELECT job_title
    INTO v_title
    FROM jobs
   WHERE job_id = p_job_id;
  RETURN v_title;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20010, 'Job ID '||p_job_id||' not found');
END fn_get_job_title;
/

SELECT fn_get_job_title('IT_PROG') FROM dual;
2. zwracającą roczne zarobki (wynagrodzenie 12-to miesięczne plus premia jako
wynagrodzenie * commission_pct) dla pracownika o podanym id
CREATE OR REPLACE FUNCTION fn_annual_compensation(
  p_emp_id IN employees.employee_id%TYPE
) RETURN NUMBER IS
  v_salary       employees.salary%TYPE;
  v_commission   employees.commission_pct%TYPE;
BEGIN
  SELECT salary, NVL(commission_pct,0)
    INTO v_salary, v_commission
    FROM employees
   WHERE employee_id = p_emp_id;
  RETURN v_salary*12 + (v_salary * v_commission);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20011, 'Employee ID '||p_emp_id||' not found');
END fn_annual_compensation;
/

SELECT fn_annual_compensation(100) FROM dual;

3. biorącą w nawias numer kierunkowy z numeru telefonu podanego jako varchar
CREATE OR REPLACE FUNCTION fn_area_code(
  p_phone IN VARCHAR2
) RETURN VARCHAR2 IS
  v_code VARCHAR2(10);
BEGIN
  -- zakładamy, że numer zaczyna się od '(' i ')'
  v_code := SUBSTR(p_phone, INSTR(p_phone,'(')+1, INSTR(p_phone,')')-INSTR(p_phone,'(')-1);
  RETURN v_code;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20012, 'Invalid phone format: '||p_phone);
END fn_area_code;
/

SELECT fn_area_code('(500) 532 554') AS area_code FROM dual;

4. Dla podanego w parametrze ciągu znaków zmieniającą pierwszą i ostatnią literę na
wielką – pozostałe na małe
CREATE OR REPLACE FUNCTION fn_capitalize_first_last(
  p_str IN VARCHAR2
) RETURN VARCHAR2 IS
  v_len PLS_INTEGER := LENGTH(p_str);
  v_out VARCHAR2(4000);
BEGIN
  IF v_len = 0 THEN
    RETURN p_str;
  ELSIF v_len = 1 THEN
    RETURN UPPER(p_str);
  ELSE
    v_out := UPPER(SUBSTR(p_str,1,1))
           || LOWER(SUBSTR(p_str,2,v_len-2))
           || UPPER(SUBSTR(p_str,v_len,1));
    RETURN v_out;
  END IF;
END fn_capitalize_first_last;
/

SELECT fn_capitalize_first_last('john') AS result FROM dual;
SELECT fn_capitalize_first_last('A') AS result FROM dual;
SELECT fn_capitalize_first_last('') AS result FROM dual;
5. Dla podanego peselu - przerabiającą pesel na datę urodzenia w formacie ‘yyyy-mm-dd’
CREATE OR REPLACE FUNCTION fn_pesel_to_date(
  p_pesel IN VARCHAR2
) RETURN DATE IS
  v_year  NUMBER;
  v_month NUMBER;
  v_day   NUMBER;
  v_date  DATE;
BEGIN
  -- Zakładamy poprawny pesel 11 cyfr
  v_year  := TO_NUMBER(SUBSTR(p_pesel,1,2));
  v_month := TO_NUMBER(SUBSTR(p_pesel,3,2));
  v_day   := TO_NUMBER(SUBSTR(p_pesel,5,2));
  -- dekodowanie stulecia
  IF v_month > 80 THEN
    v_year := 1800 + v_year;
    v_month := v_month - 80;
  ELSIF v_month > 60 THEN
    v_year := 2200 + v_year;
    v_month := v_month - 60;
  ELSIF v_month > 40 THEN
    v_year := 2100 + v_year;
    v_month := v_month - 40;
  ELSIF v_month > 20 THEN
    v_year := 2000 + v_year;
    v_month := v_month - 20;
  ELSE
    v_year := 1900 + v_year;
  END IF;
  v_date := TO_DATE(lpad(v_year,4,'0')||'-'||lpad(v_month,2,'0')||'-'||lpad(v_day,2,'0'),'YYYY-MM-DD');
  RETURN v_date;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20013, 'Invalid PESEL: '||p_pesel);
END fn_pesel_to_date;
/

SELECT fn_pesel_to_date('02270812345') FROM dual;

6. Zwracającą liczbę pracowników oraz liczbę departamentów które znajdują się w kraju
podanym jako parametr (nazwa kraju). W przypadku braku kraju - odpowiedni wyjątek
CREATE OR REPLACE PROCEDURE pr_country_stats(
  p_country_name IN countries.country_name%TYPE,
  o_emp_count    OUT NUMBER,
  o_dept_count   OUT NUMBER
) IS
BEGIN
  SELECT COUNT(DISTINCT e.employee_id), COUNT(DISTINCT d.department_id)
    INTO o_emp_count, o_dept_count
    FROM employees e
    JOIN departments d ON e.department_id = d.department_id
    JOIN locations l   ON d.location_id   = l.location_id
    JOIN countries c   ON l.country_id     = c.country_id
   WHERE c.country_name = p_country_name;

  IF o_emp_count = 0 AND o_dept_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20014, 'Country '||p_country_name||' not found or no data');
  END IF;
END pr_country_stats;
/


Stworzyć następujące wyzwalacze:
1. Stworzyć tabelę archiwum_departamentów (id, nazwa, data_zamknięcia,
ostatni_manager jako imię i nazwisko). Po usunięciu departamentu dodać odpowiedni
rekord do tej tabeli
CREATE OR REPLACE TRIGGER trg_dept_archive
AFTER DELETE ON departments
FOR EACH ROW
DECLARE
  v_manager_name VARCHAR2(100);
BEGIN
  BEGIN
    SELECT first_name || ' ' || last_name
      INTO v_manager_name
      FROM employees
     WHERE employee_id = :OLD.manager_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_manager_name := NULL;
  END;

  INSERT INTO archiwum_departamentow (
    department_id, department_name, close_date, last_manager_name
  ) VALUES (
    :OLD.department_id,
    :OLD.department_name,
    SYSDATE,
    v_manager_name
  );
END;
/


2. W razie UPDATE i INSERT na tabeli employees, sprawdzić czy zarobki łapią się w
widełkach 2000 - 26000. Jeśli nie łapią się - zabronić dodania. Dodać tabelę złodziej(id,
USER, czas_zmiany), której będą wrzucane logi, jeśli będzie próba dodania, bądź
zmiany wynagrodzenia poza widełki.
CREATE TABLE zlodziej (
  id         NUMBER GENERATED BY DEFAULT AS IDENTITY,
  username   VARCHAR2(30),
  change_ts  TIMESTAMP,
  old_salary NUMBER(8,2)
);

CREATE OR REPLACE TRIGGER trg_emp_salary_check
BEFORE INSERT OR UPDATE ON employees
FOR EACH ROW
DECLARE
  v_user VARCHAR2(30);
BEGIN
  v_user := NVL(USER,'UNKNOWN');
  IF :NEW.salary NOT BETWEEN 2000 AND 26000 THEN
    INSERT INTO zlodziej(username, change_ts, old_salary)
    VALUES (v_user, SYSTIMESTAMP, :NEW.salary);
    RAISE_APPLICATION_ERROR(-20020,'Salary out of allowed range [2000,26000]');
  END IF;
END trg_emp_salary_check;
/

3. Stworzyć sekwencję i wyzwalacz, który będzie odpowiadał za auto_increment w tabeli
employees.
CREATE SEQUENCE seq_emp_id START WITH 1 INCREMENT BY 1 NOCACHE;
/
CREATE OR REPLACE TRIGGER trg_emp_ai
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
  IF :NEW.employee_id IS NULL THEN
    :NEW.employee_id := seq_emp_id.NEXTVAL;
  END IF;
END trg_emp_ai;
/


4. Stworzyć wyzwalacz, który zabroni dowolnej operacji na tabeli JOD_GRADES (INSERT,
UPDATE, DELETE)
CREATE OR REPLACE TRIGGER trg_jobs_preserve_salary
BEFORE UPDATE OF min_salary, max_salary ON jobs
FOR EACH ROW
BEGIN
  :NEW.min_salary := :OLD.min_salary;
  :NEW.max_salary := :OLD.max_salary;
END trg_jobs_preserve_salary;
/

5. Stworzyć wyzwalacz, który przy próbie zmiany max i min salary w tabeli jobs zostawia
stare wartości.
Stworzyć paczki:
1. Składającą się ze stworzonych procedur i funkcji
CREATE OR REPLACE PACKAGE pkg_hr_utils IS
  FUNCTION get_job_title(p_job_id IN jobs.job_id%TYPE) RETURN VARCHAR2;
  FUNCTION annual_compensation(p_emp_id IN employees.employee_id%TYPE) RETURN NUMBER;
  FUNCTION area_code(p_phone IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION capitalize_first_last(p_str IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION pesel_to_date(p_pesel IN VARCHAR2) RETURN DATE;
  PROCEDURE country_stats(
    p_country_name IN countries.country_name%TYPE,
    o_emp_count    OUT NUMBER,
    o_dept_count   OUT NUMBER
  );
  PROCEDURE add_job(p_job_id IN jobs.job_id%TYPE, p_job_title IN jobs.job_title%TYPE);
  PROCEDURE update_job_title(p_job_id IN jobs.job_id%TYPE, p_new_title IN jobs.job_title%TYPE);
  PROCEDURE delete_job(p_job_id IN jobs.job_id%TYPE);
  PROCEDURE get_employee_info(
    p_emp_id    IN employees.employee_id%TYPE,
    p_salary    OUT employees.salary%TYPE,
    p_last_name OUT employees.last_name%TYPE
  );
  PROCEDURE add_employee(
    p_first_name    IN employees.first_name%TYPE DEFAULT NULL,
    p_last_name     IN employees.last_name%TYPE,
    p_salary        IN employees.salary%TYPE DEFAULT 0,
    p_job_id        IN employees.job_id%TYPE DEFAULT NULL,
    p_email         IN employees.email%TYPE DEFAULT NULL,
    p_hire_date     IN employees.hire_date%TYPE DEFAULT SYSDATE,
    p_department_id IN employees.department_id%TYPE DEFAULT NULL,
    p_phone         IN employees.phone_number%TYPE DEFAULT NULL
  );
END pkg_hr_utils;
/

2. Stworzyć paczkę z procedurami i funkcjami do obsługi tabeli REGIONS (CRUD), gdzie
odczyt z różnymi parametrami