function createForm(pairs) {
    // Create a form element
    const form = document.createElement('form');

    // Iterate over the pairs to create input elements
    pairs.forEach(pair => {
        const name = pair.name;
        const dataType = pair.dataType;

        // Create a label for the input field
        const label = document.createElement('label');
        label.textContent = name + ': ';

        // Create an input element based on the data type
        let input;
        switch (dataType) {
            case 'text':
                input = document.createElement('input');
                input.type = 'text';
                break;
            case 'number':
                input = document.createElement('input');
                input.type = 'number';
                break;
            case 'email':
                input = document.createElement('input');
                input.type = 'email';
                break;
            case 'date':
                input = document.createElement('input');
                input.type = 'date';
                break;
            case 'checkbox':
                input = document.createElement('input');
                input.type = 'checkbox';
                break;
            default:
                input = document.createElement('input');
                input.type = 'text';
                break;
        }

        // Set the name attribute of the input field
        input.name = name;

        // Append the label and input to the form
        form.appendChild(label);
        form.appendChild(input);
        form.appendChild(document.createElement('br'));
    });

    // Create a submit button
    const submitButton = document.createElement('input');
    submitButton.type = 'submit';
    submitButton.value = 'Submit';

    // Append the submit button to the form
    form.appendChild(submitButton);

    // Append the form to the body or any other container
    document.body.appendChild(form);
}

// Example usage:
const pairs = [
    { name: 'Username', dataType: 'text' },
    { name: 'Age', dataType: 'number' },
    { name: 'Email', dataType: 'email' },
    { name: 'Birthdate', dataType: 'date' },
    { name: 'Subscribe', dataType: 'checkbox' }
];

createForm(pairs);
