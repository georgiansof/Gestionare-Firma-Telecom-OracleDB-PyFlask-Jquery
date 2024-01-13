from flask import Flask, render_template, request
import cx_Oracle
import numpy as np
from datetime import datetime
import re
import regex
from numbers import Number

username = 'app_user'
password = 'oracle'
dsn = 'localhost:1521/xe' 

app = Flask(__name__)

table_names = None
connection = None
cursor = None


def normalize_values(value):
    if value is None:
        return 'Nespecificat'
    if(type(value) == type(datetime.now())):
        formatted_date = value.strftime("%Y-%m-%d")
        return formatted_date
    return value

def verify_tel_exists(tel):
    sqlquery = 'SELECT 1 FROM CLIENTI WHERE nr_tel = \'' + tel + '\''
    cursor.execute(sqlquery)
    client = cursor.fetchall()
    if(len(client) > 0):
        return None
    else:
        return 'Nu exista niciun client cu numărul de telefon ' + tel

def update_sesizari(old_tel, new_tel):
    sqlquery = 'UPDATE SESIZARI SET TEL_CLIENT = \'' + new_tel + '\'' + ' WHERE TEL_CLIENT = \'' + old_tel + '\''
    print(sqlquery)
    cursor.execute(sqlquery)

@app.route('/')
def index():
    return render_template('index.html', tables = table_names)

@app.route('/cerinta_c')
def cerinta_c():
    return render_template('cerinta_c.html')

@app.route('/exec_page_c_sql', methods = ['POST'])
def exec_page_c_sql():
    sqlquery = "select distinct nume, prenume, nr_tel \
    from clienti c join facturi f \
                        on (f.cnp_client = c.cnp) \
                    join servicii_contractate sc \
                        on (c.cnp = sc.cnp_client) \
                    join servicii serv \
                        on (serv.id_serviciu = sc.id_serviciu) \
    where extract(year from f.data_emitere) = 2023 and \
        not exists( \
            select 'pizza' \
            from sesizari ses \
            where c.nr_tel = ses.tel_client and id_serviciu = ( \
                select id_serviciu \
                from servicii \
                where lower(nume_serviciu) = 'telefonie mobila nelimitat' \
            ) \
        )"
    try:
        cursor.execute(sqlquery)
        rows = cursor.fetchall()
        if rows:
            # Extract column names from cursor.description
            column_names = [desc[0] for desc in cursor.description]

            # Generate HTML table
            table_html = '<table border="1"><tr>'
            table_html += ''.join(f'<th>{col}</th>' for col in column_names)
            table_html += '</tr>'

            for row in rows:
                table_html += '<tr>'
                table_html += ''.join(f'<td>{value}</td>' for value in row)
                table_html += '</tr>'

            table_html += '</table>'
            return table_html

        return 'Nu s-au gasit date in tabel'
    except cx_Oracle.Error as error:
        return f'Eroare în timpul interogării: {error}'




@app.route('/cerinta_d')
def cerinta_d():
    return render_template('cerinta_d.html')

@app.route('/exec_page_d_sql', methods = ['POST'])
def exec_page_d_sql():
    sqlquery = "select rol, \
                    count(cnp) nr_angajati, \
                    (select nume || ' ' || prenume \
                        from angajati a2 \
                        where a.cnp_manager = a2.cnp) nume_manager, \
                    cnp_manager \
                from angajati a \
                group by rol, cnp_manager \
                having count(cnp) > 1"
    try:
        cursor.execute(sqlquery)
        rows = cursor.fetchall()
        if rows:
            # Extract column names from cursor.description
            column_names = [desc[0] for desc in cursor.description]

            # Generate HTML table
            table_html = '<table border="1"><tr>'
            table_html += ''.join(f'<th>{col}</th>' for col in column_names)
            table_html += '</tr>'

            for row in rows:
                table_html += '<tr>'
                table_html += ''.join(f'<td>{value}</td>' for value in row)
                table_html += '</tr>'

            table_html += '</table>'
            return table_html

        return 'Nu s-au gasit date in tabel'
    except cx_Oracle.Error as error:
        return f'Eroare în timpul interogării: {error}'

@app.route('/cerinta_f')
def cerinta_f():
    return render_template('cerinta_f.html')

@app.route('/remove_view_entry', methods = ['POST'])
def remove_view_entry():
    rowValues = request.get_json()['rowValues']
    nr_tel = rowValues[2]
    data_emitere = rowValues[5]
    sqlquery = f'DELETE \
                FROM facturi \
                WHERE cnp_client = ( \
                    SELECT cnp \
                    FROM clienti \
                    WHERE nr_tel = \'{nr_tel}\' \
                ) and data_emitere = TO_DATE(\'{data_emitere}\', \'YYYY-MM-DD\')'

    print(sqlquery)
    cursor.execute(sqlquery)
    connection.commit()
    return 'ok'

@app.route('/modify_view_entry', methods = ['POST'])
def modify_view_entry():
    rowValues = request.get_json()['rowValues']
    id_factura = rowValues[4]

    view_columns = None
    sqlquery = 'SELECT COLUMN_NAME \
                FROM USER_TAB_COLUMNS \
                WHERE TABLE_NAME = \'FACTURI_CLIENTI\' \
                '

    cursor.execute(sqlquery)
    view_columns = cursor.fetchall()
    view_columns = [col[0] for col in view_columns]

    view_rows = None

    sqlquery = 'SELECT * from facturi_clienti'
    cursor.execute(sqlquery)
    view_rows = cursor.fetchall()

    table_html = '<table border="1"><tr>'
    table_html += '<th>Acțiuni</th>'
    table_html += ''.join(f'<th>{col}</th>' for col in view_columns)
    table_html += '</tr>'

    i=1
    for row in view_rows:
        table_html += '<tr>'
        if normalize_values(view_rows[i-1][4]) != int(id_factura):
            table_html += f'<td><button onclick="modifyViewEntry(this)" id="buton-modificare-rand-' + str(i) + '">Modificare</button><button onclick="deleteViewEntry(this)" id="buton-stergere-rand-' + str(i) + '">Stergere</button></td>'
            table_html += ''.join(f'<td class="td-row-{i}">{normalize_values(value)}</td>' for value in row)
        else:
            table_html += '<td><button onclick="submitViewModification(this)" id="trimitere-modificare-' + str(i) + '">Salvează</button><button onclick="show_view_facturi_clienti()" id="renuntare-modificare">Renunță</button></td>'
            table_html += ''.join(f'<td class="td-row-{i}">{normalize_values(value)}</td>' for j, value in enumerate(row[0:5]))
            table_html += ''.join(f'<td><input class="td-row-{i}" id="input-modificare-rand-{j + 1}" value="{normalize_values(value)}"></td>' for j, value in enumerate(row[5:]))
        table_html += '</tr>'
        i+=1

    table_html += '</table>'
    return table_html

@app.route('/submit_view_modification', methods = ['POST'])
def submit_view_modification():
    json = request.get_json()
    old_values = json['oldRowValues']
    values = json['rowValues']

    view_columns = None
    sqlquery = 'SELECT COLUMN_NAME \
                FROM USER_TAB_COLUMNS \
                WHERE TABLE_NAME = \'FACTURI_CLIENTI\' \
                '
    cursor.execute(sqlquery)
    view_columns = cursor.fetchall()
    view_columns = [col[0] for col in view_columns]

    view_column_types = ['VARCHAR2', 'VARCHAR2', 'VARCHAR2', 'VARCHAR2', 'NUMBER', 'DATE', 'NUMBER', 'NUMBER']

    id_factura = values[4]

    error_prohibited_characters = 'Valorile introduse contin caractere care sunt interzise in anumite locuri.'

    for value in values:
        if "'" in str(value):
            return error_prohibited_characters
    
    for i in range(len(values)):
        if view_column_types[i].upper() == 'DATE' and not re.search(r'^(\d{4}\-\d{1,2}\-\d{1,2})$', values[i]):
            return 'Data este în format greșit. Ar trebui să fie "YYYY-(M)M-(D)D"'

    sqlquery = f' \
        UPDATE facturi_clienti \
        SET '
    
    diff = False

    for i in range(5, 8):
        if values[i] != old_values[i]:    
            diff = True
            sqlquery += f"{view_columns[i]} = "
            
            if view_column_types[i] == 'DATE' and values[i].lower() != 'nespecificat':
                sqlquery += 'TO_DATE('

            if view_column_types[i] != 'NUMBER' and values[i].lower() != 'nespecificat':
                sqlquery += "'"
            
            if values[i] != 'nespecificat':
                sqlquery += values[i]
            else:
                sqlquery += 'null'

            
            if view_column_types[i] != 'NUMBER' and values[i].lower() != 'nespecificat':
                sqlquery += "'"
            
            if view_column_types[i] == 'DATE' and values[i].lower() != 'nespecificat':
                sqlquery += ", 'YYYY-MM-DD')"

            sqlquery += ','
    
    sqlquery = sqlquery[:-1]

    if not diff:
        return 'ok'

    sqlquery += ' WHERE ' + view_columns[4] + ' = ' + id_factura
    
    print(sqlquery)
    try:
        cursor.execute(sqlquery)
    except Exception as err:
        return str(err)

    connection.commit()
    return 'ok'
        

@app.route('/show_view_remedieri_per_rol', methods = ['POST'])
def show_view_remedieri_per_rol():
    sqlquery = 'SELECT * from remedieri_per_rol'
    cursor.execute(sqlquery)
    rows = cursor.fetchall()
    if rows:
            column_names = [desc[0] for desc in cursor.description]

            # Generate HTML table
            table_html = '<table border="1"><tr>'
            table_html += ''.join(f'<th>{col}</th>' for col in column_names)
            table_html += '</tr>'

            i=1
            for row in rows:
                table_html += '<tr>'
                table_html += ''.join(f'<td>{value}</td>' for value in row)
                table_html += '</tr>'
                i+=1

            table_html += '</table>'
            return table_html

    return 'Nu s-au gasit date in tabel'

@app.route('/show_view_facturi_clienti', methods = ['POST'])
def show_view_facturi_clienti():
    sqlquery = 'SELECT * from facturi_clienti'
    cursor.execute(sqlquery)
    rows = cursor.fetchall()
    rows = map(normalize_values, rows)
    if rows:
            column_names = [desc[0] for desc in cursor.description]

            # Generate HTML table
            table_html = '<table border="1"><tr>'
            table_html += '<th>Acțiuni</th>'
            table_html += ''.join(f'<th>{col}</th>' for col in column_names)
            table_html += '</tr>'

            i=1
            for row in rows:
                table_html += '<tr>'
                table_html += '<td><button onclick="modifyViewEntry(this)" id="buton-modificare-rand-' + str(i) + '">Modificare</button><button onclick="deleteViewEntry(this)" id="buton-stergere-rand-' + str(i) + '">Stergere</button></td>'
                table_html += ''.join(f'<td class="td-row-{i}">{normalize_values(value)}</td>' for value in row)
                table_html += '</tr>'
                i+=1

            table_html += '</table>'
            return table_html

    return 'Nu s-au gasit date in tabel'

@app.route('/create_view_remedieri_per_rol', methods = ['POST'])
def create_view_remedieri_per_rol():
    sqlquery = 'create or replace view remedieri_per_rol as \
                (select rol, count(id_remediere) nr_remedieri \
                from angajati left join remedieri \
                        on (cnp = cnp_angajat) \
                group by rol \
                having rol is not null)'
    cursor.execute(sqlquery)
    return 'View-ul remedieri_per_rol a fost creat.'

@app.route('/create_view_facturi_clienti', methods = ['POST'])
def create_view_facturi_clienti():
    sqlquery = 'create or replace view facturi_clienti as \
                (select nume, prenume, nr_tel, email,  \
                        id_factura, data_emitere, valoare_platita, valoare \
                from clienti join facturi \
                                on (cnp_client = cnp) \
                where valoare_platita <= valoare \
                ) \
                with check option constraint FACTURI_CLIENTI_CHK'
    cursor.execute(sqlquery)
    return 'View-ul facturi_clienti a fost creat.'

@app.route('/modify_row', methods = ['POST'])
def modify_row():
    req = request.get_json()
    current_table = req['table']
    rowValues = req['rowValues']
    
    cursor.execute("SELECT COLUMN_NAME \
                FROM USER_TAB_COLUMNS \
                WHERE TABLE_NAME = '" + current_table + "'")
    current_table_columns = cursor.fetchall()
    current_table_columns = [col[0] for col in current_table_columns]

    cursor.execute('SELECT * FROM ' + current_table)
    current_table_rows = cursor.fetchall()

    table_html = '<table border="1"><tr>'
    table_html += '<th>Acțiuni</th>'
    table_html += ''.join(f'<th>{col}</th>' for col in current_table_columns)
    table_html += '</tr>'

    i=1
    for row in current_table_rows:
        table_html += '<tr>'
        if str(row[0]) != str(rowValues[0]):
            table_html += '<td><button onclick="modifyEntry(this)" id="buton-modificare-rand-' + str(i) + '">Modificare</button><button onclick="deleteEntry(this)" id="buton-stergere-rand-' + str(i) + '">Stergere</button></td>'
            table_html += ''.join(f'<td class="td-row-{i}">{normalize_values(value)}</td>' for value in row)
        else:
            table_html += '<td><button onclick="submitModification(this)" id="trimitere-modificare-' + str(i) + '">Salvează</button><button onclick="showTable()" id="renuntare-modificare">Renunță</button></td>'
            table_html += ''.join(f'<td><input class="td-row-{i}" id="input-modificare-rand-{j + 1}" value="{normalize_values(value)}"></td>' for j, value in enumerate(row))
        table_html += '</tr>'
        i+=1

    table_html += '</table>'
    return table_html



@app.route('/remove_row', methods = ['POST'])
def remove_row():
    req = request.get_json()
    selectedRowValues = req['values']
    current_table = req['table']

    print(current_table)
    print(selectedRowValues)

    cursor.execute("SELECT COLUMN_NAME \
                FROM USER_TAB_COLUMNS \
                WHERE TABLE_NAME = '" + current_table + "'")
    current_table_columns = cursor.fetchall()
    current_table_columns = [col[0] for col in current_table_columns]

    cursor.execute("SELECT DATA_TYPE \
        FROM USER_TAB_COLUMNS \
        WHERE TABLE_NAME = '" + current_table + "'")
    column_types = cursor.fetchall()
    column_types = [col[0] for col in column_types]

    sqlquery = 'DELETE \
                    FROM ' + current_table + '\
                    WHERE ' + current_table_columns[0] + \
                        '= '
    sqlquery += ("'" + selectedRowValues[0] + "'") if column_types[0].upper() != 'NUMBER' \
                else str(selectedRowValues[0])
    print(sqlquery)
    cursor.execute(sqlquery)
    connection.commit()
    return 'ok'


@app.route('/get_table_columns', methods = ['POST'])
def get_table_columns():
    selected_table = request.form['selected_table']
    try:
        cursor.execute("SELECT COLUMN_NAME \
                        FROM USER_TAB_COLUMNS \
                        WHERE TABLE_NAME = '" + selected_table + "'")
        htmlcode = ""
        col_names = cursor.fetchall()
        i = 1
        for col in col_names:
            htmlcode += '<input class="sorting-priorities" oninput="verifyPriorityInput(this)" id="sorting-priority-input-"' \
                        + str(i) \
                        + '" type="number" value="0">  <li value="' \
                        + col[0] \
                        + '">'  \
                        + col[0] \
                        + '</li><select id="sorting-type-selector-' \
                        + str(i) \
                        + '"><option value="asc">Ascendent</option><option value="desc">Descendent</option></select><br>'
            i+=1

        return htmlcode
    except cx_Oracle.Error as error:
        return f'Error fetching data: {error}'

@app.route('/get_table_data', methods=['POST'])
def get_table_data():
    request_data = request.get_json()
    selected_table = request_data['selected_table']
    sortQuery = request_data['sortQuery']
    sortingPriorities = request_data['sortingPriorities']
    sortingTypes = request_data['sortingTypes']
    try:
        sortingColumnsCount = len([x for x in sortingPriorities if x != 0])
        
        sqlquery = 'SELECT * FROM ' + selected_table


        cursor.execute("SELECT COLUMN_NAME \
            FROM USER_TAB_COLUMNS \
            WHERE TABLE_NAME = '" + selected_table + "'")
        column_names = cursor.fetchall()
        cursor.execute("SELECT DATA_TYPE \
            FROM USER_TAB_COLUMNS \
            WHERE TABLE_NAME = '" + selected_table + "'")
        column_types = cursor.fetchall()
        if sortQuery and sortingColumnsCount > 0:
            column_order = np.argsort(np.array(sortingPriorities))
            sqlquery += ' ORDER BY'
            for index in column_order:
                if sortingPriorities[index] == 0:
                    continue
                sqlquery += ' ' + column_names[index][0].upper() + ' ' + sortingTypes[index].upper()
                if sortingColumnsCount > 1:
                    sqlquery += ','
                    sortingColumnsCount -= 1

        print(sqlquery)

        cursor.execute(sqlquery)
        rows = cursor.fetchall()
        if rows:
            # Extract column names from cursor.description
            column_names = [desc[0] for desc in cursor.description]

            # Generate HTML table
            table_html = '<table border="1"><tr>'
            table_html += '<th>Acțiuni</th>'
            table_html += ''.join(f'<th>{col}</th>' for col in column_names)
            table_html += '</tr>'

            i=1
            for row in rows:
                table_html += '<tr>'
                table_html += '<td><button onclick="modifyEntry(this)" id="buton-modificare-rand-' + str(i) + '">Modificare</button><button onclick="deleteEntry(this)" id="buton-stergere-rand-' + str(i) + '">Stergere</button></td>'
                table_html += ''.join(f'<td class="td-row-{i}">{normalize_values(value)}</td>' for value in row)
                table_html += '</tr>'
                i+=1

            table_html += '</table>'
            return table_html

        return 'Nu s-au gasit date in tabel'

    except cx_Oracle.Error as error:
        return f'Eroare în timpul interogării: {error}'

@app.route('/submit_modified_row', methods = ['POST'])
def submit_modified_row():
    request_data = request.get_json()
    current_table = request_data['table']
    selected_table = current_table
    rowValues = request_data['rowValues']
    oldRowValues = request_data['oldRowValues']

    if current_table.upper() == 'CLIENTI':
        old_tel = current_table_rows[rowNumber-1][3]
        new_tel = rowValues[3]

    error_prohibited_characters = 'Valorile introduse contin caractere care sunt interzise in anumite locuri.'

    for value in rowValues:
        if "'" in str(value):
            return error_prohibited_characters

    numeric_string_columns = ['CNP', 'NR_TEL', 'TEL_CLIENT', 'CNP_CLIENT', 'CNP_ANGAJAT', 'CNP_MANAGER']
    

    cursor.execute("SELECT COLUMN_NAME \
        FROM USER_TAB_COLUMNS \
        WHERE TABLE_NAME = '" + selected_table + "'")
    current_table_columns = cursor.fetchall()
    current_table_columns = [col[0] for col in current_table_columns]

    cursor.execute("SELECT DATA_TYPE \
        FROM USER_TAB_COLUMNS \
        WHERE TABLE_NAME = '" + selected_table + "'")
    current_table_column_types = cursor.fetchall()
    current_table_column_types = [col[0] for col in current_table_column_types]

    for i in range(len(current_table_columns)):
        if rowValues[i].lower() == 'nespecificat':
            pass
        else:    
            if current_table_columns[i] in numeric_string_columns:
                for chr in rowValues[i]:
                    if not chr.isdigit():
                        print(chr)
                        return error_prohibited_characters
            else:
                if current_table_column_types[i].upper() == 'DATE' and not re.search(r'^(\d{4}\-\d{1,2}\-\d{1,2})$', rowValues[i]):
                    return 'Data este în format greșit. Ar trebui să fie "YYYY-(M)M-(D)D"'
                else:
                    if current_table_columns[i].upper() in ['NUME', 'PRENUME']:
                        if len(regex.findall(r'^([-\sa-zA-Z\p{L}]+)$', rowValues[i])) == 0:
                            return 'Numele este în format greșit. Poate conține doar spații, cratime și litere mari și mici.'

                    else:
                        if current_table_columns[i].upper() == 'EMAIL':
                            if not re.search(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$', rowValues[i]):
                                return 'E-mailul nu este valid.'


    if current_table.upper() == 'SESIZARI':
        rez = verify_tel_exists(rowValues[3])
        if rez != None:
            return rez

    sqlquery = f' \
        UPDATE {current_table}\
        SET '
    
    diff = False
    for i in range(0, len(current_table_columns)):
        if rowValues[i] != oldRowValues[i]:
            diff = True
            sqlquery += f"{current_table_columns[i]} = "
            
            if current_table_column_types[i] == 'DATE' and rowValues[i].lower() != 'nespecificat':
                sqlquery += 'TO_DATE('

            if current_table_column_types[i] != 'NUMBER' and rowValues[i].lower() != 'nespecificat':
                sqlquery += "'"
            
            if rowValues[i] != 'nespecificat':
                sqlquery += rowValues[i]
            else:
                sqlquery += 'null'

            
            if current_table_column_types[i] != 'NUMBER' and rowValues[i].lower() != 'nespecificat':
                sqlquery += "'"
            
            if current_table_column_types[i] == 'DATE' and rowValues[i].lower() != 'nespecificat':
                sqlquery += ", 'YYYY-MM-DD')"

            sqlquery += ','
    
    sqlquery = sqlquery[:-1]
    if not diff:
        return 'ok'

    sqlquery += ' WHERE ' + current_table_columns[0] + ' = '
    if(current_table_column_types[i] != 'NUMBER'):
        sqlquery += "'"

    sqlquery += str(oldRowValues[0])
    
    if(current_table_column_types[i] != 'NUMBER'):
        sqlquery += "'"

    print(sqlquery)
    try:
        cursor.execute(sqlquery)
    except Exception as err:
        return str(err)
    # REZOLVARE PROBLEME DE INTEGRITATE

    if current_table == 'CLIENTI':
        update_sesizari(old_tel, new_tel)

    connection.commit()
    return 'ok'
        


if __name__ == '__main__':
    try:
        connection = cx_Oracle.connect(user=username, password=password, dsn=dsn)
        cursor = connection.cursor()
        cursor.execute('SELECT TABLE_NAME FROM USER_TABLES')
        rows = cursor.fetchall()
        table_names = [row[0] for row in rows]
    except cx_Oracle.Error as error:
        print("Error connecting to Oracle database:", error)
    app.run(debug = True)