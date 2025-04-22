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
            case 'text':
                input = document.createElement('input');
                input.type = 'text';
                form.appendChild(label);
                form.appendChild(input);
                break;
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