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

        function createGenericDateTable(data, createMissingForms = false) {
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

            // Add an extra header for the action column if forms are to be created
            if (createMissingForms) {
                const th = document.createElement('th');
                th.textContent = 'Action';
                th.style.border = '1px solid black';
                th.style.padding = '5px';
                headerRow.appendChild(th);
            }

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

            // Add missing date rows with forms if createMissingForms is true
            if (createMissingForms) {
                const dateIndex = colNames.indexOf('date');
                const existingDates = new Set(columns[dateIndex]);
                const today = new Date().toISOString().split('T')[0];
                let currentDate = new Date(Math.min(...columns[dateIndex]));

                while (currentDate.toISOString() <= today) {
                    const dateStr = currentDate.toISOString().split('T')[0];
                    if (!existingDates.has(dateStr)) {
                        const row = tbody.insertRow();
                        for (let j = 0; j < numCols; j++) {
                            const cell = row.insertCell();
                            if (j === dateIndex) {
                                cell.textContent = dateStr;
                            } else {
                                cell.innerHTML = '<input type="text">';
                            }
                            cell.style.border = '1px solid black';
                            cell.style.padding = '5px';
                        }
                        const actionCell = row.insertCell();
                        actionCell.innerHTML = '<button onclick="submitForm(this)">Submit</button>';
                        actionCell.style.border = '1px solid black';
                        actionCell.style.padding = '5px';
                    }
                    currentDate.setDate(currentDate.getDate() + 1);
                }
            }

            body.appendChild(tbl);
        }
