var old_view_cols;
var old_cols;

function backToMainMenu() {
    window.location.href = '/'
}

function create_view_remedieri_per_rol() {
    $.ajax({
        type: 'POST',
        url: '/create_view_remedieri_per_rol',
        success: function(response) {
            $('#errorMsgHolder1').html(response);
        }
    })
}

function create_view_facturi_clienti() {
    $.ajax({
        type: 'POST',
        url: '/create_view_facturi_clienti',
        success: function(response) {
            $('#errorMsgHolder2').html(response);
        }
    })
}


function show_view_facturi_clienti() {
    $.ajax({
        type: 'POST',
        url: '/show_view_facturi_clienti',
        success: function(response) {
            $('#tableDisplay2').html(response);
        }
    });
}

function show_view_remedieri_per_rol() {
    $.ajax({
        type: 'POST',
        url: '/show_view_remedieri_per_rol',
        success: function(response) {
            $('#tableDisplay1').html(response);
        }
    });
}

function execute_sql_page_c() {
    $.ajax({
        type: 'POST',
        url: '/exec_page_c_sql',
        success: function(response) {
            $('#tableDisplay').html(response);
        }
    });
}

function execute_sql_page_d() {
    $.ajax({
        type: 'POST',
        url: '/exec_page_d_sql',
        success: function(response) {
            $('#tableDisplay').html(response);
        }
    });
}

function fetchCurrentTableColumns() {
    var selectedTable = document.getElementById('tables').value;
    $('#tableDisplay').html('');
    $.ajax({
        type: 'POST',
        url: '/get_table_columns',
        data: { selected_table: selectedTable },
        success: function(response) {
            $('#columns').html(response);
        }
    });
}

function toggleSortingOptions() {
    sortCheckBox = document.getElementById('willSort');
    sortDiv = document.getElementById('sort-div')
    if(sortCheckBox.checked)
        sortDiv.style.display = 'block';
    else
        sortDiv.style.display = 'none';
}

window.onload = () => {
    if(window.location.pathname === '/')
        fetchCurrentTableColumns();
}

function verifyPriorityInput(elem) {
    if(elem.value.length > 2 || 
        elem.value[0] < '0' && elem.value[0] > '9' ||
        elem.value[1] < '0' && elem.value[1] > '9')
        elem.value = "";
}

function modifyEntry(button) {
    var rowNumber = button.id.match(/\d+$/)[0];
    var selectedTable = document.getElementById('tables').value;
    var cols = document.getElementsByClassName('td-row-' + rowNumber)
    cols = Array.from(cols).map((elem) => {
        return elem.textContent;
    });
    old_cols = cols;
    $.ajax({
        type: 'POST',
        url: '/modify_row',
        contentType: 'application/json',
        data: JSON.stringify({table : selectedTable,
                rowValues: cols}),
        success: function(response) {
            $('#tableDisplay').html(response);
        }
    });
}

function modifyViewEntry(button) {
    var rowNumber = button.id.match(/\d+$/)[0];
    var cols = document.getElementsByClassName('td-row-' + rowNumber)
    cols = Array.from(cols).map((elem) => {
        return elem.textContent;
    });
    old_view_cols = cols;
    $.ajax({
        type: 'POST',
        url: '/modify_view_entry',
        contentType: 'application/json',
        data: JSON.stringify({ rowValues : cols}),
        success: function(response) {
            $('#tableDisplay2').html(response);
        }
    });
}

function submitViewModification(button) {
    var rowNumber = button.id.match(/\d+$/)[0];
    var cols = document.getElementsByClassName('td-row-' + rowNumber)
    cols = Array.from(cols).map((elem) => {
        if(elem.textContent !== '')
            return elem.textContent;
        return elem.value;
    });
    $.ajax({
        type: 'POST',
        url: '/submit_view_modification',
        contentType: 'application/json',
        data: JSON.stringify({ rowValues : cols,
                                oldRowValues : old_view_cols}),
        success: function(response) {
            if(response !== 'ok')
                $('#errorMsgHolder2').html(response);
            show_view_facturi_clienti();
        }
    });
}

function deleteViewEntry(button) {
    var rowNumber = button.id.match(/\d+$/)[0];
    var cols = document.getElementsByClassName('td-row-' + rowNumber)
    cols = Array.from(cols).map((elem) => {
        return elem.textContent;
    });
    $.ajax({
        type: 'POST',
        url: '/remove_view_entry',
        contentType: 'application/json',
        data: JSON.stringify({ rowValues : cols}),
        success: function(response) {
            if(response != 'ok')
                return;
            show_view_facturi_clienti();
        }
    });
}

function submitModification(button) {
    /// verificari
    var sorting_priority_inputs = Array.from(document.querySelectorAll('[id^="input-modificare-rand-"]'))
    rowValues = sorting_priority_inputs.map((element) => {
        return element.value;
    });
    rowNumber = button.id.match(/\d+$/)[0];
    var selectedTable = document.getElementById('tables').value;
    $.ajax({
        type: 'POST',
        url: '/submit_modified_row',
        contentType: 'application/json',
        data: JSON.stringify({ 
        table: selectedTable,
        rowValues : rowValues,
        oldRowValues: old_cols}),
        success: function(response) {
            if(response != 'ok') {
                $('#errorMsgHolder').html('Eroare: <br>' + response + ' <br><br>');
                showTable();
                return;
            }
            showTable();
        }
    });
}

function deleteEntry(button) {
    var selectedTable = document.getElementById('tables').value;
    var rowNumber = button.id.match(/\d+$/)[0];
    var cols = document.getElementsByClassName('td-row-' + rowNumber)
    cols = Array.from(cols).map((elem) => {
        return elem.textContent;
    });
    $.ajax({
        type: 'POST',
        url: '/remove_row',
        contentType: 'application/json',
        data: JSON.stringify({ values : cols,
                table : selectedTable}),
        success: function(response) {
            if(response != 'ok')
                return;
            showTable();
        }
    });
}

function showTable() {

    var selectedTable = document.getElementById('tables').value;
    var sortCheckBox = document.getElementById('willSort');

    var sorting_priority_inputs = Array.from(document.querySelectorAll('[id^="sorting-priority-input-"]')).map(function(element) {
        if(element.value == "")
            element.value = "0";
        return parseInt(element.value);
    });
    var sorting_types = Array.from(document.querySelectorAll('[id^="sorting-type-selector-"]')).map(function(element) {return element.value;});
    
    $.ajax({
        type: 'POST',
        url: '/get_table_data',
        contentType: 'application/json',
        data: JSON.stringify({ selected_table: selectedTable,
                sortQuery: sortCheckBox.checked,
                sortingPriorities: sorting_priority_inputs,
                sortingTypes: sorting_types
              }),
        success: function(response) {
            $('#tableDisplay').html(response);
        }
    });
}