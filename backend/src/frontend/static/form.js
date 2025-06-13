function createSearchableDropdown(labelText, options, form) {
    console.log(options);
    const label = document.createElement('label');
    label.textContent = labelText + ': ';
    form.appendChild(label);

    const input = document.createElement('input');
    input.type = 'text';
    input.placeholder = 'Type to search....';
    input.list = "testList";
    form.appendChild(input);

    const dropdownList = document.createElement('datalist');
    dropdownList.id = "testList";
    dropdownList.className = 'dropdown-content';
    form.appendChild(dropdownList);

    input.addEventListener('input', function() {
        const filter = input.value.toLowerCase();
        dropdownList.innerHTML = '';

        if (filter) {
            const filteredOptions = options.filter(option =>
                option[1].toLowerCase().includes(filter)
            );

            filteredOptions.forEach(option => {
                const div = document.createElement('option');
                div.textContent = option[1];
                div.value = option[1];
                div.dataset.id = option[0]; // Store the ID in a data attribute
                div.addEventListener('click', function() {
                    input.value = option[1];
                    input.dataset.selectedId = option[0]; // Store the selected ID in a data attribute
                    dropdownList.innerHTML = '';
                    dropdownList.style.display = 'none';
                });
                dropdownList.appendChild(div);
            });

            dropdownList.style.display = 'block';
        } else {
            dropdownList.style.display = 'none';
        }
    });

    document.addEventListener('click', function(event) {
        if (event.target !== input && !dropdownList.contains(event.target)) {
            dropdownList.style.display = 'none';
        }
    });

    return input;
}

function createForm(formData, formId, createUrl, onSubmitCallback, containerId) {
    const form = document.createElement('form');
    form.id = formId;
    form.addEventListener('submit', async function(event) {
        event.preventDefault();
        if (onSubmitCallback) {
            await onSubmitCallback(event, createUrl);
        }
    });
    formData.forEach(pair => {
        const name = pair.name;
        const dataType = pair.data_type;
        const label = document.createElement('label');
        label.textContent = name + ': ';
        
        let input;
        
        switch (dataType) {
            case 'options':
                if (pair.options && Array.isArray(pair.options)) {
                    input = createSearchableDropdown(name, pair.options, form);
                } else {
                    input = document.createElement('input');
                    input.type = 'text';
                    form.appendChild(label);
                    form.appendChild(input);
                }
                break;
            case 'text':
                input = document.createElement('input');
                input.type = 'text';
                form.appendChild(label);
                form.appendChild(input);
                break;
            case 'numeric':
            case 'integer':
            case 'number':
                input = document.createElement('input');
                input.type = 'number';
                form.appendChild(label);
                form.appendChild(input);
                break;
            case 'email':
                input = document.createElement('input');
                input.type = 'email';
                form.appendChild(label);
                form.appendChild(input);
                break;
            case 'date':
                input = document.createElement('input');
                input.type = 'date';
                form.appendChild(label);
                form.appendChild(input);
                break;
            case 'timestamp':
            case 'timestamp with time zone':
            case 'datetime':
                input = document.createElement('input');
                input.type = 'datetime-local';
                form.appendChild(label);
                form.appendChild(input);
                break;
            case 'boolean':
                input = document.createElement('input');
                input.type = 'checkbox';
                form.appendChild(label);
                form.appendChild(input);
                break;
            case 'radio':
                if (pair.options && Array.isArray(pair.options)) {
                    const radioGroup = document.createElement('div');
                    radioGroup.className = 'radio-group';
                    
                    // Add the main label for the radio group
                    radioGroup.appendChild(label);
                    form.appendChild(radioGroup);
                    
                    // Create radio buttons for each option
                    pair.options.forEach((option, index) => {
                        const radioContainer = document.createElement('div');
                        radioContainer.className = 'radio-option';
                        
                        // Create radio input
                        const radioInput = document.createElement('input');
                        radioInput.type = 'radio';
                        radioInput.name = name;
                        radioInput.id = `${name}_${index}`;
                        radioInput.value = option.value || option;
                        
                        // If this is the first option or the option is marked as default, check it
                        if (index === 0 || option.default) {
                            radioInput.checked = true;
                        }
                        
                        // Create label for this radio option
                        const radioLabel = document.createElement('label');
                        radioLabel.htmlFor = `${name}_${index}`;
                        radioLabel.textContent = option.label || option;
                        
                        // Add radio button and its label to the container
                        radioContainer.appendChild(radioInput);
                        radioContainer.appendChild(radioLabel);
                        radioGroup.appendChild(radioContainer);
                    });
                    
                    // No need for separate input variable as we've added all radios to the form
                    input = null;
                } else {
                    // Fallback if no options are provided
                    input = document.createElement('input');
                    input.type = 'text';
                    form.appendChild(label);
                    form.appendChild(input);
                }
                break;
            default:
                input = document.createElement('input');
                input.type = 'text';
                form.appendChild(label);
                form.appendChild(input);
                break;
        }
        
        // Set the name attribute of the input field if it exists
        if (input) {
            input.name = name;
            // These appends have been moved into each case for better control
        }
        
        form.appendChild(document.createElement('br'));
    });
    
    const submitButton = document.createElement('button');
    submitButton.type = 'submit';
    submitButton.textContent = 'Submit';
    
    form.appendChild(submitButton);

    if (containerId) {
        const container = document.getElementById(containerId);
        if (container) {
            container.appendChild(form);
        } else {
            console.warn(`Container with ID "${containerId}" not found. Appending form to document body instead.`);
            document.body.appendChild(form);
        }
    } else {
        document.body.appendChild(form);
    }
}