1. Stwórz ranking pracowników oparty na wysokości pensji. Jeśli dwie osoby mają tę samą
pensję, powinny otrzymać ten sam numer.

SELECT 
  employee_id,
  last_name,
  salary,
  RANK() OVER (
    ORDER BY salary DESC
  ) AS salary_rank
FROM employees;


2. Dodaj kolumnę, która pokazuje całkowitą sumę pensji wszystkich pracowników, ale bez
grupowania ich.
SELECT
  employee_id,
  last_name,
  salary,
  SUM(salary) OVER () AS total_salary_all_employees
FROM employees;




3. Dla każdego pracownika wypisz: nazwisko, nazwę produktu, skumulowaną wartość
sprzedaży dla pracownika, ranking wartości sprzedaży względem wszystkich
zamówień.

SELECT
  e.last_name,
  p.product_name,
  SUM(s.quantity * s.price) OVER (
    PARTITION BY e.employee_id
    ORDER BY s.sale_date
  ) AS cumulative_sales,
  RANK() OVER (
    ORDER BY s.quantity * s.price DESC
  ) AS order_value_rank
FROM sales s
JOIN employees e ON s.employee_id = e.employee_id
JOIN products  p ON s.product_id  = p.product_id;

4. Dla każdego wiersza z tabeli sales wypisać nazwisko pracownika, nazwę produktu, cenę
produktu, liczbę transakcji dla danego produktu tego dnia, sumę zapłaconą danego dnia
za produkt, poprzednią cenę oraz kolejną cenę danego produktu.
SELECT
  e.last_name,
  p.product_name,
  s.price,
  COUNT(*) OVER (
    PARTITION BY s.product_id, TRUNC(s.sale_date)
  ) AS tx_count_per_day,
  SUM(s.quantity * s.price) OVER (
    PARTITION BY s.product_id, TRUNC(s.sale_date)
  ) AS total_paid_per_day,
  LAG(s.price)  OVER (PARTITION BY s.product_id ORDER BY s.sale_date) AS prev_price,
  LEAD(s.price) OVER (PARTITION BY s.product_id ORDER BY s.sale_date) AS next_price
FROM sales s
JOIN employees e ON s.employee_id = e.employee_id
JOIN products  p ON s.product_id  = p.product_id;



5. Dla każdego wiersza wypisać nazwę produktu, cenę produktu, sumę całkowitą
zapłaconą w danym miesiącu oraz sumę rosnącą zapłaconą w danym miesiącu za
konkretny produkt
SELECT
  p.product_name,
  s.price,
  SUM(s.quantity * s.price) OVER (
    PARTITION BY s.product_id, TRUNC(s.sale_date,'MM')
  ) AS total_monthly_paid,
  SUM(s.quantity * s.price) OVER (
    PARTITION BY s.product_id, TRUNC(s.sale_date,'MM')
    ORDER BY s.sale_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_monthly_paid
FROM sales s
JOIN products p ON s.product_id = p.product_id;


6. Wypisać obok siebie cenę produktu z roku 2022 i roku 2023 z tego samego dnia oraz
dodatkowo różnicę pomiędzy cenami tych produktów oraz dodatkowo nazwę produktu
i jego kategorię
SELECT
  p.product_name,
  p.product_category,
  s22.price AS price_2022,
  s23.price AS price_2023,
  s23.price - s22.price AS price_diff
FROM sales s22
JOIN sales s23 ON
  s22.product_id = s23.product_id AND
  TO_CHAR(s22.sale_date, 'MM-DD') = TO_CHAR(s23.sale_date, 'MM-DD') AND
  EXTRACT(YEAR FROM s22.sale_date) = 2022 AND
  EXTRACT(YEAR FROM s23.sale_date) = 2023
JOIN products p ON s22.product_id = p.product_id;


7. Dla każdego wiersza wypisać nazwę kategorii produktu, nazwę produktu, jego cenę,
minimalną cenę w danej kategorii, maksymalną cenę w danej kategorii, różnicę między
maksymalną a minimalną ceną.
SELECT
  p.product_category,
  p.product_name,
  s.price,
  MIN(s.price) OVER (PARTITION BY p.product_category) AS min_price_in_category,
  MAX(s.price) OVER (PARTITION BY p.product_category) AS max_price_in_category,
  MAX(s.price) OVER (PARTITION BY p.product_category)
    - MIN(s.price) OVER (PARTITION BY p.product_category) AS price_range
FROM sales s
JOIN products p ON s.product_id = p.product_id;

8. Dla każdego wiersza wypisz nazwę produktu i średnią kroczącą ceny (biorącą pod
uwagę poprzednią, bieżącą i następną cenę) tego produktu według kolejnych dat
SELECT
  p.product_name,
  s.sale_date,
  s.price,
  ROUND(AVG(s.price) OVER (
    PARTITION BY s.product_id
    ORDER BY s.sale_date
    ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
  ), 2) AS moving_avg_price
FROM sales s
JOIN products p ON s.product_id = p.product_id;


9. Dla każdego wiersza nazwę produktu, kategorię oraz ranking cen wewnątrz kategorii,
ponumerowane wiersze wewnątrz kategorii w zależności od ceny oraz ranking gęsty
(dense) cen wewnątrz kategorii
SELECT
  p.product_name,
  p.product_category,
  RANK() OVER (
    PARTITION BY p.product_category
    ORDER BY s.price DESC
  ) AS price_rank,
  ROW_NUMBER() OVER (
    PARTITION BY p.product_category
    ORDER BY s.price DESC
  ) AS row_number_by_price,
  DENSE_RANK() OVER (
    PARTITION BY p.product_category
    ORDER BY s.price DESC
  ) AS dense_price_rank
FROM sales s
JOIN products p ON s.product_id = p.product_id;

10. Dla każdego wiersza tabeli sales nazwisko pracownika, nazwa produktu, wartość
rosnąca jego sprzedaży według dat (cena produktu * ilość) dla danego pracownika oraz
ranking wartości sprzedaży dla kolejnych wierszy globalnie według wartości
zamówienia

11. Nie używając funkcji okienkowych wyświetl: Imiona i nazwiska pracowników oraz ich
stanowisko, którzy uczestniczyli w sprzeda

SELECT DISTINCT
  e.first_name,
  e.last_name,
  e.job_id
FROM employees e
JOIN sales     s ON e.employee_id = s.employee_id;

