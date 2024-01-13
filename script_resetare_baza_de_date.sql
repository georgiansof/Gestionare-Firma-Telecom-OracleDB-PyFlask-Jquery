--- drop tabelelor existente
drop table servicii_contractate;
drop table reduceri;
drop table echipamente;
drop table facturi;
drop table remedieri;
drop table sesizari;
drop table servicii;
drop table clienti;
drop table angajati;

--- drop secventelor
drop sequence autonumerotare_servicii;
drop sequence autonumerotare_servicii_contractate;
drop sequence autonumerotare_reduceri;
drop sequence autonumerotare_echipamente;
drop sequence autonumerotare_facturi;
drop sequence autonumerotare_sesizari;
drop sequence autonumerotare_remedieri;

--- creare tabele

create table angajati (
    cnp varchar2(13),
    nume varchar2(20)
        constraint ANGAJATI_NUME_NN not null,
    prenume varchar2(30)
        constraint ANGAJATI_PRENUME_NN not null,
    data_angajare date default sysdate
        constraint ANGAJATI_DATA_ANGAJARE_NN not null,
    rol varchar2(20),
    salariu number(5,0)
        constraint ANAJATI_SALARIU_NN not null,
    nr_tel varchar2(10)
        constraint ANGAJATI_NR_TEL_UNQ unique,
    email varchar2(30),
    cnp_manager varchar2(13),
    
    constraint ANGAJATI_CNP_PK primary key (cnp),
    constraint ANGAJATI_CNP_MANAGER_FK foreign key (cnp_manager)
        references angajati(cnp) on delete set null,
    constraint ANGAJATI_NR_TEL_CHK check(length(nr_tel) = 10 and nr_tel like '07%'),
    --- ANGAJATI_NR_TEL_CHK verifica daca numarul de telefon este de mobil.
    constraint ANGAJATI_EMAIL_CHK check(email like '%@%.%')
    --- ANGAJATI_EMAIL_CHK verifica daca emailul este in forma ***@domeniu.com/ro/io/etc
);

alter table angajati
add constraint ANGAJATI_CNP_CHK
check (length(cnp) = 13 and
    case 
        when substr(cnp, 1, 1) in ('5', '6', '7', '8') then to_date('20' || substr(cnp, 2, 6), 'yyyymmdd')
        when substr(cnp, 1, 1) in ('1', '2') then to_date('19' || substr(cnp, 2, 6), 'yyyymmdd')
        when substr(cnp, 1, 1) in ('3', '4') then to_date('18' || substr(cnp, 2, 6), 'yyyymmdd')
        else null
    end is not null and --- data este valida
    to_number(substr(cnp, 8, 2)) >= 1 and
    to_number(substr(cnp, 8, 2)) <= 52 and --- judetul este valid 
    to_char(
    mod(
        (
            substr(cnp, 1, 1) * 2 +
            substr(cnp, 2, 1) * 7 +
            substr(cnp, 3, 1) * 9 +
            substr(cnp, 4, 1) * 1 +
            substr(cnp, 5, 1) * 4 +
            substr(cnp, 6, 1) * 6 +
            substr(cnp, 7, 1) * 3 +
            substr(cnp, 8, 1) * 5 +
            substr(cnp, 9, 1) * 8 +
            substr(cnp, 10, 1) * 2 +
            substr(cnp, 11, 1) * 7 +
            substr(cnp, 12, 1) * 9
        ), 11)
    ) = substr(cnp, 13, 1) --- cifra de control
);

create sequence autonumerotare_servicii
    start with 1
    increment by 1
    maxvalue 99999;

create table servicii (
        id_serviciu number(5,0) default autonumerotare_servicii.NEXTVAL,
        nume_serviciu varchar2(30) constraint SERVICII_NUME_SERVICIU_NN not null,
        pret_lunar number(5,2) constraint SERVICII_PRET_LUNAR_NN not null,

        constraint SERVICII_ID_SERVICIU_PK primary key (id_serviciu)
);

create table clienti (
    cnp varchar2(13),
    nume varchar2(20) 
        constraint CLIENTI_NUME_NN not null,
    prenume varchar2(30) 
        constraint CLIENTI_PRENUME_NN not null,
    nr_tel varchar2(10) 
        constraint CLIENTI_NR_TEL_NN not null,
    email varchar2(30),
    adresa varchar2(60) 
        constraint CLIENTI_ADRESA_NN not null,
    data_inregistrare date default sysdate
        constraint CLIENTI_DATA_INREGISTRARE not null,
    
    constraint CLIENTI_NR_TEL_UNQ unique (nr_tel),
    constraint CLIENTI_CNP_PK primary key (cnp),
    constraint CLIENTI_NR_TEL_CHK check (length(nr_tel) = 10 and nr_tel like '07%'),
    constraint CLIENTI_EMAIL_CHK check(email like '%@%.%')
);

alter table clienti
add constraint CLIENTI_CNP_CHK
check ( length(cnp) = 13 and
    case 
        when substr(cnp, 1, 1) in ('5', '6', '7', '8') then to_date('20' || substr(cnp, 2, 6), 'yyyymmdd')
        when substr(cnp, 1, 1) in ('1', '2') then to_date('19' || substr(cnp, 2, 6), 'yyyymmdd')
        when substr(cnp, 1, 1) in ('3', '4') then to_date('18' || substr(cnp, 2, 6), 'yyyymmdd')
        else null
    end is not null and --- data este valida
    to_number(substr(cnp, 8, 2)) >= 1 and
    to_number(substr(cnp, 8, 2)) <= 52 and --- judetul este valid 
    to_char(
    mod(
        (
            substr(cnp, 1, 1) * 2 +
            substr(cnp, 2, 1) * 7 +
            substr(cnp, 3, 1) * 9 +
            substr(cnp, 4, 1) * 1 +
            substr(cnp, 5, 1) * 4 +
            substr(cnp, 6, 1) * 6 +
            substr(cnp, 7, 1) * 3 +
            substr(cnp, 8, 1) * 5 +
            substr(cnp, 9, 1) * 8 +
            substr(cnp, 10, 1) * 2 +
            substr(cnp, 11, 1) * 7 +
            substr(cnp, 12, 1) * 9
        ), 11)
    ) = substr(cnp, 13, 1) --- cifra de control
);

create sequence autonumerotare_servicii_contractate
    start with 1
    increment by 1
    maxvalue 9999999;

create table servicii_contractate(
    id_serviciu_contractat number(7,0) default autonumerotare_servicii_contractate.NEXTVAL,
    cnp_client varchar2(13)
        constraint SERVICII_CONTRACTATE_CNP_CLIENT_NN not null,
    id_serviciu number(5,0)
        constraint SERVICII_ID_SERVICIU_CNP_CLIENT_NN not null,
    
    constraint SERVICII_CONTRACTATE_ID_SERVICIU_CONTRACTAT_PK primary key (id_serviciu_contractat),
    constraint SERVICII_CONTRACTATE_CNP_CLIENT_FK foreign key (cnp_client) 
                references clienti(cnp) on delete cascade,
    constraint SERVICII_CONTRACTATE_ID_SERVICIU foreign key (id_serviciu)
                references servicii(id_serviciu) on delete cascade,
    constraint SERVICII_CONTRACTATE_ID_SERVICIU_CNP_UNQ unique(id_serviciu, cnp_client)
);

create sequence autonumerotare_reduceri
    start with 1
    increment by 1
    maxvalue 99999;

create table reduceri (
    id_reducere number(5,0) default autonumerotare_reduceri.NEXTVAL,
    nume_reducere varchar2(40) 
        constraint REDUCERI_NUME_REDUCERE_NN not null,
    procent number(4,2)
        constraint REDUCERI_PROCENT_NN not null,
    id_serviciu number(5,0)
        constraint REDUCERI_ID_SERVICIU not null,
    
    constraint REDUCERI_ID_REDUCERE_PK primary key (id_reducere),
    constraint REDUCERI_ID_SERVICIU_FK foreign key (id_serviciu)
        references servicii(id_serviciu) on delete cascade,
    constraint REDUCERI_PROCENT_CHK CHECK (procent<>0)
);

create sequence autonumerotare_echipamente
    start with 1
    increment by 1
    maxvalue 99999;

create table echipamente (
    id_echipament number(5,0) default autonumerotare_echipamente.NEXTVAL,
    nume_echipament varchar2(20)
        constraint NUME_ECHIPAMENT_NN not null,
    pret_lunar number(5,2),
    pret_distrugere number(6,2),
    id_serviciu number(5,0),
    
    constraint ECHIPAMENTE_ID_ECHIPAMENT_PK primary key (id_echipament),
    constraint ECHIPAMENTE_ID_SERVICIU_FK foreign key (id_serviciu)
        references servicii(id_serviciu) on delete set null,
    constraint ECHIPAMENTE_PRET_CHK check (pret_lunar is null 
                                or pret_distrugere is null
                                or pret_lunar < pret_distrugere)
    
);

create sequence autonumerotare_facturi
    start with 1
    increment by 1
    maxvalue 9999999;

create table facturi(
    id_factura number(7,0) default autonumerotare_facturi.NEXTVAL,
    valoare number(6,2)
        constraint FACTURI_VALOARE_NN not null,
    data_emitere date default sysdate
        constraint FACTURI_DATA_EMITERE_NN not null,
    valoare_platita number(6,2) default 0,
    cnp_client varchar2(13)
        constraint FACTURI_CNP_CLIENT_NN not null,
    
    constraint FACTURI_ID_FACTURA_PK primary key (id_factura),
    constraint FACTURI_CNP_CLIENT_FK foreign key (cnp_client)
        references clienti(cnp) on delete cascade
);

create sequence autonumerotare_sesizari
    start with 1
    increment by 1
    maxvalue 999999;

create table sesizari(
    id_sesizare number(6,0) default autonumerotare_sesizari.nextval,
    data_remediere date,
    data_inregistrare date default sysdate
        constraint SESIZARI_DATA_REMEDIERE_NN not null,
    tel_client varchar(10)
        constraint SESIZARI_TEL_CLIENT_NN not null,
    id_serviciu number(5,0)
        constraint SESIZARI_ID_SERVICIU_NN not null,
    
    constraint SESIZARI_ID_SESIZARE_PK primary key (id_sesizare),
    constraint SESIZARI_ID_SERVICIU_FK foreign key (id_serviciu)
        references servicii(id_serviciu) on delete cascade,
    constraint SESIZARI_TEL_CLIENT_CHK check(length(tel_client) = 10 and tel_client like '07%')
);

create sequence autonumerotare_remedieri
    start with 1
    increment by 1
    maxvalue 999999;

create table remedieri (
    id_remediere number(6,0) default autonumerotare_remedieri.NEXTVAL,
    id_sesizare number(6,0)
        constraint REMEDIERI_ID_SESIZARE_NN not null,
    cnp_angajat varchar2(13)
        constraint REMEDIERI_CNP_ANGAJAT_NN not null,
    
    constraint REMEDIERI_ID_REMEDIERE_PK primary key (id_remediere),
    constraint REMEDIERI_ID_SESIZARE_FK foreign key (id_sesizare)
        references sesizari(id_sesizare) on delete cascade,
    constraint REMEDIERI_CNP_ANGAJAT_FK foreign key (cnp_angajat)
        references angajati(cnp) on delete cascade,
    constraint REMEDIERI_ID_SESIZARE_CNP_UNQ unique(id_sesizare, cnp_angajat)
);

insert into servicii (nume_serviciu, pret_lunar)
values ('Televiziune Analogica', 30);
insert into servicii (nume_serviciu, pret_lunar)
values ('Televiziune Digitala', 30);
insert into servicii (nume_serviciu, pret_lunar)
values ('Stocare Cloud 100GB', 15);
insert into servicii (nume_serviciu, pret_lunar)
values ('Telefonie fixa', 15);
insert into servicii (nume_serviciu, pret_lunar)
values ('Telefonie mobila nelimitat', 30);
insert into servicii (nume_serviciu, pret_lunar)
values ('Internet', 45);

insert into echipamente(nume_echipament, pret_distrugere, id_serviciu)
select 'Modem', 100, id_serviciu
from servicii
where nume_serviciu = 'Internet';
insert into echipamente(nume_echipament, pret_lunar, pret_distrugere, id_serviciu)
select 'Telefon fix', 5, 60, id_serviciu
from servicii
where nume_serviciu = 'Telefonie fixa';
insert into echipamente(nume_echipament)
values ('Antena parabolica');
insert into echipamente(nume_echipament, id_serviciu)
select 'Hub RJ-45', id_serviciu
from servicii
where nume_serviciu = 'Internet';
insert into echipamente(nume_echipament, id_serviciu, pret_distrugere)
select 'Wi-Fi-Router', id_serviciu, 100
from servicii
where nume_serviciu = 'Internet';
insert into echipamente(nume_echipament, id_serviciu, pret_distrugere)
select 'Wi-Fi-Extender', id_serviciu, 50
from servicii
where nume_serviciu = 'Internet';
insert into echipamente(nume_echipament, id_serviciu)
select 'Splitter Coaxial', id_serviciu
from servicii
where nume_serviciu = 'Televiziune Analogica';

insert into reduceri(nume_reducere, procent, id_serviciu)
select 'Internet - Anul nou', 14.99, id_serviciu
from servicii
where nume_serviciu = 'Internet';
insert into reduceri(nume_reducere, procent, id_serviciu)
select 'Promovare cloud 99.99%', 99.99, id_serviciu
from servicii
where nume_serviciu = 'Stocare Cloud 100GB';

insert into reduceri(nume_reducere, procent, id_serviciu)
select 'Reducere aniversara serviciu ' || to_char(id_serviciu), 5.00, id_serviciu
from servicii;
--- orice asemanare
--- cu persoane reale
--- e pur intamplatoare

insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1910708519781', 'Dorel', 'Fixescu', '0739394141',
    'dorica@nicemail.ro', 'Splaiul Independentei 204, Sector 6, Bucuresti');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('6000813181279', 'Iasmina', 'Iasminescu', '0712312345',
    'iasmi@gmail.ro', 'Bulevardul Iuliu Maniu 115, Sector 6, Bucuresti');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('2980701183652', 'Carmen', 'Bob', '0712312346',
    'carmenb@gmail.ro', 'Bulevardul Iuliu Maniu 114, Sector 6, Bucuresti');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('5011119445244', 'Adrian', 'Bosu', '0712312347',
    'adrian@pharaon.com', 'Bulevardul Iuliu Maniu 116, Sector 6, Bucuresti');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('2930705193748', 'Adele', 'Tadacsz', '0712312348',
    'adeltd@gmail.hu', 'Drumul Taberei 6, Sector 6, Bucuresti');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1891023031385', 'Iustin', 'Somn', '0712312350',
    'iustin@zzz.ro', 'Atomistilor 43, Magurele, Ilfov');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1990910011035', 'Vladut', 'Caserola', '0712312351',
    'vladutu@albaiulia.ro', 'Bulevardul Horea 5, Alba Iulia');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1980208388780', 'Costica', 'Vrajeala', '0712312352',
    'costi@yahoo.ro', 'Strada Sfintii Apostoli 20, Craiova, Dolj');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('5050704403270', 'Gigel', 'Ploae', '0712312353',
    'gigi57@sunnyday.com', 'Strada Nucilor 1, Solesti, Vaslui');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('6050520526165', 'Maria', 'Tarpan', '0712312354',
    'mariatarp@google.com', 'Strada Rahova 7, Calarasi');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('5011212032176', 'Gigi', 'Garfield', '0712312355',
    'ggarfield@googl.ro', 'Strada Florilor 3, Timisoara');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('2900321110294', 'Sofia', 'Diaconu', '0712312356',
    'sofyd@yahoo.com', 'Bulevardul Eroilor 40, Caransebes');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1961201192345', 'Razvan', 'Constantinescu', '0712312357',
    'razvconst@gmail.ro', 'Strada Stefan cel Mare 10, Covasna');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('2930529159365', 'Roxana', 'Nistor', '0712312358',
    'roxinist@yahoo.com', 'Strada Stefan cel Mare 10, Targoviste');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('5030103062732', 'Daniel', 'Ungureanu', '0712312359',
    'dung@yahoo.com', 'Strada 1 Mai, Bistrita');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('2980228329757', 'Bianca', 'Moldovan', '0712312360',
    'moldobianca@gmail.com', 'Strada Orasului 5, Sibiu');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('6041215026605', 'Mihaela', 'Dragomir', '0723456780',
       'mihaela.dragomir@example.com', 'Bulevardul Iancu de Hunedoara 15, Bucuresti');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('6050607443890', 'Alexandra', 'Florescu', '0745678902',
       'alexandra.florescu@example.com', 'Strada Republicii 20, Brasov');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1940411128930', 'Razvan', 'Dumitrascu', '0734567891',
       'razvan.dumitrascu@example.com', 'Bulevardul 1 Decembrie 1918 30, Cluj-Napoca');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('5031118062812', 'Andrei', 'Georgescu', '0712345679',
       'andrei.georgescu@example.com', 'Strada Avram Iancu 5, Timisoara');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('5000517221905', 'Catalin', 'Popa', '0734567892',
       'catalin.popa@example.com', 'Bulevardul Unirii 10, Iasi');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('2950718289279', 'Andreea', 'Stanciu', '0723456781',
       'andreea.stanciu@example.com', 'Strada Libertatii 25, Constanta');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1920614307043', 'Cristi', 'Popescu', '0734567893',
       'cristi.popescu@example.com', 'Aleea Crizantemelor 7, Galati');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('1930926254541', 'Simon', 'Iacob', '0723456784',
       'simon.iacob@example.com', 'Strada Mihai Eminescu 5, Suceava');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa)
values('2961215258032', 'Andreea', 'Balan', '0712345676',
       'andreea.balan@example.com', 'Bulevardul Stefan cel Mare 12, Bacau');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa, data_inregistrare)
values('1961117510120', 'Iulian', 'Florea', '0734567894',
       'iulian.florea@example.com', 'Strada Unirii 7, Buzau',
       '2023-11-25');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa, data_inregistrare)
values('6030505323570', 'Gabriela', 'Manole', '0723456785',
       'gabriela.manole@example.com', 'Bulevardul Decebal 20, Pitesti',
       '2023-09-10');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa, data_inregistrare)
values('5020322277006', 'Adi', 'Pop', '0734567895',
       'Adi.pop@example.com', 'Strada Libertatii 25, Oradea',
       '2023-10-21');
insert into clienti(cnp, prenume, nume, nr_tel, email, adresa, data_inregistrare)
values('5000319336330', 'Adrian', 'Mocanu', '0712345677',
       'adrian.mocanu@example.com', 'Strada 1 Decembrie 1918 15, Sibiu',
       '2023-11-10');

insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare)
values('1910708519781', 'Dorel', 'Fixescu', '0739394141', --- este si client si angajat
    'dorica@nicemail.ro', 6000, 'Inginer retea', '2023-08-10');
insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare)
values('1910910095959', 'Petrica', 'Fixescu', '0739394103',
    'petrica@fixit.ro', 6000, 'Inginer retea', '2023-08-10');    
insert into angajati(cnp, prenume, nume, nr_tel, email, salariu)
select cnp, prenume, nume, nr_tel,
       email, 7000
from clienti
where cnp = '6041215026605';
insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare, cnp_manager)
values('5040422311751', 'Mihai', 'Dragomiroiu', '0723456781',
       'mihaidrag@gmail.com', 6000, 'Operator date', '2023-12-10', '6041215026605');
       
insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare, cnp_manager)
values('6010506512024', 'Clara', 'Manjescu', '0723456782',
        'claram2@yahoo.com', 4000, 'Operator date jr', sysdate, '5040422311751');
        
insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare, cnp_manager)        
values('6040715255345', 'Mara', 'Manolescu', '0723456783',
        'maraman@yahoo.com', 4000, 'Operator date jr' , '2023-12-15', '5040422311751');
        
--- o mica ierarhie manageriala
---          6041215026605
---                 |
---           5040422311751
---            /          \
--- 6010506512024        6040715255345

insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare)
values('5051221181146', 'Gabriel', 'Condurachi', '0745352515',
        'gabicond@tuta.io', 9000, 'Programator Frontend', '2023-10-03');

insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare)
values('5011213407676', 'Omar', 'Panda', '0712121314',
        'pandomar@pandamail.co', 10000, 'Programator Backend', '2023-10-03');

insert into angajati(cnp, prenume, nume, nr_tel, email, salariu, rol, data_angajare)
values('1921120306604', 'Vlad', 'Chichita', '0734517821',
        'chivladta@domainmail.ctr', 9000, 'Administrator retea', '2023-08-27');



insert into servicii_contractate(cnp_client, id_serviciu)
select c.cnp, (
                    select id_serviciu
                    from servicii
                    where nume_serviciu = 'Internet'
                    )
from clienti c
where c.cnp like '1%' or c.cnp like '6%';

insert into servicii_contractate(cnp_client, id_serviciu)
select c.cnp, (
                    select id_serviciu
                    from servicii
                    where nume_serviciu = 'Telefonie fixa'
                )
from clienti c
where lower(c.adresa) like '%sibiu%';

insert into servicii_contractate(cnp_client, id_serviciu)
select c.cnp, (
                    select id_serviciu
                    from servicii
                    where nume_serviciu = 'Telefonie mobila nelimitat'
                )
from clienti c
where nr_tel like '071%';

insert into servicii_contractate(cnp_client, id_serviciu)
select c.cnp, (
                    select id_serviciu
                    from servicii
                    where nume_serviciu = 'Stocare Cloud 100GB'
                )
from clienti c
where email like '%@example.com';

insert into servicii_contractate(cnp_client, id_serviciu)
select c.cnp, (
                    select id_serviciu
                    from servicii
                    where nume_serviciu = 'Televiziune Analogica'
                )
from clienti c
where lower(adresa) like '%bucuresti%' and lower(adresa) like '%sector 6%';

insert into servicii_contractate(cnp_client, id_serviciu)
select c.cnp, (
                    select id_serviciu
                    from servicii
                    where nume_serviciu = 'Televiziune Digitala'
                )
from clienti c
where not (lower(adresa) like '%bucuresti%' and lower(adresa) like '%sector 6%');

insert into sesizari(tel_client, id_serviciu, data_inregistrare)
select '0739394141', id_serviciu, '2024-01-09'
    from servicii
    where nume_serviciu = 'Internet';

insert into sesizari(tel_client, id_serviciu)
select '0712312347', id_serviciu
    from servicii
    where nume_serviciu = 'Telefonie mobila nelimitat';

insert into sesizari(tel_client, id_serviciu, data_inregistrare)
select nr_tel, id_serviciu, sysdate - 2
from servicii join servicii_contractate using (id_serviciu)
            join clienti on(cnp = cnp_client)
where nume_serviciu like 'Televiziune%' and 
    (lower(adresa) like '%iuliu maniu%'
        or lower(adresa) like '%ilfov%');

insert into sesizari(tel_client, id_serviciu, data_inregistrare)
select nr_tel, id_serviciu, '2024-01-05'
    from servicii_contractate join clienti on (cnp_client = cnp)
    where nr_tel = '0712312350';
insert into sesizari(tel_client, id_serviciu, data_inregistrare)
select nr_tel, id_serviciu, '2024-01-05'
    from servicii_contractate join clienti on (cnp_client = cnp)
    where nr_tel = '0712312345';


insert into remedieri(id_sesizare, cnp_angajat)
values(1, '1910708519781');

insert into remedieri(id_sesizare, cnp_angajat)
values(1, '1910910095959');

update sesizari
set data_remediere = '2024-01-10'
where id_sesizare = 1;

insert into remedieri(id_sesizare, cnp_angajat)
select unique ses.id_sesizare , a.cnp
from sesizari ses join servicii s on(ses.id_serviciu = s.id_serviciu)
        join servicii_contractate sc on (s.id_serviciu = sc.id_serviciu)
        join clienti c on(c.cnp = sc.cnp_client) 
            join angajati a on(a.nume = 'Fixescu')
where ses.data_remediere is null and s.nume_serviciu like 'Televiziune%' and 
    lower(c.adresa) like '%iuliu maniu%';

insert into remedieri(id_sesizare, cnp_angajat)
select id_sesizare, '1910708519781'
from sesizari
where id_sesizare >= 6 and id_sesizare <=9;

insert into remedieri(id_sesizare, cnp_angajat)
select id_sesizare, '6040715255345'
from sesizari
where id_sesizare >= 6 and id_sesizare <=9;

insert into remedieri(id_sesizare, cnp_angajat)
select id_sesizare, '5011213407676'
from sesizari
where id_sesizare >= 6 and id_sesizare <=9;

update sesizari
set data_remediere = sysdate
where data_remediere is null and id_sesizare in (
    select id_sesizare
    from sesizari join remedieri using (id_sesizare)
); --- update tuturor sesizarilor carora le-a aparut o remediere intre timp

insert into facturi(cnp_client, valoare, data_emitere)
values ('1961117510120', 64.5, '24-12-25');

insert into facturi(cnp_client, valoare, data_emitere)
values('6030505323570', 75.15, '23-10-10');

insert into facturi(cnp_client, valoare, data_emitere)
values('6030505323570', 75.15, '23-11-10');

insert into facturi(cnp_client, valoare, data_emitere)
values('6030505323570', 64.5, '23-12-10');

insert into facturi(cnp_client, valoare, data_emitere)
values('6030505323570', 64.5, '24-01-10');

insert into facturi(cnp_client, valoare, data_emitere)
values('5020322277006', 30, '23-11-21');

insert into facturi(cnp_client, valoare, data_emitere)
values ('5020322277006', 28.5, '23-12-21');

insert into facturi(cnp_client, valoare, data_emitere)
values ('5000319336330', 76, '23-12-10');

insert into facturi(cnp_client, valoare, data_emitere)
values ('5000319336330', 76, '24-01-10');

update facturi
set valoare_platita = valoare
where cnp_client <> '1961117510120';

commit;




