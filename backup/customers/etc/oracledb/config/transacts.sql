DROP TABLE TRANSACTION;

CREATE TABLE TRANSACTION(
id              number(5) primary key,
account_id       number(5),
transaction_type varchar(128),
amount          decimal(8,2)
);

INSERT INTO TRANSACTION VALUES (1, 1, 'DEBIT', 1.10);
INSERT INTO TRANSACTION VALUES (2, 1, 'CREDIT', 2.22);
INSERT INTO TRANSACTION VALUES (3, 2, 'DEBIT', 3.30);
INSERT INTO TRANSACTION VALUES (4, 2, 'CREDIT', 4.40);
INSERT INTO TRANSACTION VALUES (5, 3, 'DEBIT', 5.50);
INSERT INTO TRANSACTION VALUES (6, 3, 'CREDIT', 6.60);
INSERT INTO TRANSACTION VALUES (7, 4, 'DEBIT', 7.70);
INSERT INTO TRANSACTION VALUES (8, 4, 'CREDIT', 8.80);
INSERT INTO TRANSACTION VALUES (9, 5, 'DEBIT', 9.90);
INSERT INTO TRANSACTION VALUES (10, 5, 'CREDIT', 10.13);
INSERT INTO TRANSACTION VALUES (11, 6, 'DEBIT', 1.10);
INSERT INTO TRANSACTION VALUES (12, 6, 'CREDIT', 2.20);
INSERT INTO TRANSACTION VALUES (13, 7, 'DEBIT', 3.30);
INSERT INTO TRANSACTION VALUES (14, 7, 'CREDIT', 4.40);
INSERT INTO TRANSACTION VALUES (15, 8, 'DEBIT', 5.50);
INSERT INTO TRANSACTION VALUES (16, 8, 'CREDIT', 6.68);
INSERT INTO TRANSACTION VALUES (17, 9, 'DEBIT', 7.70);
INSERT INTO TRANSACTION VALUES (18, 9, 'CREDIT', 8.80);
INSERT INTO TRANSACTION VALUES (19, 10, 'DEBIT', 9.90);
INSERT INTO TRANSACTION VALUES (20, 10, 'CREDIT', 10.27);
