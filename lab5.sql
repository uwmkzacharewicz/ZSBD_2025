1. Stworzyć blok anonimowy wypisujący zmienną numer_max równą maksymalnemu
numerowi Departamentu i dodaj do tabeli departamenty – departament z numerem o
10 wiekszym, typ pola dla zmiennej z nazwą nowego departamentu (zainicjować na
EDUCATION) ustawić taki jak dla pola department_name w tabeli (%TYPE)
2. Do poprzedniego skryptu dodaj instrukcje zmieniającą location_id (3000) dla
dodanego departamentu

DECLARE
  v_max_dept_id   departments.department_id%TYPE;
  v_new_dept_name departments.department_name%TYPE := 'EDUCATION';
BEGIN
  -- pobieramy max department_id
  SELECT MAX(department_id)
    INTO v_max_dept_id
    FROM departments;

  -- zwiększ o 10
  v_max_dept_id := v_max_dept_id + 10;
  INSERT INTO departments(department_id, department_name)
  VALUES (v_max_dept_id, v_new_dept_name);

  -- 2. zmiana location_id 
  UPDATE departments
    SET location_id = 3000
    WHERE department_id = v_max_dept_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Dodano departament ' || v_new_dept_name ||
                       ' o ID ' || v_max_dept_id);
END;
/



3. Stwórz tabelę nowa z jednym polem typu varchar a następnie wpisz do niej za
pomocą pętli liczby od 1 do 10 bez liczb 4 i 6
CREATE TABLE NOWA (val VARCHAR2(10));

BEGIN
  FOR i IN 1..10 LOOP
    IF i NOT IN (4,6) THEN
      INSERT INTO NOWA(val) VALUES (TO_CHAR(i));
    END IF;
  END LOOP;
  COMMIT;
END;
/

4. Wyciągnąć informacje z tabeli countries do jednej zmiennej (%ROWTYPE) dla kraju o
identyfikatorze ‘CA’. Wypisać nazwę i region_id na ekran
DECLARE
  v_country countries%ROWTYPE;
BEGIN
  SELECT *
    INTO v_country
    FROM countries
   WHERE country_id = 'CA';

  DBMS_OUTPUT.PUT_LINE('Kraj: ' || v_country.country_name ||
                       ', Region ID: ' || v_country.region_id);
END;
/

5. Zadeklaruj kursor jako wynagrodzenie, nazwisko dla departamentu o numerze 50. Dla
elementów kursora wypisać na ekran, jeśli wynagrodzenie jest wyższe niż 3100:
nazwisko osoby i tekst ‘nie dawać podwyżki’ w przeciwnym przypadku: nazwisko +
‘dać podwyżkę’
DECLARE
  CURSOR c_sal IS
    SELECT last_name, salary
      FROM employees
     WHERE department_id = 50;
  v_last_name employees.last_name%TYPE;
  v_salary    employees.salary%TYPE;
BEGIN
  OPEN c_sal;
  LOOP
    FETCH c_sal INTO v_last_name, v_salary;
    EXIT WHEN c_sal%NOTFOUND;

    IF v_salary > 3100 THEN
      DBMS_OUTPUT.PUT_LINE(v_last_name || ' nie dawać podwyżki');
    ELSE
      DBMS_OUTPUT.PUT_LINE(v_last_name || ' dać podwyżkę');
    END IF;
  END LOOP;
  CLOSE c_sal;
END;
/

6. Zadeklarować kursor zwracający zarobki imię i nazwisko pracownika z parametrami,
gdzie pierwsze dwa parametry określają widełki zarobków a trzeci część imienia
pracownika. Wypisać na ekran pracowników:
a. z widełkami 1000- 5000 z częścią imienia a (może być również A)
b. z widełkami 5000-20000 z częścią imienia u (może być również U)
DECLARE
  CURSOR c_emp(p_min_sal IN employees.salary%TYPE,
               p_max_sal IN employees.salary%TYPE,
               p_frag    IN VARCHAR2) IS
    SELECT first_name, last_name, salary
      FROM employees
     WHERE salary BETWEEN p_min_sal AND p_max_sal
       AND UPPER(first_name) LIKE '%' || UPPER(p_frag) || '%';

  v_fname employees.first_name%TYPE;
  v_lname employees.last_name%TYPE;
  v_sal    employees.salary%TYPE;
BEGIN
  -- a) 1000-5000, a
  DBMS_OUTPUT.PUT_LINE('-- Pracownicy 1000-5000, fragment ''a'' --');
  OPEN c_emp(1000, 5000, 'a');
  LOOP
    FETCH c_emp INTO v_fname, v_lname, v_sal;
    EXIT WHEN c_emp%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_fname || ' ' || v_lname || ' ' || v_sal);
  END LOOP;
  CLOSE c_emp;

  -- b) 5000-20000, u
  DBMS_OUTPUT.PUT_LINE('-- Pracownicy 5000-20000, fragment ''u'' --');
  OPEN c_emp(5000, 20000, 'u');
  LOOP
    FETCH c_emp INTO v_fname, v_lname, v_sal;
    EXIT WHEN c_emp%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(v_fname || ' ' || v_lname || ' ' || v_sal);
  END LOOP;
  CLOSE c_emp;
END;
/

9. Stwórz procedury:
a. dodającą wiersz do tabeli Jobs – z dwoma parametrami wejściowymi
określającymi Job_id, Job_title, przetestuj działanie wrzuć wyjątki – co
najmniej when others
b. modyfikującą title w tabeli Jobs – z dwoma parametrami id dla którego ma być
modyfikacja oraz nową wartość dla Job_title – przetestować działanie, dodać
swój wyjątek dla no Jobs updated – najpierw sprawdzić numer błędu
c. usuwającą wiersz z tabeli Jobs o podanym Job_id– przetestować działanie,
dodaj wyjątek dla no Jobs deleted
d. Wyciągającą zarobki i nazwisko (parametry zwracane przez procedurę) z
tabeli employees dla pracownika o przekazanym jako parametr id
e. dodającą do tabeli employees wiersz – większość parametrów ustawić na
domyślne (id poprzez sekwencję), stworzyć wyjątek jeśli wynagrodzenie
dodawanego pracownika jest wyższe niż 20000

-- 9a
CREATE OR REPLACE PROCEDURE add_job(
  p_job_id    IN jobs.job_id%TYPE,
  p_job_title IN jobs.job_title%TYPE
) AS
BEGIN
  INSERT INTO jobs(job_id, job_title)
  VALUES (p_job_id, p_job_title);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error adding job: ' || SQLERRM);
    ROLLBACK;
END;
/

-- 9b
CREATE OR REPLACE PROCEDURE update_job_title(
  p_job_id    IN jobs.job_id%TYPE,
  p_new_title IN jobs.job_title%TYPE
) AS
BEGIN
  UPDATE jobs
     SET job_title = p_new_title
   WHERE job_id    = p_job_id;
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'No Jobs updated for ID ' || p_job_id);
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error updating job title: ' || SQLERRM);
    ROLLBACK;
END;
/

-- 9c
CREATE OR REPLACE PROCEDURE delete_job(
  p_job_id IN jobs.job_id%TYPE
) AS
BEGIN
  DELETE FROM jobs
   WHERE job_id = p_job_id;
  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'No Jobs deleted for ID ' || p_job_id);
  END IF;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error deleting job: ' || SQLERRM);
    ROLLBACK;
END;
/

-- 9d
CREATE OR REPLACE PROCEDURE get_employee_info(
  p_emp_id     IN  employees.employee_id%TYPE,
  p_salary     OUT employees.salary%TYPE,
  p_last_name  OUT employees.last_name%TYPE
) AS
BEGIN
  SELECT salary, last_name
    INTO p_salary, p_last_name
    FROM employees
   WHERE employee_id = p_emp_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_salary    := NULL;
    p_last_name := NULL;
    DBMS_OUTPUT.PUT_LINE('No employee found with ID ' || p_emp_id);
END;
/