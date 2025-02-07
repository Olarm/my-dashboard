function tableCreate(data) {
    const body = document.body;
    const tbl = document.createElement('table');
    tbl.style.width = '100%';
    tbl.style.border = '1px solid black';
    tbl.style.borderCollapse = 'collapse';

    const colNames = data.colindex.names;
    const columns = data.columns;
    const numRows = columns[0].length;
    const numCols = colNames.length;

    // Create table head
    const thead = tbl.createTHead();
    const headerRow = thead.insertRow();
    colNames.forEach(name => {
        const th = document.createElement('th');
        th.textContent = name;
        th.style.border = '1px solid black';
        th.style.padding = '5px';
        headerRow.appendChild(th);
    });

    // Create table body
    const tbody = tbl.createTBody();
    for (let i = 0; i < numRows; i++) {
        const row = tbody.insertRow();
        for (let j = 0; j < numCols; j++) {
            const cell = row.insertCell();
            cell.textContent = columns[j][i] !== undefined ? columns[j][i] : '';
            cell.style.border = '1px solid black';
            cell.style.padding = '5px';
        }
    }

    body.appendChild(tbl);
}
