BEGIN
  FOR cur_rec IN (SELECT object_name, object_type 
                  FROM   user_objects
                  WHERE  object_type IN ('TABLE', 'VIEW', 'PACKAGE', 'PROCEDURE', 'FUNCTION', 'SEQUENCE', 'TRIGGER', 'TYPE')) LOOP
    BEGIN
      IF cur_rec.object_type = 'TABLE' THEN
        IF instr(cur_rec.object_name, 'STORE') = 0 then
          EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '" CASCADE CONSTRAINTS';
        END IF;
      ELSIF cur_rec.object_type = 'TYPE' THEN
        EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '" FORCE';
      ELSE
        EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '"';
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('FAILED: DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '"');
    END;
  END LOOP;
END;
/


CREATE OR REPLACE TYPE t_adres AS OBJECT
(
 ulica VARCHAR2(25),
 numer_domu VARCHAR2(4),
 numer_mieszkania VARCHAR2(4),
 miejscowosc VARCHAR2(20),
 kod_pocztowy VARCHAR2(5),
 kraj VARCHAR2(20),
 numer_telefonu NUMBER(9)
); 



CREATE OR REPLACE TYPE t_klient AS OBJECT
(
 klient_id NUMBER,
 imie VARCHAR2(30),
 nazwisko VARCHAR2(30),
 adres t_adres,
 id VARCHAR(10),
 dokument_prawa_jazdy VARCHAR2(8),
 ilosc_wypozyczen NUMBER
);


Create OR REPLACE TYPE typ_samochodu AS OBJECT
(
typ_id NUMBER,
Nazwa VARCHAR2(50)
);

CREATE OR REPLACE TYPE t_samochod AS OBJECT
(
samochod_id NUMBER,
marka VARCHAR2(20),
model_samochodu VARCHAR2(30),
rok_produkcji NUMBER(4),
nr_rejestracyjny VARCHAR(10),
typ REF Typ_Samochodu,
kolor VARCHAR2(20),
przebieg NUMBER,
pojemnosc_silnika NUMBER,
stan_paliwa NUMBER,
cena_za_dzien NUMBER,
liczba_miejsca NUMBER,
status NUMBER
);

CREATE OR REPLACE TYPE t_pracownik AS OBJECT
(
 pracownik_id NUMBER,
 imie VARCHAR2(15),
 nazwisko VARCHAR2(15),
 data_Zatrudnienia DATE,
 data_Zwolnienia DATE,
 adres t_adres,
 Stanowisko VARCHAR2(50),
 pensja NUMBER,
 ilosc_klientow NUMBER
);


CREATE OR REPLACE TYPE t_wypozyczenie AS OBJECT
(
id_wypozyczenia NUMBER,
klient_id REF t_klient,
samochod_id REF t_samochod,
pracownik_id REF t_pracownik,
data_wypozyczenia DATE,
data_zwrotu DATE,
cena NUMBER,
status NUMBER
);








CREATE TABLE Klienci OF t_klient
(
  PRIMARY KEY (klient_id)
);

CREATE TABLE typy_samochodow OF typ_samochodu
(
    PRIMARY KEY (typ_id)
);

CREATE TABLE Samochody OF t_samochod
(
  PRIMARY KEY (samochod_id),
  SCOPE FOR (typ) IS typy_samochodow
);

CREATE TABLE Pracownicy OF t_pracownik
(
  PRIMARY KEY (pracownik_id)
);

CREATE TABLE Wypozyczenia OF t_wypozyczenie
(
  PRIMARY KEY (id_wypozyczenia),
  SCOPE FOR (samochod_id) IS samochody,
  SCOPE FOR (pracownik_id) IS pracownicy,
  SCOPE FOR (klient_id) IS klienci
);



CREATE SEQUENCE seq_klient START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_pracownik START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_samochod START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_wypozyczenie START WITH 1 INCREMENT BY 1;

CREATE SEQUENCE seq_typ_samochodu START WITH 1 INCREMENT BY 1;


CREATE OR REPLACE PACKAGE Szef AS

    PROCEDURE DodajPracownika (
        p_imie             IN VARCHAR2,
        p_nazwisko         IN VARCHAR2,
        p_dataZatrudnienia IN DATE,
        p_dataZwolnienia   IN DATE,
        p_ulica            IN VARCHAR2,
        p_numer_domu       IN VARCHAR2,
        p_numer_mieszkania IN VARCHAR2,
        p_miejscowosc      IN VARCHAR2,
        p_kod_pocztowy     IN VARCHAR2,
        p_kraj             IN VARCHAR2,
        p_numer_telefonu   IN NUMBER,
        p_stanowisko       IN VARCHAR2,
        p_pensja           IN NUMBER
    );

    PROCEDURE ZwolnijPracownika (
        p_pracownik_id IN NUMBER
    );

    PROCEDURE ZmienStanowiskoPracownika (
        p_pracownik_id     IN NUMBER,
        p_nowe_stanowisko  IN VARCHAR2
    );

    FUNCTION ObliczPensjePracownika (
        p_pracownik_id IN NUMBER
    ) RETURN NUMBER;

END Szef;



CREATE OR REPLACE PACKAGE BODY Szef AS

PROCEDURE DodajPracownika (
    p_imie            IN VARCHAR2,
    p_nazwisko        IN VARCHAR2,
    p_dataZatrudnienia IN DATE,
    p_dataZwolnienia  IN DATE,
    p_ulica           IN VARCHAR2,
    p_numer_domu      IN VARCHAR2,
    p_numer_mieszkania IN VARCHAR2,
    p_miejscowosc     IN VARCHAR2,
    p_kod_pocztowy    IN VARCHAR2,
    p_kraj            IN VARCHAR2,
    p_numer_telefonu  IN NUMBER,
    p_stanowisko      IN VARCHAR2,
    p_pensja          IN NUMBER
) IS
BEGIN
     IF p_numer_telefonu < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Numer telefonu nie mo¿e byæ ujemny.');
    END IF;
    
    IF p_pensja < 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Pensja nie mo¿e byæ ujemna.');
    END IF;


    INSERT INTO Pracownicy (pracownik_id, imie, nazwisko, data_Zatrudnienia, data_Zwolnienia, adres, Stanowisko, pensja, ilosc_klientow)
    VALUES (seq_pracownik.NEXTVAL, p_imie, p_nazwisko, p_dataZatrudnienia, p_dataZwolnienia, t_adres(p_ulica, p_numer_domu, p_numer_mieszkania, p_miejscowosc, p_kod_pocztowy, p_kraj, p_numer_telefonu), p_stanowisko, p_pensja, 0);
END DodajPracownika;


PROCEDURE ZwolnijPracownika (p_pracownik_id IN NUMBER) IS
BEGIN
    UPDATE Pracownicy
    SET data_Zwolnienia = SYSDATE
    WHERE pracownik_id = p_pracownik_id;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono pracownika o ID: ' || p_pracownik_id);
    ELSIF SQL%ROWCOUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Pracownik o ID: ' || p_pracownik_id || ' zosta³ zwolniony.');
    END IF;
    
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono pracownika o ID: ' || p_pracownik_id || ' do zwolnienia.');
   
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d podczas zwalniania pracownika: ' || SQLERRM);
        RAISE;
END ZwolnijPracownika;

PROCEDURE ZmienStanowiskoPracownika (
    p_pracownik_id IN NUMBER,
    p_nowe_stanowisko IN VARCHAR2
) IS
BEGIN
    UPDATE Pracownicy
    SET Stanowisko = p_nowe_stanowisko
    WHERE pracownik_id = p_pracownik_id;
    
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono pracownika o ID: ' || p_pracownik_id || '.');
    ELSIF SQL%ROWCOUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Zaktualizowano stanowisko pracownika o ID: ' || p_pracownik_id || ' na ' || p_nowe_stanowisko || '.');
    END IF;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Wyst¹pi³ b³¹d podczas aktualizacji stanowiska pracownika.');
        ROLLBACK;
END ZmienStanowiskoPracownika;

FUNCTION ObliczPensjePracownika (p_pracownik_id IN NUMBER) RETURN NUMBER IS
    v_pensja NUMBER;
    v_ilosc_klientow NUMBER;
    v_calculated_salary NUMBER;
BEGIN

    SELECT pensja, ilosc_klientow INTO v_pensja, v_ilosc_klientow
    FROM Pracownicy
    WHERE pracownik_id = p_pracownik_id;
    

    v_calculated_salary := v_pensja + (v_ilosc_klientow * 30);
    
    RETURN v_calculated_salary;
EXCEPTION
    WHEN NO_DATA_FOUND THEN

        RAISE_APPLICATION_ERROR(-20001, 'Nie znaleziono pracownika o podanym ID: ' || TO_CHAR(p_pracownik_id));
    WHEN OTHERS THEN

        RAISE;
END ObliczPensjePracownika;

END Szef;




CREATE OR REPLACE PACKAGE Uzytkownik AS


    FUNCTION PokazDostepneSamochody RETURN SYS_REFCURSOR;
    

    FUNCTION SprawdzWypozyczeniaKlienta(p_klient_id IN NUMBER) RETURN SYS_REFCURSOR;

END Uzytkownik;



CREATE OR REPLACE PACKAGE BODY Uzytkownik AS

    FUNCTION PokazDostepneSamochody RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT s.samochod_id, s.marka, s.model_samochodu, s.rok_produkcji, s.nr_rejestracyjny,
                   DEREF(s.typ).Nazwa AS typ_samochodu_nazwa,
                   s.kolor, s.przebieg, s.pojemnosc_silnika, s.stan_paliwa, s.cena_za_dzien, s.liczba_miejsca, s.status
            FROM Samochody s
            WHERE s.status = 1;
        RETURN v_cursor;
    END PokazDostepneSamochody;

FUNCTION SprawdzWypozyczeniaKlienta(p_klient_id IN NUMBER) RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT w.id_wypozyczenia, w.data_wypozyczenia, w.data_zwrotu, w.cena, w.status,
               DEREF(w.samochod_id).marka AS marka_samochodu,
               DEREF(w.samochod_id).model_samochodu AS model_samochodu
        FROM Wypozyczenia w
        WHERE DEREF(w.klient_id).klient_id = p_klient_id;
    RETURN v_cursor;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Tutaj mo¿na zdecydowaæ, czy zwracaæ pusty kursor, czy zg³aszaæ wyj¹tek.
        RAISE_APPLICATION_ERROR(-20001, 'Nie znaleziono wypo¿yczeñ dla klienta o ID: ' || p_klient_id);
    WHEN OTHERS THEN
        RAISE;
END SprawdzWypozyczeniaKlienta;

END Uzytkownik;



CREATE OR REPLACE PACKAGE Pracownik AS

    PROCEDURE DodajKlienta (
        p_imie             IN VARCHAR2,
        p_nazwisko         IN VARCHAR2,
        p_ulica            IN VARCHAR2,
        p_numer_domu       IN VARCHAR2,
        p_numer_mieszkania IN VARCHAR2,
        p_miejscowosc      IN VARCHAR2,
        p_kod_pocztowy     IN VARCHAR2,
        p_kraj             IN VARCHAR2,
        p_numer_telefonu   IN NUMBER,
        p_id               IN VARCHAR2,
        p_dokument_prawa_jazdy IN VARCHAR2
    );

    PROCEDURE DodajTypSamochodu (
        p_Nazwa IN VARCHAR2
    );

    PROCEDURE DodajSamochod (
        p_marka            IN VARCHAR2,
        p_model_samochodu  IN VARCHAR2,
        p_rok_produkcji    IN NUMBER,
        p_nr_rejestracyjny IN VARCHAR,
        p_typ_id           IN NUMBER,
        p_kolor            IN VARCHAR2,
        p_przebieg         IN NUMBER,
        p_pojemnosc_silnika IN NUMBER,
        p_stan_paliwa      IN NUMBER,
        p_cena_za_dzien    IN NUMBER,
        p_liczba_miejsc    IN NUMBER,
        p_status           IN NUMBER
    );

    PROCEDURE DodajWypozyczenie (
        p_klient_id         IN NUMBER,
        p_samochod_id       IN NUMBER,
        p_pracownik_id      IN NUMBER,
        p_data_wypozyczenia IN DATE,
        p_data_zwrotu       IN DATE
    );

    PROCEDURE ZakonczWypozyczenie (
        p_id_wypozyczenia IN NUMBER
    );

END Pracownik;



create or replace PACKAGE BODY Pracownik AS

    
PROCEDURE DodajKlienta (
    p_imie             IN VARCHAR2,
    p_nazwisko         IN VARCHAR2,
    p_ulica            IN VARCHAR2,
    p_numer_domu       IN VARCHAR2,
    p_numer_mieszkania IN VARCHAR2,
    p_miejscowosc      IN VARCHAR2,
    p_kod_pocztowy     IN VARCHAR2,
    p_kraj             IN VARCHAR2,
    p_numer_telefonu   IN NUMBER,
    p_id               IN VARCHAR2,
    p_dokument_prawa_jazdy IN VARCHAR2
)
IS
BEGIN
    INSERT INTO Klienci (klient_id, imie, nazwisko, adres, id, dokument_prawa_jazdy,ilosc_wypozyczen)
    VALUES (seq_klient.NEXTVAL, p_imie, p_nazwisko, t_adres(p_ulica, p_numer_domu, p_numer_mieszkania, p_miejscowosc, p_kod_pocztowy, p_kraj, p_numer_telefonu), p_id, p_dokument_prawa_jazdy,0);
END DodajKlienta;



PROCEDURE DodajTypSamochodu (
    p_Nazwa IN VARCHAR2
) IS
BEGIN
    INSERT INTO typy_samochodow (typ_id, Nazwa)
    VALUES (seq_typ_samochodu.NEXTVAL, p_Nazwa);
END DodajTypSamochodu;


PROCEDURE DodajSamochod (
    p_marka            IN VARCHAR2,
    p_model_samochodu  IN VARCHAR2,
    p_rok_produkcji    IN NUMBER,
    p_nr_rejestracyjny IN VARCHAR,
    p_typ_id           IN NUMBER,
    p_kolor            IN VARCHAR2,
    p_przebieg         IN NUMBER,
    p_pojemnosc_silnika IN NUMBER,
    p_stan_paliwa      IN NUMBER,
    p_cena_za_dzien    IN NUMBER,
    p_liczba_miejsc    IN NUMBER,
    p_status           IN NUMBER
) IS
BEGIN

    IF p_rok_produkcji < 0 OR p_przebieg < 0 OR p_pojemnosc_silnika < 0 OR p_stan_paliwa < 0 OR
       p_cena_za_dzien < 0 OR p_liczba_miejsc < 0 OR p_status < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Wartoœci numeryczne nie mog¹ byæ ujemne.');
    END IF;

    INSERT INTO Samochody (samochod_id, marka, model_samochodu, rok_produkcji, nr_rejestracyjny, typ, kolor, przebieg, pojemnosc_silnika, stan_paliwa, cena_za_dzien, liczba_miejsca, status)
    VALUES (seq_samochod.NEXTVAL, p_marka, p_model_samochodu, p_rok_produkcji, p_nr_rejestracyjny, (SELECT REF(s) FROM typy_samochodow s WHERE s.typ_id = p_typ_id), p_kolor, p_przebieg, p_pojemnosc_silnika, p_stan_paliwa, p_cena_za_dzien, p_liczba_miejsc, p_status);
END DodajSamochod;


PROCEDURE DodajWypozyczenie (
    p_klient_id         IN NUMBER,
    p_samochod_id       IN NUMBER,
    p_pracownik_id      IN NUMBER,
    p_data_wypozyczenia IN DATE,
    p_data_zwrotu       IN DATE
) IS
    v_cena_za_dzien NUMBER;
    v_ilosc_dni     NUMBER;
    v_cena          NUMBER;
    v_liczba_rekordow NUMBER;
    v_data_zwolnienia DATE;
BEGIN
    IF p_data_zwrotu < p_data_wypozyczenia THEN
        RAISE_APPLICATION_ERROR(-20007, 'Data zwrotu nie mo¿e byæ wczeœniejsza ni¿ data wypo¿yczenia.');
    END IF;

    SELECT COUNT(*) INTO v_liczba_rekordow FROM Klienci WHERE klient_id = p_klient_id;
    IF v_liczba_rekordow = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nie znaleziono klienta o ID: ' || p_klient_id);
    END IF;


    SELECT COUNT(*) INTO v_liczba_rekordow FROM Samochody WHERE samochod_id = p_samochod_id;
    IF v_liczba_rekordow = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nie znaleziono samochodu o ID: ' || p_samochod_id);
    END IF;


    SELECT COUNT(*), MAX(data_Zwolnienia) INTO v_liczba_rekordow, v_data_zwolnienia FROM Pracownicy WHERE pracownik_id = p_pracownik_id GROUP BY pracownik_id;
    IF v_liczba_rekordow = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Nie znaleziono pracownika o ID: ' || p_pracownik_id);
    ELSIF v_data_zwolnienia IS NOT NULL THEN
        RAISE_APPLICATION_ERROR(-20005, 'Pracownik o ID: ' || p_pracownik_id || ' zosta³ zwolniony.');
    END IF;

    SELECT cena_za_dzien INTO v_cena_za_dzien FROM Samochody WHERE samochod_id = p_samochod_id;


    v_ilosc_dni := p_data_zwrotu - p_data_wypozyczenia;
    v_cena := v_cena_za_dzien * v_ilosc_dni;


    INSERT INTO Wypozyczenia (id_wypozyczenia, klient_id, samochod_id, pracownik_id, data_wypozyczenia, data_zwrotu, cena, status)
    VALUES (seq_wypozyczenie.NEXTVAL, 
            (SELECT REF(k) FROM Klienci k WHERE k.klient_id = p_klient_id), 
            (SELECT REF(s) FROM Samochody s WHERE s.samochod_id = p_samochod_id), 
            (SELECT REF(p) FROM Pracownicy p WHERE p.pracownik_id = p_pracownik_id), 
            p_data_wypozyczenia, p_data_zwrotu, v_cena, 0);

EXCEPTION
    WHEN OTHERS THEN

        RAISE_APPLICATION_ERROR(-20006, 'Wyst¹pi³ nieoczekiwany b³¹d: ' || SQLERRM);
END DodajWypozyczenie;

PROCEDURE ZakonczWypozyczenie (
    p_id_wypozyczenia IN NUMBER
) IS
    v_samochod_id NUMBER;
BEGIN

    SELECT DEREF(samochod_id).samochod_id INTO v_samochod_id
    FROM Wypozyczenia
    WHERE id_wypozyczenia = p_id_wypozyczenia;


    UPDATE Samochody
    SET status = 1
    WHERE samochod_id = v_samochod_id;


    UPDATE Wypozyczenia
   
    WHERE id_wypozyczenia = p_id_wypozyczenia;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN

        RAISE_APPLICATION_ERROR(-20001, 'Nie znaleziono wypo¿yczenia o podanym ID.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nieprawid³owe dane.');
        RAISE;
END ZakonczWypozyczenie;


END Pracownik;



CREATE OR REPLACE TRIGGER ZmienStatusSamochoduPoWypozyczeniu
AFTER INSERT ON Wypozyczenia
FOR EACH ROW
DECLARE
    v_samochod_id NUMBER;
BEGIN

    SELECT DEREF(:NEW.samochod_id).samochod_id INTO v_samochod_id FROM dual;


    UPDATE Samochody
    SET status = 0
    WHERE samochod_id = v_samochod_id;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN

        RAISE_APPLICATION_ERROR(-20002, 'Nie znaleziono samochodu o podanym ID.');
END ZmienStatusSamochoduPoWypozyczeniu;


CREATE OR REPLACE TRIGGER AktualizujIloscKlientowDlaPracownika
AFTER INSERT ON Wypozyczenia
FOR EACH ROW
DECLARE
    v_pracownik_id NUMBER;
BEGIN

    SELECT DEREF(:NEW.pracownik_id).pracownik_id INTO v_pracownik_id FROM dual;


    UPDATE Pracownicy
    SET ilosc_klientow = ilosc_klientow + 1
    WHERE pracownik_id = v_pracownik_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nie znaleziono pracownika o ID: ' || v_pracownik_id);
END;



CREATE OR REPLACE TRIGGER AktualizujIloscWypozyczenDlaKlienta
AFTER INSERT ON Wypozyczenia
FOR EACH ROW
DECLARE
    v_klient_id NUMBER;
BEGIN

    SELECT DEREF(:NEW.klient_id).klient_id INTO v_klient_id FROM dual;


    UPDATE Klienci
    SET ilosc_wypozyczen = ilosc_wypozyczen + 1
    WHERE klient_id = v_klient_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nie znaleziono klienta o ID: ' || v_klient_id);
END;





BEGIN
    Pracownik.DodajKlienta('Jan', 'Kowalski', 'Ulica', '12', '34', 'Warszawa', '00000', 'Polska', 123456789, 'ID12345678', 'DL123456');
END;

BEGIN
    Pracownik.DodajKlienta('Anna', 'Nowak', 'Jasna', '5', '2', 'Kraków', '30000', 'Polska', 987654321, 'ID87654321', 'DL876543');
END;

BEGIN
    Pracownik.DodajKlienta('Piotr', 'Wiœniewski', 'Miodowa', '22', '7', 'Gdañsk', '80000', 'Polska', 234567890, 'ID23456789', 'DL234567');
END;

BEGIN
    Pracownik.DodajKlienta('Katarzyna', 'Zaj¹c', 'Krótka', '3', '16', 'Wroc³aw', '50000', 'Polska', 345678901, 'ID34567890', 'DL345678');
END;

BEGIN
    Pracownik.DodajKlienta('Micha³', 'Mazur', 'D³uga', '40', '5', 'Poznañ', '60000', 'Polska', 456789012, 'ID45678901', 'DL456789');
END;

BEGIN
    Pracownik.DodajKlienta('Ewa', 'Kowalczyk', 'Szeroka', '11', '8', 'Szczecin', '70000', 'Polska', 567890123, 'ID56789012', 'DL567890');
END;

SELECT * FROM KLIENCI




BEGIN
    Pracownik.DodajTypSamochodu('SUV');
END;

BEGIN
    Pracownik.DodajTypSamochodu('Sedan');
END;

BEGIN
    Pracownik.DodajTypSamochodu('Hatchback');
END;

BEGIN
    Pracownik.DodajTypSamochodu('Coupe');
END;

SELECT * FROM Typy_samochodow



BEGIN
    Pracownik.DodajSamochod('Toyota', 'Yaris', 2020, 'WE12345', 1, 'Czerwony', 15000, 1300, 50, 100, 5, 1);
END;


BEGIN
    Pracownik.DodajSamochod('Honda', 'Civic', 2018, 'WZ67890', 2, 'Niebieski', 12000, 1600, 60, 120, 5, 1);
END;



BEGIN
    Pracownik.DodajSamochod('Ford', 'Focus', 2019, 'DW54321', 3, 'Zielony', 10000, 1500, 55, 110, 5, 1);
END;


BEGIN
    Pracownik.DodajSamochod('Volkswagen', 'Golf', 2021, 'KR98765', 4, 'Bia³y', 8000, 1400, 45, 90, 5, 1);
END;

SELECT * FROM SAMOCHODY


BEGIN
    Szef.DodajPracownika(
        'Jan', 'Kowalski', DATE '2023-01-01', NULL,
        'Ulica', '12', '34', 'Warszawa', '00000', 'Polska', 123456789,
        'Dyrektor', -5000
    );
END;



BEGIN
    Szef.DodajPracownika(
        'Anna', 'Nowak', DATE '2022-05-15', NULL,
        'Kwiatowa', '5', '2', 'Kraków', '31000', 'Polska', 987654321,
        'Menad¿er', 4500
    );
END;


BEGIN
    Szef.DodajPracownika(
        'Piotr', 'Wiœniewski', DATE '2023-03-01', NULL,
        'S³oneczna', '7', '16', 'Gdañsk', '80090', 'Polska', 567890123,
        'Specjalista ds. sprzeda¿y', 4000
    );
END;


SELECT * FROM PRACOWNICY






BEGIN
    Pracownik.DodajWypozyczenie(
        p_klient_id         => 1,
        p_samochod_id       => 1,
        p_pracownik_id      => 1,
        p_data_wypozyczenia => TO_DATE('2023-01-10', 'YYYY-MM-DD'),
        p_data_zwrotu       => TO_DATE('2023-01-20', 'YYYY-MM-DD')
    );
END;



BEGIN
    Pracownik.DodajWypozyczenie(
        p_klient_id         => 2,
        p_samochod_id       => 2,
        p_pracownik_id      => 2,
        p_data_wypozyczenia => TO_DATE('2023-02-01', 'YYYY-MM-DD'),
        p_data_zwrotu       => TO_DATE('2023-02-10', 'YYYY-MM-DD')
    );
END;




SELECT * FROM WYPOZYCZENIA
SELECT * FROM SAMOCHODY

SELECT * FROM PRACOWNICY
SELECT * FROM KLIENCI



BEGIN
    Pracownik.ZakonczWypozyczenie(p_id_wypozyczenia => 3); 
END;

SELECT * FROM SAMOCHODY
SELeCT * FROM WYPOZYCZENIA



VARIABLE cur REFCURSOR;
EXEC :cur := Uzytkownik.PokazDostepneSamochody;
PRINT cur;



VARIABLE cur REFCURSOR;
EXEC :cur := Uzytkownik.SprawdzWypozyczeniaKlienta(1);
PRINT cur;




SET SERVEROUTPUT ON;
EXEC Szef.ZwolnijPracownika(p_pracownik_id => 1); 


SELECT * FROM Pracownicy

BEGIN
    Pracownik.DodajWypozyczenie(
        p_klient_id         => 2,
        p_samochod_id       => 2,
        p_pracownik_id      => 1,
        p_data_wypozyczenia => TO_DATE('2023-02-01', 'YYYY-MM-DD'),
        p_data_zwrotu       => TO_DATE('2023-02-10', 'YYYY-MM-DD')
    );
END;


SET SERVEROUTPUT ON;
EXEC Szef.ZmienStanowiskoPracownika(p_pracownik_id => 2, p_nowe_stanowisko => 'Konsultant');


SELECT * FROM Pracownicy

DECLARE
    v_pensja NUMBER;
BEGIN
    v_pensja := Szef.ObliczPensjePracownika(1);
    DBMS_OUTPUT.PUT_LINE('Ca³kowita pensja pracownika: ' || v_pensja);
END;



