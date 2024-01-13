select distinct nume, prenume, nr_tel
    from clienti c join facturi f 
                        on (f.cnp_client = c.cnp)
                    join servicii_contractate sc
                        on (c.cnp = sc.cnp_client)
                    join servicii serv
                        on (serv.id_serviciu = sc.id_serviciu)
    where extract(year from f.data_emitere) = 2023 and 
        not exists(
            select 'pizza'
            from sesizari ses
            where c.nr_tel = ses.tel_client and id_serviciu = (
                select id_serviciu
                from servicii
                where lower(nume_serviciu) = 'telefonie mobila nelimitat'
            )
        );

--- numele, prenumele și numărul de telefon pentru clientii care au facturi emise in 2023 si care nu au avut sesizari deschise la serviciul 'Telefonie mobila nelimitat'