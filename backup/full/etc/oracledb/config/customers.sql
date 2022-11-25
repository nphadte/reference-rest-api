DROP TABLE CUSTOMER;

CREATE TABLE CUSTOMER(
id                      number(5) primary key,
first_name              varchar(256),
last_name               varchar(256),
middle_initial          varchar(5)
);

INSERT INTO CUSTOMER VALUES (1, 'Martin', 'Fowler', 'M');
INSERT INTO CUSTOMER VALUES (2, 'Sam', 'Newman', 'A');
INSERT INTO CUSTOMER VALUES (3, 'Adrian', 'Cockroft', 'B');
INSERT INTO CUSTOMER VALUES (5, 'Caitie', 'McCaffrey', 'C');
INSERT INTO CUSTOMER VALUES (4, 'Chris', 'Richardson', 'D');
