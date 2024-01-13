select rol, 
       count(cnp) nr_angajati,
       (select nume || ' ' || prenume
        from angajati a2
        where a.cnp_manager = a2.cnp) nume_manager,
       cnp_manager
from angajati a
group by rol, cnp_manager
having count(cnp) > 1;

--- sa se afiseze rolul comun al angajatilor cu acelasi manager, numarul lor, precum si cnp-ul managerului si numele sau